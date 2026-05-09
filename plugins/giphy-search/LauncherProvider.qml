import QtQuick
import Quickshell
import qs.Commons

Item {
    id: root

    property var pluginApi: null
    property var launcher: null
    property string name: "Giphy Search"

    property bool handleSearch: true
    property string supportedLayouts: "grid"
    property real preferredGridColumns: 7
    property real preferredGridCellRatio: 1.0

    property var gifResults: []
    property string lastQuery: ""

    readonly property var cfg: pluginApi?.pluginSettings || ({})
    readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

    readonly property string apiKey: cfg.api_key ?? defaults.api_key ?? ""
    readonly property int maxResults: 20
    readonly property string rating: cfg.rating ?? defaults.rating ?? "g"

    function getResults(searchText) {
        let results = [];
        let rawText = searchText.trim();
        let isCommand = rawText.startsWith(">gif");
        let query = rawText;

        if (isCommand) {
            query = rawText.slice(5).trim();
        }

        if (query === "" && !isCommand) return [];
        if (rawText.startsWith(">") && !isCommand) return [];

        if (apiKey === "") {
            return [{
                "provider": root,
                "name": pluginApi?.tr("launcher.noApiKey"),
                "description": pluginApi?.tr("launcher.noApiKeyDescription"),
                "icon": "alert-triangle",
                "isTablerIcon": true
            }];
        }

        if (isCommand && query === "") {
            return [{
                "provider": root,
                "name": pluginApi?.tr("launcher.typeSomething"),
                "description": pluginApi?.tr("launcher.searchGiphy"),
                "icon": "gif",
                "isTablerIcon": true
            }];
        }

        results.push({
            "provider": root,
            "name": pluginApi?.tr("launcher.search", { query: query }),
            "description": pluginApi?.tr("launcher.openOnGiphy"),
            "icon": "gif",
            "isTablerIcon": true,
            "_score": isCommand ? 999 : -5,
            "onActivate": function() {
                Qt.openUrlExternally("https://giphy.com/search/" + encodeURIComponent(query));
                if (launcher) launcher.close();
            }
        });

        if (query !== lastQuery && query.length > 1) {
            lastQuery = query;
            gifResults = [];
            if (launcher) launcher.updateResults();
            fetchGifs(query);
        }

        if (gifResults.length > 0) {
            for (let i = 0; i < gifResults.length; i++) {
                let gif = gifResults[i];
                let previewUrl = gif.images.fixed_height?.url
                    || gif.images.fixed_width?.url || "";
                let originalUrl = gif.images.original?.url || gif.url;
                results.push({
                    "provider": root,
                    "name": gif.title || pluginApi?.tr("launcher.untitled"),
                    "description": pluginApi?.tr("launcher.copyUrl"),
                    "icon": previewUrl,
                    "isTablerIcon": false,
                    "isImage": previewUrl !== "",
                    "_score": isCommand ? (900 - i) : (-10 - i),
                    "onActivate": function() {
                        copyToClipboard(originalUrl);
                        if (launcher) launcher.close();
                    }
                });
            }
        }

        return results;
    }

    function copyToClipboard(text) {
        let escaped = text.replace(/'/g, "'\\''");
        Quickshell.execDetached(["sh", "-c", "printf '%s' '" + escaped + "' | wl-copy"]);
    }

    function getImageUrl(modelData) {
        if (modelData.isImage) {
            return modelData.icon;
        }
        return null;
    }

    function fetchGifs(query) {
        let xhr = new XMLHttpRequest();
        let url = "https://api.giphy.com/v1/gifs/search?api_key=" + encodeURIComponent(apiKey)
            + "&q=" + encodeURIComponent(query)
            + "&limit=" + maxResults
            + "&rating=" + encodeURIComponent(rating);

        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    if (query !== lastQuery) return;
                    try {
                        let data = JSON.parse(xhr.responseText);
                        if (data.data && Array.isArray(data.data)) {
                            gifResults = data.data;
                            if (launcher) launcher.updateResults();
                        }
                    } catch (e) {
                        Logger.e("GiphySearch", "JSON Parse error: " + e.message);
                    }
                } else {
                    Logger.e("GiphySearch", "API request failed with status: " + xhr.status);
                }
            }
        }
        xhr.open("GET", url);
        xhr.send();
    }

    function handleCommand(searchText) {
        return searchText.startsWith(">gif");
    }

    function commands() {
        return [{
            "name": ">gif",
            "description": pluginApi?.tr("launcher.command.description"),
            "icon": "gif",
            "isTablerIcon": true,
            "onActivate": function() {
                launcher.setSearchText(">gif ");
            }
        }];
    }
}
