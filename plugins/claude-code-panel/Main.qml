import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI
import "ClaudeLogic.js" as Logic

Item {
  id: root

  property var pluginApi: null

  // ----- Conversation state -----
  property var messages: []
  property bool isGenerating: false
  property string errorMessage: ""
  property bool isManuallyStopped: false
  property string streamingMessageId: ""   // id of live assistant bubble being streamed into
  property bool sawPartialThisTurn: false

  // Back-compat accessor — some older bindings may read `currentAssistantBuffer`.
  readonly property string currentAssistantBuffer: {
    if (!streamingMessageId) return "";
    for (var i = messages.length - 1; i >= 0; i--) {
      if (messages[i].id === streamingMessageId) return messages[i].text || "";
    }
    return "";
  }

  // ----- Session state -----
  property string sessionId: ""
  property string lastModel: ""
  property string lastPermissionMode: "default"
  property var lastTools: []
  property var lastMcpServers: []

  // ----- Input persistence -----
  property string inputText: ""
  property int inputCursor: 0

  // ----- CLI health -----
  property bool binaryAvailable: false
  property bool binaryChecked: false
  // Absolute path resolved from `which` (or the user-configured absolute path).
  // Using this avoids PATH mismatches between Quickshell's launch env and the shell.
  property string resolvedBinaryPath: ""

  // ----- Persistent process state -----
  property string activeFingerprint: ""
  property bool processReady: false
  property var pendingTurns: []

  // ----- Cache paths -----
  readonly property string cacheDir: (typeof Settings !== 'undefined' && Settings.cacheDir)
      ? Settings.cacheDir + "plugins/claude-code-panel/" : ""
  readonly property string stateCachePath: cacheDir + "state.json"

  // ----- Settings accessors -----
  readonly property var claudeSettings: pluginApi?.pluginSettings?.claude || ({})
  readonly property string binaryPath: claudeSettings.binary || "claude"
  readonly property string workingDir: claudeSettings.workingDir || ""
  readonly property string permissionMode: claudeSettings.permissionMode || "default"
  readonly property bool dangerouslySkip: claudeSettings.dangerouslySkipPermissions === true

  Component.onCompleted: {
    Logger.i("ClaudeCode", "Plugin initialized");
    ensureCacheDir();
    checkBinary();
  }

  function ensureCacheDir() {
    if (cacheDir) { Quickshell.execDetached(["mkdir", "-p", cacheDir]); }
  }

  // ---------- Binary presence check ----------
  Process {
    id: whichProcess
    command: ["which", root.binaryPath]
    stdout: StdioCollector {
      onStreamFinished: {
        var resolved = (text || "").trim();
        // `which` may return multiple lines in edge cases — keep the first.
        if (resolved.indexOf("\n") !== -1) { resolved = resolved.split("\n")[0].trim(); }
        root.resolvedBinaryPath = resolved;
        root.binaryAvailable = (resolved !== "");
        root.binaryChecked = true;
        if (!root.binaryAvailable) {
          Logger.w("ClaudeCode", "`" + root.binaryPath + "` not found on PATH");
        } else {
          Logger.i("ClaudeCode", "Using claude at: " + resolved);
        }
      }
    }
    stderr: StdioCollector {}
  }

  function checkBinary() {
    binaryChecked = false;
    // If the user gave an absolute path, skip resolution — trust it.
    if (binaryPath && binaryPath.length > 0 && binaryPath[0] === "/") {
      root.resolvedBinaryPath = binaryPath;
      root.binaryAvailable = true;
      root.binaryChecked = true;
      Logger.i("ClaudeCode", "Using claude at (absolute): " + binaryPath);
      return;
    }
    whichProcess.command = ["which", binaryPath];
    whichProcess.running = true;
  }

  // Re-check whenever the configured binary name changes.
  onBinaryPathChanged: checkBinary()

  // ---------- State persistence ----------
  FileView {
    id: stateCacheFile
    path: root.stateCachePath
    watchChanges: false
    onLoaded: loadStateFromCache()
    onLoadFailed: function (error) {
      if (error !== 2) { Logger.e("ClaudeCode", "state load failed: " + error); }
    }
  }

  function loadStateFromCache() {
    var result = Logic.processLoadedState(stateCacheFile.text());
    if (!result || result.error) {
      if (result && result.error) { Logger.e("ClaudeCode", "state parse: " + result.error); }
      return;
    }
    root.messages = result.messages;
    root.sessionId = result.sessionId;
    root.lastModel = result.lastModel;
    root.lastPermissionMode = result.lastPermissionMode;
    root.inputText = result.inputText;
    root.inputCursor = result.inputCursor;
  }

  Timer {
    id: saveStateTimer
    interval: 500
    onTriggered: root.performSaveState()
  }
  property bool saveStateQueued: false

  function saveState() {
    saveStateQueued = true;
    saveStateTimer.restart();
  }

  function performSaveState() {
    if (!saveStateQueued || !cacheDir) { return; }
    saveStateQueued = false;
    try {
      ensureCacheDir();
      var maxHistory = pluginApi?.pluginSettings?.maxHistoryLength || 200;
      var data = Logic.prepareStateForSave({
        messages: root.messages,
        sessionId: root.sessionId,
        lastModel: root.lastModel,
        lastPermissionMode: root.lastPermissionMode,
        inputText: root.inputText,
        inputCursor: root.inputCursor
      }, maxHistory);
      stateCacheFile.setText(data);
    } catch (e) {
      Logger.e("ClaudeCode", "state save: " + e);
    }
  }

  // ---------- Message helpers ----------
  function pushMessage(entry) {
    var withMeta = Object.assign({
      id: Date.now().toString() + "-" + Math.random().toString(36).slice(2, 6),
      timestamp: new Date().toISOString()
    }, entry);
    root.messages = [...root.messages, withMeta];
    saveState();
    return withMeta;
  }

  function clearMessages() {
    root.messages = [];
    root.streamingMessageId = "";
    saveState();
  }

  // Find the index of a message by id; -1 if not found.
  function _indexOfMessage(id) {
    for (var i = root.messages.length - 1; i >= 0; i--) {
      if (root.messages[i].id === id) return i;
    }
    return -1;
  }

  // Replace the entry at index with updated fields; keeps ListView rendering happy.
  function _replaceMessageAt(i, updated) {
    root.messages = [...root.messages.slice(0, i), updated, ...root.messages.slice(i + 1)];
  }

  // Ensure there is a live assistant bubble to stream into; return its id.
  function ensureStreamingMessage() {
    if (root.streamingMessageId) { return root.streamingMessageId; }
    var entry = pushMessage({ role: "assistant", kind: "text", text: "", streaming: true });
    root.streamingMessageId = entry.id;
    return entry.id;
  }

  // Append text to the live streaming bubble (creates one if missing).
  function appendToStreaming(text) {
    if (!text) { return; }
    var id = ensureStreamingMessage();
    var idx = _indexOfMessage(id);
    if (idx === -1) { return; }
    var current = root.messages[idx];
    _replaceMessageAt(idx, Object.assign({}, current, { text: (current.text || "") + text }));
    // Debounced cache write — avoids hammering FS on every token.
    saveState();
  }

  // Set the streaming bubble's text outright (used by non-partial assistant events).
  function setStreamingText(text) {
    var id = ensureStreamingMessage();
    var idx = _indexOfMessage(id);
    if (idx === -1) { return; }
    var current = root.messages[idx];
    _replaceMessageAt(idx, Object.assign({}, current, { text: text || "" }));
    saveState();
  }

  // Finalize: mark the live bubble as no longer streaming. Drop if it's empty.
  function finalizeStreaming() {
    if (!root.streamingMessageId) { return; }
    var idx = _indexOfMessage(root.streamingMessageId);
    root.streamingMessageId = "";
    if (idx === -1) { return; }
    var current = root.messages[idx];
    if (!current.text || current.text.trim() === "") {
      // Empty placeholder — remove it
      root.messages = [...root.messages.slice(0, idx), ...root.messages.slice(idx + 1)];
    } else {
      _replaceMessageAt(idx, Object.assign({}, current, { streaming: false }));
    }
    saveState();
  }

  function newSession() {
    stopProcess();
    root.sessionId = "";
    root.messages = [];
    root.streamingMessageId = "";
    root.errorMessage = "";
    saveState();
    ToastService.showNotice(pluginApi?.tr("toast.sessionCleared"));
  }

  // ---------- Per-turn process ----------
  // NOTE: persistent bidirectional mode (stdinEnabled + write) is broken on this build of
  // Quickshell — setting stdinEnabled:true causes the spawn itself to fail. We fall back to
  // one `claude -p "<prompt>"` invocation per turn. Partial streaming + --resume preserve
  // the feel and continuity. Flip back once stdinEnabled is reliable.
  Process {
    id: claudeProcess

    property string stderrBuffer: ""

    stdout: SplitParser {
      onRead: function (line) {
        var ev = Logic.parseStreamJsonLine(line);
        root.applyEvent(ev);
      }
    }

    stderr: StdioCollector {
      onStreamFinished: {
        if (text && text.trim() !== "") {
          Logger.w("ClaudeCode", "claude stderr: " + text);
          claudeProcess.stderrBuffer = text;
        }
      }
    }

    property bool didStart: false
    onStarted: {
      didStart = true;
      startWatchdog.stop();
      Logger.i("ClaudeCode", "claude process started (pid=" + claudeProcess.processId + ")");
    }

    onExited: function (exitCode, exitStatus) {
      Logger.i("ClaudeCode", "claude exited code=" + exitCode + " status=" + exitStatus);
      root.onProcessExited();
    }
  }

  Timer {
    id: startWatchdog
    interval: 1500
    repeat: false
    onTriggered: {
      if (!claudeProcess.didStart) {
        Logger.e("ClaudeCode", "claude failed to start within 1.5s — binary exec failed");
        root.isGenerating = false;
        root.errorMessage = "Claude failed to launch. Check binary path / interpreter (node).";
        if (typeof ToastService !== "undefined") {
          ToastService.showError(root.errorMessage);
        }
        if (claudeProcess.running) { claudeProcess.running = false; }
      }
    }
  }

  function stopProcess() {
    if (claudeProcess.running) {
      claudeProcess.running = false;
    }
    root.processReady = false;
    root.activeFingerprint = "";
  }

  function onProcessExited() {
    var wasGenerating = root.isGenerating;
    root.processReady = false;
    root.activeFingerprint = "";
    if (root.isManuallyStopped) {
      root.isManuallyStopped = false;
      root.isGenerating = false;
      finalizeStreaming();
      return;
    }
    root.isGenerating = false;
    finalizeStreaming();
    if (wasGenerating && root.errorMessage === "") {
      var reason = claudeProcess.stderrBuffer && claudeProcess.stderrBuffer.trim() !== ""
        ? claudeProcess.stderrBuffer.trim()
        : (pluginApi?.tr("errors.runFailed"));
      root.errorMessage = reason;
    }
    claudeProcess.stderrBuffer = "";
    root.saveState();
  }

  // ---------- Sending ----------
  function sendMessage(userText) {
    if (!userText || userText.trim() === "") { return; }
    if (!binaryAvailable) {
      root.errorMessage = pluginApi?.tr("errors.binaryMissing");
      ToastService.showError(root.errorMessage);
      return;
    }
    if (root.isGenerating || claudeProcess.running) {
      root.errorMessage = pluginApi?.tr("errors.busy");
      return;
    }

    var text = userText.trim();
    pushMessage({ role: "user", kind: "text", text: text });

    root.isGenerating = true;
    root.isManuallyStopped = false;
    root.errorMessage = "";
    root.streamingMessageId = "";
    root.sawPartialThisTurn = false;
    claudeProcess.stderrBuffer = "";

    var home = Quickshell.env("HOME") || "";
    var cmd = Logic.buildPerTurnCommand(claudeSettings, text, root.sessionId, home);
    if (root.resolvedBinaryPath && cmd.args.length > 0) {
      cmd.args[0] = root.resolvedBinaryPath;
    }
    // Direct exec — Quickshell Process already handles argv properly; the sh wrapper was
    // causing FailedToStart on some builds.
    var finalArgs = cmd.args;
    Logger.i("ClaudeCode", "spawn per-turn: " + JSON.stringify(finalArgs));
    claudeProcess.command = finalArgs;
    if (cmd.cwd && cmd.cwd.trim() !== "") {
      claudeProcess.workingDirectory = cmd.cwd;
    } else {
      claudeProcess.workingDirectory = home || "/tmp";
    }
    claudeProcess.didStart = false;
    claudeProcess.running = true;
    startWatchdog.restart();
  }

  function stopGeneration() {
    if (!claudeProcess.running) {
      root.isGenerating = false;
      finalizeStreaming();
      return;
    }
    root.isManuallyStopped = true;
    stopProcess();
    root.isGenerating = false;
    finalizeStreaming();
    ToastService.showNotice(pluginApi?.tr("toast.stopped"));
  }

  // ---------- Stream event handling ----------
  function applyEvent(ev) {
    if (!ev) { return; }
    if (ev.kind === "batch") {
      for (var i = 0; i < ev.items.length; i++) { applyEvent(ev.items[i]); }
      return;
    }
    switch (ev.kind) {
      case "init":
        if (ev.sessionId) { root.sessionId = ev.sessionId; }
        if (ev.model) { root.lastModel = ev.model; }
        if (ev.permissionMode) { root.lastPermissionMode = ev.permissionMode; }
        root.lastTools = ev.tools || [];
        root.lastMcpServers = ev.mcpServers || [];
        break;

      case "assistant_text":
        // If we already streamed this via partial deltas, the bubble already has the text.
        // Otherwise, set it from the complete event.
        if (!root.sawPartialThisTurn) {
          setStreamingText((root.streamingMessageId ? root.currentAssistantBuffer : "") + ev.text);
        }
        break;

      case "thinking":
        // Break any in-flight assistant bubble, record thinking as its own entry.
        finalizeStreaming();
        pushMessage({ role: "assistant", kind: "thinking", text: ev.text });
        break;

      case "tool_use":
        // Finalize current assistant text before the tool invocation.
        finalizeStreaming();
        pushMessage({
          role: "assistant",
          kind: "tool_use",
          text: Logic.summarizeToolInput(ev.name, ev.input),
          meta: {
            toolName: ev.name,
            toolId: ev.id,
            input: ev.input,
            classification: Logic.classifyTool(ev.name)
          }
        });
        // Next assistant text will open a fresh streaming bubble after the tool_result.
        root.sawPartialThisTurn = false;
        break;

      case "tool_result":
        pushMessage({
          role: "tool",
          kind: "tool_result",
          text: ev.content || "",
          meta: { toolUseId: ev.toolUseId, isError: ev.isError }
        });
        break;

      case "result":
        if (ev.sessionId) { root.sessionId = ev.sessionId; }
        finalizeStreaming();
        root.isGenerating = false;
        if (ev.isError) { root.errorMessage = ev.text || (pluginApi?.tr("errors.runFailed")); }
        root.saveState();
        break;

      case "stream_event":
        var delta = Logic.extractStreamDeltaText(ev.event);
        if (delta) {
          root.sawPartialThisTurn = true;
          appendToStreaming(delta);
        }
        break;

      case "raw":
        Logger.d("ClaudeCode", "raw: " + ev.line);
        break;
    }
  }

  // ---------- Clipboard ----------
  function copyToClipboard(text) {
    if (typeof text !== "string" || text === "") { return; }
    // Pass text as argv $1 — no shell interpolation. Handles Wayland + X11.
    const script = `if command -v wl-copy >/dev/null 2>&1; then printf %s "$1" | wl-copy; elif command -v xclip >/dev/null 2>&1; then printf %s "$1" | xclip -selection clipboard; elif command -v xsel >/dev/null 2>&1; then printf %s "$1" | xsel -b -i; fi`;
    Quickshell.execDetached(["sh", "-c", script, "--", text]);
    ToastService.showNotice(pluginApi?.tr("toast.copied"));
  }

  // ---------- Slash commands ----------
  // Returns true if the command was handled locally; false = pass through to Claude.
  function handleSlashCommand(raw) {
    if (!raw || raw[0] !== "/") { return false; }
    var parts = raw.trim().split(/\s+/);
    var cmd = parts[0].toLowerCase();
    var rest = parts.slice(1).join(" ");

    switch (cmd) {
      case "/help":
        pushMessage({
          role: "assistant",
          kind: "text",
          text: [
            "**Local commands**",
            "- `/help` — this list",
            "- `/clear` — clear chat history (local only; session persists)",
            "- `/new` — start a new Claude session",
            "- `/stop` — stop the current run",
            "- `/model <name>` — switch model (restarts session)",
            "- `/mode <default|acceptEdits|plan|bypass>` — permission mode",
            "- `/cwd <absolute-path>` — working directory",
            "- `/dirs <path1,path2,...>` — additional readable dirs",
            "- `/allow <Tool1,Tool2>` — set allowedTools",
            "- `/deny <Tool1,Tool2>` — set disallowedTools",
            "- `/session` — show current session id",
            "- `/copy` — copy last assistant message",
            "",
            "Any other `/command` is passed through to Claude Code itself (`/compact`, `/cost`, …)."
          ].join("\n")
        });
        return true;

      case "/clear":
        clearMessages();
        ToastService.showNotice(pluginApi?.tr("toast.historyCleared"));
        return true;

      case "/new":
        newSession();
        return true;

      case "/stop":
        stopGeneration();
        return true;

      case "/model":
        if (!rest) {
          pushMessage({ role: "assistant", kind: "text", text: pluginApi?.tr("cmd.modelCurrent") + "`" + (lastModel || claudeSettings.model || pluginApi?.tr("cmd.modelDefault")) + "`" });
          return true;
        }
        setClaudeField("model", rest);
        pushMessage({ role: "assistant", kind: "text", text: pluginApi?.tr("cmd.modelSet") + rest + "`" });
        stopProcess();
        return true;

      case "/mode":
        var modes = { "default": "default", "acceptedits": "acceptEdits", "accept": "acceptEdits",
                      "plan": "plan", "bypass": "bypassPermissions", "bypasspermissions": "bypassPermissions" };
        var m = modes[(rest || "").toLowerCase()];
        if (!m) {
          pushMessage({ role: "assistant", kind: "text", text: pluginApi?.tr("cmd.modeUsage") });
          return true;
        }
        setClaudeField("permissionMode", m);
        pushMessage({ role: "assistant", kind: "text", text: pluginApi?.tr("cmd.modeSet") + m + "`." });
        stopProcess();
        return true;

      case "/cwd":
        if (!rest) {
          pushMessage({ role: "assistant", kind: "text", text: pluginApi?.tr("cmd.cwdCurrent") + "`" + (claudeSettings.workingDir || pluginApi?.tr("cmd.cwdDefault")) + "`" });
          return true;
        }
        setClaudeField("workingDir", rest);
        pushMessage({ role: "assistant", kind: "text", text: pluginApi?.tr("cmd.cwdSet") + rest + "`." });
        stopProcess();
        return true;

      case "/dirs":
        var dirs = rest.split(/[,\n]/).map(function (s) { return s.trim(); }).filter(function (s) { return s !== ""; });
        setClaudeField("additionalDirs", dirs);
        pushMessage({ role: "assistant", kind: "text", text: pluginApi?.tr("cmd.dirsSet") + (dirs.length ? dirs.join(", ") : pluginApi?.tr("cmd.none")) });
        stopProcess();
        return true;

      case "/allow":
        var al = rest.split(/[,\s]+/).filter(function (s) { return s !== ""; });
        setClaudeField("allowedTools", al);
        pushMessage({ role: "assistant", kind: "text", text: pluginApi?.tr("cmd.allowSet") + (al.length ? al.join(", ") : pluginApi?.tr("cmd.allowEmpty")) });
        stopProcess();
        return true;

      case "/deny":
        var dl = rest.split(/[,\s]+/).filter(function (s) { return s !== ""; });
        setClaudeField("disallowedTools", dl);
        pushMessage({ role: "assistant", kind: "text", text: pluginApi?.tr("cmd.denySet") + (dl.length ? dl.join(", ") : pluginApi?.tr("cmd.none")) });
        stopProcess();
        return true;

      case "/session":
        pushMessage({ role: "assistant", kind: "text", text: sessionId ? (pluginApi?.tr("cmd.sessionActive") + "`" + sessionId + "`") : pluginApi?.tr("cmd.sessionNone") });
        return true;

      case "/copy":
        for (var i = messages.length - 1; i >= 0; i--) {
          var msg = messages[i];
          if (msg.role === "assistant" && msg.kind === "text" && msg.text) {
            copyToClipboard(msg.text);
            return true;
          }
        }
        ToastService.showNotice("No assistant message to copy");
        return true;

      default:
        return false; // pass through to Claude
    }
  }

  function setClaudeField(key, value) {
    if (!pluginApi) { return; }
    if (!pluginApi.pluginSettings.claude) { pluginApi.pluginSettings.claude = {}; }
    pluginApi.pluginSettings.claude[key] = value;
    pluginApi.saveSettings();
  }

  // ---------- IPC ----------
  IpcHandler {
    target: "plugin:claude-code-panel"

    function toggle() {
      if (pluginApi) { pluginApi.withCurrentScreen(function (s) { pluginApi.togglePanel(s); }); }
    }
    function open() {
      if (pluginApi) { pluginApi.withCurrentScreen(function (s) { pluginApi.openPanel(s); }); }
    }
    function close() {
      if (pluginApi) { pluginApi.withCurrentScreen(function (s) { pluginApi.closePanel(s); }); }
    }
    function send(message: string) {
      if (!message || message.trim() === "") { return; }
      if (message[0] === "/") {
        if (root.handleSlashCommand(message.trim())) { return; }
      }
      root.sendMessage(message);
    }
    function stop() { root.stopGeneration(); }
    function clear() {
      root.clearMessages();
      ToastService.showNotice(pluginApi?.tr("toast.historyCleared"));
    }
    function newSession() { root.newSession(); }
    function setModel(m: string)           { if (m) { root.setClaudeField("model", m); } }
    function setPermissionMode(mode: string) {
      if (["default","acceptEdits","plan","bypassPermissions"].indexOf(mode) === -1) { return; }
      root.setClaudeField("permissionMode", mode);
    }
    function setWorkingDir(path: string)   { root.setClaudeField("workingDir", path || ""); }
    function copyLast() {
      for (var i = root.messages.length - 1; i >= 0; i--) {
        var msg = root.messages[i];
        if (msg.role === "assistant" && msg.kind === "text" && msg.text) {
          root.copyToClipboard(msg.text);
          return;
        }
      }
    }
  }
}
