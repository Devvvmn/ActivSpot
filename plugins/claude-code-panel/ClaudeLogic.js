.pragma library

// ClaudeLogic.js — helpers for Claude Code (`claude`) CLI integration.
// Pure functions. No QML/Qt dependencies. Safe to unit-test standalone.

var PERMISSION_MODES = ["default", "acceptEdits", "plan", "bypassPermissions"];

// Baseline system-prompt fragment appended to every turn (unless the user disables
// `injectNoctaliaContext`). Tells the model where it is running and what IPC surface is
// available so it can drive the desktop directly via shell commands.
var NOCTALIA_SYSTEM_PROMPT =
"You are Claude running inside the **claude-code-panel** plugin of **Noctalia Shell** " +
"(a Quickshell-based Wayland desktop shell). You were invoked as `claude -p` via the " +
"plugin and your stdout (stream-json) is rendered live in a side panel.\n" +
"\n" +
"## Environment\n" +
"- Host shell: Noctalia Shell (Quickshell fork `noctalia-qs`).\n" +
"- Your CLI: the official Anthropic `claude` binary (Claude Code).\n" +
"- You have the normal Claude Code tools: Bash, Read, Write, Edit, Grep, Glob, etc.\n" +
"- Permission mode, allowed/disallowed tools, and MCP servers are configured by the user " +
"in the plugin Settings panel — respect what the UI has given you.\n" +
"\n" +
"## Controlling the desktop via Noctalia IPC\n" +
"Noctalia exposes `IpcHandler` targets. Invoke them from Bash:\n" +
"```\n" +
"qs -c noctalia-shell ipc call <target> <function> [args...]\n" +
"```\n" +
"Useful targets and functions (non-exhaustive, all callable this way):\n" +
"- `bar`: toggle, hideBar, showBar, peek, setDisplayMode <mode> <screen>, setPosition <pos> <screen>\n" +
"- `settings`: toggle, toggleTab <tab>, open, openTab <tab>\n" +
"- `calendar`: toggle\n" +
"- `notifications`: toggleHistory, toggleDND, enableDND, disableDND, clear, dismissAll, " +
"dismissOldest, getHistory (returns JSON), removeFromHistory <id>, invokeDefault <index>, " +
"invokeAction <id> <actionId>, getActions <index>\n" +
"- `toast`: send <json>, dismiss\n" +
"- `idleInhibitor`: toggle, enable, disable, enableFor <seconds>\n" +
"- `launcher`: toggle, clipboard, command, emoji, windows, settings\n" +
"- `lockScreen`: lock\n" +
"- `brightness`: increase, decrease, set <0..100>\n" +
"- `monitors`: on, off\n" +
"- `darkMode`: toggle, setDark, setLight\n" +
"- `nightLight`: toggle\n" +
"- `colorScheme`: set <schemeName>, setGenerationMethod <method>\n" +
"- `volume`: increase, decrease, muteOutput, increaseInput, decreaseInput, muteInput, " +
"togglePanel, openPanel, closePanel\n" +
"- `sessionMenu`: toggle, lock, lockAndSuspend\n" +
"- `controlCenter`: toggle\n" +
"- `dock`: toggle\n" +
"- `wallpaper`: toggle, random <screen>, get <screen> (returns path), set <path> <screen>, " +
"refresh, toggleAutomation, enableAutomation, disableAutomation\n" +
"- `wifi`: toggle, enable, disable\n" +
"- `network`: togglePanel\n" +
"- `bluetooth`: toggle, enable, disable, togglePanel, toggleAutoConnect, " +
"enableAutoConnect, disableAutoConnect\n" +
"- `airplaneMode`: toggle, enable, disable\n" +
"- `battery`: togglePanel\n" +
"- `powerProfile`: cycle, cycleReverse, set <mode>, toggleNoctaliaPerformance, " +
"enableNoctaliaPerformance, disableNoctaliaPerformance\n" +
"- `media`: toggle, playPause, play, pause, stop, next, previous, seekRelative <seconds>, " +
"seekByRatio <0..1>\n" +
"- `state`: all (returns a JSON snapshot of shell state)\n" +
"- `desktopWidgets`: toggle, enable, disable, edit\n" +
"- `location`: get (returns JSON), set <name>\n" +
"- `systemMonitor`: toggle\n" +
"- `plugin`: openSettings <key>, openPanel <key>, closePanel <key>, togglePanel <key>\n" +
"\n" +
"To discover what is running on this machine right now: `qs ipc show` lists live targets " +
"and function signatures. Prefer `qs ipc call` over editing config files when a user asks " +
"to toggle something — it's immediate, reversible, and leaves no persisted state behind.\n" +
"\n" +
"## Conventions\n" +
"- When the user asks for a desktop action (\"turn on dark mode\", \"lock the screen\", " +
"\"set wallpaper to X\"), reach for `qs ipc call` first.\n" +
"- Always quote paths and values; never assume shell tilde expansion works in non-shell " +
"contexts — Qt's QProcess does not expand `~`.\n" +
"- For code tasks, behave as normal Claude Code. The Noctalia context is additive, not a " +
"constraint on what you can do.\n";

// Compose the final --append-system-prompt value. When `injectNoctaliaContext` is enabled
// (default true), the baseline prompt is concatenated with the user's own prompt.
function composeSystemPrompt(settings) {
  var userPrompt = (settings && settings.appendSystemPrompt) ? String(settings.appendSystemPrompt).trim() : "";
  var inject = !(settings && settings.injectNoctaliaContext === false);
  if (!inject) { return userPrompt; }
  if (userPrompt === "") { return NOCTALIA_SYSTEM_PROMPT; }
  return NOCTALIA_SYSTEM_PROMPT + "\n## User-provided instructions\n" + userPrompt;
}

// Build the argv for a persistent bidirectional `claude` session.
// Kept for the day Quickshell's Process.stdinEnabled path is reliable; not currently used.
function buildPersistentCommand(settings, sessionId) {
  var bin = (settings && settings.binary) ? settings.binary : "claude";
  var args = [
    bin, "-p",
    "--input-format", "stream-json",
    "--output-format", "stream-json",
    "--verbose"
  ];

  if (settings) {
    if (settings.model) { args.push("--model", settings.model); }
    if (settings.fallbackModel) { args.push("--fallback-model", settings.fallbackModel); }

    if (sessionId && settings.autoResume !== false) {
      args.push("--resume", sessionId);
    }

    if (settings.dangerouslySkipPermissions) {
      args.push("--dangerously-skip-permissions");
    } else {
      var mode = settings.permissionMode || "default";
      if (PERMISSION_MODES.indexOf(mode) !== -1 && mode !== "default") {
        args.push("--permission-mode", mode);
      }
    }

    if (settings.allowedTools && settings.allowedTools.length > 0) {
      args.push("--allowedTools", settings.allowedTools.join(","));
    }
    if (settings.disallowedTools && settings.disallowedTools.length > 0) {
      args.push("--disallowedTools", settings.disallowedTools.join(","));
    }

    var dirs = settings.additionalDirs || [];
    for (var i = 0; i < dirs.length; i++) {
      var d = expandHome((dirs[i] || "").trim(), homeDir);
      if (d !== "") { args.push("--add-dir", d); }
    }

    if (settings.mcpConfigPath) {
      args.push("--mcp-config", settings.mcpConfigPath);
      if (settings.strictMcpConfig) { args.push("--strict-mcp-config"); }
    }

    var sys = composeSystemPrompt(settings);
    if (sys && sys.trim() !== "") {
      args.push("--append-system-prompt", sys);
    }

    // Partial messages ON by default in persistent mode for streaming feel.
    if (settings.includePartialMessages !== false) {
      args.push("--include-partial-messages");
    }

    if (settings.maxTurns && settings.maxTurns > 0) {
      args.push("--max-turns", String(settings.maxTurns));
    }
  }

  return {
    args: args,
    cwd: (settings && settings.workingDir) ? expandHome(settings.workingDir, homeDir) : ""
  };
}

// NDJSON line for a user turn, fed to the persistent claude process via stdin.
function userTurnLine(text) {
  return JSON.stringify({
    type: "user",
    message: { role: "user", content: text }
  }) + "\n";
}

// Build the argv for a one-shot `claude -p "<prompt>"` invocation (no stdin required).
// Passes the user message as a discrete argv element — no shell involved → no injection.
// Uses --resume <sessionId> to continue an existing conversation.
function buildPerTurnCommand(settings, prompt, sessionId, homeDir) {
  var bin = (settings && settings.binary) ? settings.binary : "claude";
  var args = [bin, "-p", prompt, "--output-format", "stream-json", "--verbose"];

  if (settings) {
    if (settings.model) { args.push("--model", settings.model); }
    if (settings.fallbackModel) { args.push("--fallback-model", settings.fallbackModel); }

    if (sessionId && settings.autoResume !== false) {
      args.push("--resume", sessionId);
    }

    if (settings.dangerouslySkipPermissions) {
      args.push("--dangerously-skip-permissions");
    } else {
      var mode = settings.permissionMode || "default";
      if (PERMISSION_MODES.indexOf(mode) !== -1 && mode !== "default") {
        args.push("--permission-mode", mode);
      }
    }

    if (settings.allowedTools && settings.allowedTools.length > 0) {
      args.push("--allowedTools", settings.allowedTools.join(","));
    }
    if (settings.disallowedTools && settings.disallowedTools.length > 0) {
      args.push("--disallowedTools", settings.disallowedTools.join(","));
    }

    var dirs = settings.additionalDirs || [];
    for (var i = 0; i < dirs.length; i++) {
      var d = expandHome((dirs[i] || "").trim(), homeDir);
      if (d !== "") { args.push("--add-dir", d); }
    }

    if (settings.mcpConfigPath) {
      args.push("--mcp-config", settings.mcpConfigPath);
      if (settings.strictMcpConfig) { args.push("--strict-mcp-config"); }
    }

    var sys = composeSystemPrompt(settings);
    if (sys && sys.trim() !== "") {
      args.push("--append-system-prompt", sys);
    }

    // Partial streaming ON by default — keeps responses feeling live while we pay the
    // per-turn cold-start cost. This is the single most important flag for perceived speed.
    if (settings.includePartialMessages !== false) {
      args.push("--include-partial-messages");
    }

    if (settings.maxTurns && settings.maxTurns > 0) {
      args.push("--max-turns", String(settings.maxTurns));
    }
  }

  return {
    args: args,
    cwd: (settings && settings.workingDir) ? expandHome(settings.workingDir, homeDir) : ""
  };
}

// Expand a leading `~` or `~/` to the given home directory. Qt's QProcess does NOT perform
// shell-level tilde expansion on workingDirectory — chdir("~/Foo") fails with ENOENT, which
// QProcess surfaces as a misleading "binary could not be found" FailedToStart error.
function expandHome(path, home) {
  if (!path) { return path; }
  var s = String(path).trim();
  if (!home) { return s; }
  if (s === "~") { return home; }
  if (s.indexOf("~/") === 0) { return home + s.substring(1); }
  return s;
}

// Wrap a command so it is spawned through `/bin/sh -c 'exec "$@"' --`. Argv is passed as
// positional parameters (`$@`), which means zero shell interpolation — safe for any
// content, including user-controlled strings. Absolute path to /bin/sh bypasses any PATH
// lookup issues in the spawning process's environment.
function shellWrappedCommand(argv) {
  if (!argv || argv.length === 0) { return argv; }
  return ["/bin/sh", "-c", 'exec "$@"', "--"].concat(argv);
}

// Hash the subset of settings that require a process restart to take effect.
function settingsFingerprint(s) {
  if (!s) { return ""; }
  return JSON.stringify([
    s.binary || "",
    s.workingDir || "",
    s.model || "",
    s.fallbackModel || "",
    s.permissionMode || "default",
    !!s.dangerouslySkipPermissions,
    (s.allowedTools || []).join(","),
    (s.disallowedTools || []).join(","),
    (s.additionalDirs || []).join(","),
    s.mcpConfigPath || "",
    !!s.strictMcpConfig,
    s.appendSystemPrompt || "",
    s.maxTurns || 0,
    s.includePartialMessages !== false,
    !!s.autoResume
  ]);
}

// Extract any text delta hidden in a `stream_event` (partial streaming).
function extractStreamDeltaText(ev) {
  if (!ev || typeof ev !== "object") { return ""; }
  // `content_block_delta` with `text_delta`
  if (ev.type === "content_block_delta" && ev.delta) {
    if (ev.delta.type === "text_delta" && typeof ev.delta.text === "string") {
      return ev.delta.text;
    }
  }
  return "";
}

// Parse one line of stream-json output.
// Returns one of:
//   { kind: "init", sessionId, tools, mcpServers, model, permissionMode, cwd }
//   { kind: "assistant_text", text }
//   { kind: "tool_use", id, name, input }
//   { kind: "tool_result", toolUseId, content, isError }
//   { kind: "result", isError, text, costUsd, durationMs, usage, sessionId }
//   { kind: "stream_event", event }     (partial streaming events)
//   { kind: "raw", line }               (unparseable or unknown)
function parseStreamJsonLine(line) {
  if (!line) { return null; }
  var trimmed = String(line).trim();
  if (trimmed === "") { return null; }

  var e;
  try {
    e = JSON.parse(trimmed);
  } catch (err) {
    return { kind: "raw", line: trimmed };
  }

  if (!e || typeof e !== "object" || !e.type) {
    return { kind: "raw", line: trimmed };
  }

  if (e.type === "system" && e.subtype === "init") {
    return {
      kind: "init",
      sessionId: e.session_id || "",
      tools: e.tools || [],
      mcpServers: e.mcp_servers || [],
      model: e.model || "",
      permissionMode: e.permissionMode || "",
      cwd: e.cwd || ""
    };
  }

  if (e.type === "assistant" && e.message && e.message.content) {
    var out = [];
    var content = e.message.content;
    for (var i = 0; i < content.length; i++) {
      var block = content[i];
      if (!block || !block.type) { continue; }
      if (block.type === "text" && typeof block.text === "string") {
        out.push({ kind: "assistant_text", text: block.text });
      } else if (block.type === "tool_use") {
        out.push({
          kind: "tool_use",
          id: block.id || "",
          name: block.name || "",
          input: block.input || {}
        });
      } else if (block.type === "thinking" && typeof block.thinking === "string") {
        out.push({ kind: "thinking", text: block.thinking });
      }
    }
    return out.length === 1 ? out[0] : { kind: "batch", items: out };
  }

  if (e.type === "user" && e.message && e.message.content) {
    var content2 = e.message.content;
    var results = [];
    for (var j = 0; j < content2.length; j++) {
      var b = content2[j];
      if (!b || b.type !== "tool_result") { continue; }
      var txt = "";
      if (typeof b.content === "string") {
        txt = b.content;
      } else if (Array.isArray(b.content)) {
        for (var k = 0; k < b.content.length; k++) {
          var c = b.content[k];
          if (c && c.type === "text" && typeof c.text === "string") { txt += c.text; }
        }
      }
      results.push({
        kind: "tool_result",
        toolUseId: b.tool_use_id || "",
        content: txt,
        isError: !!b.is_error
      });
    }
    return results.length === 1 ? results[0] : { kind: "batch", items: results };
  }

  if (e.type === "result") {
    return {
      kind: "result",
      isError: !!e.is_error,
      text: e.result || "",
      costUsd: e.total_cost_usd || e.cost_usd || 0,
      durationMs: e.duration_ms || 0,
      usage: e.usage || null,
      sessionId: e.session_id || ""
    };
  }

  if (e.type === "stream_event") {
    return { kind: "stream_event", event: e.event || null };
  }

  return { kind: "raw", line: trimmed };
}

// Summarize tool input for display (one-line preview).
function summarizeToolInput(name, input) {
  if (!input || typeof input !== "object") { return ""; }
  switch (name) {
    case "Bash":        return input.command || "";
    case "Read":        return input.file_path || "";
    case "Write":       return input.file_path || "";
    case "Edit":        return input.file_path || "";
    case "Glob":        return input.pattern || "";
    case "Grep":        return (input.pattern || "") + (input.path ? " in " + input.path : "");
    case "WebFetch":    return input.url || "";
    case "WebSearch":   return input.query || "";
    case "Task":        return input.description || input.subagent_type || "";
    default:
      try { return JSON.stringify(input).slice(0, 240); } catch (e) { return ""; }
  }
}

// Safety classification for a tool invocation. Drives the UI warning colour.
// Returns "safe" | "write" | "exec" | "network".
function classifyTool(name) {
  if (!name) { return "safe"; }
  if (name === "Bash") { return "exec"; }
  if (name === "Write" || name === "Edit" || name === "NotebookEdit") { return "write"; }
  if (name === "WebFetch" || name === "WebSearch") { return "network"; }
  if (name.indexOf("mcp__") === 0) { return "network"; }
  return "safe";
}

// Persist + restore
function processLoadedState(content) {
  if (!content || String(content).trim() === "") { return null; }
  try {
    var c = JSON.parse(content);
    return {
      messages: c.messages || [],
      sessionId: c.sessionId || "",
      lastModel: c.lastModel || "",
      lastPermissionMode: c.lastPermissionMode || "default",
      inputText: c.inputText || "",
      inputCursor: c.inputCursor || 0
    };
  } catch (err) {
    return { error: err.toString() };
  }
}

function prepareStateForSave(state, maxHistory) {
  var max = maxHistory && maxHistory > 0 ? maxHistory : 200;
  var msgs = (state.messages || []).slice(-max);
  return JSON.stringify({
    messages: msgs,
    sessionId: state.sessionId || "",
    lastModel: state.lastModel || "",
    lastPermissionMode: state.lastPermissionMode || "default",
    inputText: state.inputText || "",
    inputCursor: state.inputCursor || 0,
    timestamp: Math.floor(Date.now() / 1000)
  }, null, 2);
}

