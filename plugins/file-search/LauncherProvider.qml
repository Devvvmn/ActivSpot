import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Item {
  id: root

  property var pluginApi: null

  // Provider metadata
  property string name: pluginApi?.tr("provider.name")
  property var launcher: null
  property bool handleSearch: false
  property string supportedLayouts: "list"
  property bool supportsAutoPaste: false

  // Search state
  property var currentResults: []
  property string currentQuery: ""
  property bool searching: false
  property int nextRequestId: 0
  property int activeRequestId: 0
  property int fileProcessRequestId: 0
  property int dirProcessRequestId: 0
  property int pendingProcessCount: 0
  property bool currentRequestFailed: false
  property var pendingResultsByType: ({ "files": [], "dirs": [] })
  property string fdCommandPath: ""
  property bool fdAvailable: false

  // Settings shortcuts
  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
  property bool showHidden: cfg.showHidden ?? defaults.showHidden ?? false
  property int maxResults: cfg.maxResults ?? defaults.maxResults ?? 0
  property string fileOpener: cfg.fileOpener ?? defaults.fileOpener ?? "xdg-open"
  property string fdCommand: cfg.fdCommand ?? defaults.fdCommand ?? "fd"
  property string searchDirectory: cfg.searchDirectory ?? defaults.searchDirectory ?? "~"

  Process {
    id: fileSearchProcess
    running: false

    stdout: StdioCollector {
      id: fileStdoutCollector
    }

    stderr: StdioCollector {
      id: fileStderrCollector
    }

    onExited: function(exitCode) {
      root.handleSearchProcessExit("files", fileProcessRequestId, exitCode, fileStdoutCollector.text, fileStderrCollector.text);
    }
  }

  Process {
    id: dirSearchProcess
    running: false

    stdout: StdioCollector {
      id: dirStdoutCollector
    }

    stderr: StdioCollector {
      id: dirStderrCollector
    }

    onExited: function(exitCode) {
      root.handleSearchProcessExit("dirs", dirProcessRequestId, exitCode, dirStdoutCollector.text, dirStderrCollector.text);
    }
  }

  // Debounce timer for search
  Timer {
    id: searchDebouncer
    interval: 300
    repeat: false
    onTriggered: root.executeSearch(root.currentQuery)
  }

  function init() {
    Logger.i("FileSearch", "Initializing plugin");
    fdCommandPath = fdCommand;
    fdAvailable = true;
    Logger.i("FileSearch", "Using fd command:", fdCommandPath);
  }

  function handleCommand(searchText) {
    return searchText.startsWith(">file");
  }

  function commands() {
    return [{
      "name": ">file",
      "description": pluginApi?.tr("launcher.command.description"),
      "icon": "file-search",
      "isTablerIcon": true,
      "isImage": false,
      "onActivate": function() {
        launcher.setSearchText(">file ");
      }
    }];
  }

  function getResults(searchText) {
    if (!searchText.startsWith(">file")) {
      return [];
    }

    if (!fdAvailable) {
      return [{
        "name": pluginApi?.tr("launcher.errors.fdNotFound.title"),
        "description": pluginApi?.tr("launcher.errors.fdNotFound.description"),
        "icon": "alert-circle",
        "isTablerIcon": true,
        "isImage": false,
        "onActivate": function() {}
      }];
    }

    var query = searchText.slice(5).trim();

    if (query === "") {
      return [{
        "name": pluginApi?.tr("launcher.prompts.emptyQuery.title"),
        "description": pluginApi?.tr("launcher.prompts.emptyQuery.description", { "root": displaySearchDirectory() }),
        "icon": "file-search",
        "isTablerIcon": true,
        "isImage": false,
        "onActivate": function() {}
      }];
    }

    if (query !== currentQuery) {
      currentQuery = query;
      activeRequestId = 0;
      currentRequestFailed = false;
      searching = true;
      searchDebouncer.restart();
      
      return [{
        "name": pluginApi?.tr("launcher.prompts.searching.title"),
        "description": pluginApi?.tr("launcher.prompts.searching.description", { "query": query }),
        "icon": "refresh",
        "isTablerIcon": true,
        "isImage": false,
        "onActivate": function() {}
      }];
    }

    if (searching) {
      return [{
        "name": pluginApi?.tr("launcher.prompts.searching.title"),
        "description": pluginApi?.tr("launcher.prompts.searching.description", { "query": query }),
        "icon": "refresh",
        "isTablerIcon": true,
        "isImage": false,
        "onActivate": function() {}
      }];
    }

    return currentResults;
  }

  function executeSearch(query) {
    if (!fdAvailable || query === "") {
      return;
    }

    Logger.d("FileSearch", "Executing search for:", query);

    if (fileSearchProcess.running) {
      fileSearchProcess.running = false;
    }
    if (dirSearchProcess.running) {
      dirSearchProcess.running = false;
    }

    var expandedDir = expandHomePath(searchDirectory);

    nextRequestId += 1;
    var requestId = nextRequestId;
    activeRequestId = requestId;
    currentRequestFailed = false;
    pendingProcessCount = 2;
    pendingResultsByType = ({ "files": [], "dirs": [] });

    var commonArgs = [];

    if (showHidden) {
      commonArgs.push("--hidden");
    }

    if (maxResults > 0) {
      commonArgs.push("--max-results", maxResults.toString());
    }
    commonArgs.push("--base-directory", expandedDir);
    commonArgs.push("--absolute-path");
    commonArgs.push("--color", "never");
    commonArgs.push(query);

    var fileArgs = ["--type", "f"].concat(commonArgs);
    var dirArgs = ["--type", "d"].concat(commonArgs);

    fileProcessRequestId = requestId;
    fileSearchProcess.command = [fdCommandPath].concat(fileArgs);
    fileSearchProcess.running = true;

    dirProcessRequestId = requestId;
    dirSearchProcess.command = [fdCommandPath].concat(dirArgs);
    dirSearchProcess.running = true;

    Logger.d("FileSearch", "Running file command:", fdCommandPath, fileArgs.join(" "));
    Logger.d("FileSearch", "Running dir command:", fdCommandPath, dirArgs.join(" "));
  }

  function handleSearchProcessExit(kind, requestId, exitCode, stdoutText, stderrText) {
    if (requestId !== activeRequestId || currentRequestFailed) {
      return;
    }

    if (exitCode !== 0) {
      currentRequestFailed = true;
      searching = false;
      pendingProcessCount = 0;
      Logger.e("FileSearch", "fd command failed with exit code:", exitCode);
      Logger.e("FileSearch", "stderr:", stderrText);
      currentResults = [{
        "name": pluginApi?.tr("launcher.errors.fdNotFound.title"),
        "description": pluginApi?.tr("launcher.errors.fdNotFound.description"),
        "icon": "alert-circle",
        "isTablerIcon": true,
        "onActivate": function() {}
      }];
      if (launcher) {
        launcher.updateResults();
      }
      return;
    }

    pendingResultsByType[kind] = parseRawPaths(stdoutText);
    pendingProcessCount -= 1;

    if (pendingProcessCount <= 0) {
      finalizeSearchResults(requestId);
    }
  }

  function finalizeSearchResults(requestId) {
    if (requestId !== activeRequestId || currentRequestFailed) {
      return;
    }

    var results = [];

    for (var i = 0; i < pendingResultsByType.dirs.length; i++) {
      results.push(formatFileEntry(pendingResultsByType.dirs[i], true));
    }
    for (var j = 0; j < pendingResultsByType.files.length; j++) {
      results.push(formatFileEntry(pendingResultsByType.files[j], false));
    }

    results = sortResults(results, currentQuery);

    if (maxResults > 0 && results.length > maxResults) {
      results = results.slice(0, maxResults);
    }

    if (results.length === 0) {
      results.push({
        "name": pluginApi?.tr("launcher.prompts.noResults.title"),
        "description": pluginApi?.tr("launcher.prompts.noResults.description", { "query": currentQuery }),
        "icon": "file-off",
        "isTablerIcon": true,
        "isImage": false,
        "onActivate": function() {}
      });
      searching = false;
      currentResults = results;
      if (launcher) {
        launcher.updateResults();
      }
      return;
    }

    searching = false;
    currentResults = results;
    Logger.d("FileSearch", "Found", results.length, "results");
    if (launcher) {
      launcher.updateResults();
    }
  }

  function parseRawPaths(output) {
    var trimmed = output.trim();
    if (trimmed === "") {
      return [];
    }
    return trimmed.split("\n").filter(function(line) { return line.trim() !== ""; });
  }

  function expandHomePath(pathValue) {
    var expandedPath = pathValue;
    if (expandedPath.startsWith("~")) {
      expandedPath = Quickshell.env("HOME") + expandedPath.substring(1);
    }
    return expandedPath;
  }

  function displaySearchDirectory() {
    var expandedPath = expandHomePath(searchDirectory);
    var homeDir = Quickshell.env("HOME");
    if (expandedPath.startsWith(homeDir)) {
      return "~" + expandedPath.slice(homeDir.length);
    }
    return expandedPath;
  }

  function sortResults(results, query) {
    var queryLower = query.toLowerCase();
    results.sort(function(a, b) {
      var rankA = resultRank(a, queryLower);
      var rankB = resultRank(b, queryLower);
      if (rankA !== rankB) {
        return rankA - rankB;
      }

      var nameA = (a.name || "").toLowerCase();
      var nameB = (b.name || "").toLowerCase();
      if (nameA < nameB) {
        return -1;
      }
      if (nameA > nameB) {
        return 1;
      }
      return (a.description || "").length - (b.description || "").length;
    });
    return results;
  }

  function resultRank(result, queryLower) {
    var name = (result.name || "").toLowerCase();
    var description = (result.description || "").toLowerCase();
    var fullPath = description + "/" + name;

    if (name === queryLower) {
      return 0;
    }
    if (name.startsWith(queryLower)) {
      return 1;
    }
    if (name.indexOf(queryLower) !== -1) {
      return 2;
    }
    if (fullPath.indexOf(queryLower) !== -1) {
      return 3;
    }
    return 4;
  }

  function formatFileEntry(filePath, forcedIsDirectory) {
    var normalizedPath = filePath;
    while (normalizedPath.length > 1 && normalizedPath.endsWith("/")) {
      normalizedPath = normalizedPath.slice(0, -1);
    }

    var isDirectory = (forcedIsDirectory !== undefined) ? forcedIsDirectory : normalizedPath !== filePath;
    var parts = normalizedPath.split("/");
    var filename = parts[parts.length - 1];
    var parentPath = parts.slice(0, -1).join("/");

    if (filename === "") {
      filename = normalizedPath;
    }
    
    var homeDir = Quickshell.env("HOME");
    if (parentPath.startsWith(homeDir)) {
      parentPath = "~" + parentPath.slice(homeDir.length);
    }

    return {
      "name": filename,
      "description": parentPath,
      "icon": isDirectory ? "folder" : getFileIcon(filename),
      "isTablerIcon": true,
      "isImage": false,
      "singleLine": false,
      "onActivate": function() {
        root.openFile(normalizedPath);
      }
    };
  }

  function getFileIcon(filename) {
    var ext = filename.split(".").pop().toLowerCase();
    
    // Images
    if (["jpg", "jpeg", "png", "gif", "svg", "webp", "bmp", "ico"].indexOf(ext) !== -1) {
      return "photo";
    }
    
    // Documents
    if (["txt", "md", "pdf", "doc", "docx", "odt", "rtf"].indexOf(ext) !== -1) {
      return "file-text";
    }
    
    // Code files
    if (["js", "ts", "py", "java", "cpp", "c", "h", "qml", "rs", "go", "rb", "php", "html", "css", "json", "xml", "yaml", "yml"].indexOf(ext) !== -1) {
      return "code";
    }
    
    // Archives
    if (["zip", "tar", "gz", "bz2", "xz", "7z", "rar"].indexOf(ext) !== -1) {
      return "file-zip";
    }
    
    // Audio
    if (["mp3", "wav", "flac", "ogg", "m4a", "aac", "wma"].indexOf(ext) !== -1) {
      return "music";
    }
    
    // Video
    if (["mp4", "mkv", "avi", "mov", "wmv", "flv", "webm"].indexOf(ext) !== -1) {
      return "video";
    }
    
    // Spreadsheets
    if (["xls", "xlsx", "ods", "csv"].indexOf(ext) !== -1) {
      return "table";
    }
    
    // Presentations
    if (["ppt", "pptx", "odp"].indexOf(ext) !== -1) {
      return "presentation";
    }
    
    // Default
    return "file";
  }

  function openFile(filePath) {
    Logger.i("FileSearch", "Opening file:", filePath);
    Quickshell.execDetached([fileOpener, filePath]);
    launcher.close();
  }
}
