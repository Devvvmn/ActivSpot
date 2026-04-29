pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Reads ~/.cache/quickshell/plugins.json and exposes the list of installed
// Noctalia-compatible plugins. Re-reads whenever scan_plugins.sh updates
// /tmp/qs_plugins_reload (watched via inotifywait so atomic writes are caught).

Singleton {
    id: root

    property var plugins: []

    Component.onCompleted: {
        _load()
        _watcher.running = true
    }

    // inotifywait loop: fires onRead each time the reload signal file is written
    Process {
        id: _watcher
        running: false
        command: [
            "bash", "-c",
            "while inotifywait -qq -e close_write,moved_to /tmp/qs_plugins_reload 2>/dev/null; do echo reload; done"
        ]
        stdout: SplitParser {
            onRead: root._load()
        }
    }

    Process {
        id: _reader
        running: false
        command: ["bash", "-c", "cat ~/.cache/quickshell/plugins.json 2>/dev/null || echo '[]'"]
        stdout: StdioCollector {}
        onExited: {
            try {
                let parsed = JSON.parse(_reader.stdout.text.trim())
                root.plugins = Array.isArray(parsed) ? parsed : []
            } catch (e) {
                console.warn("[PluginLoader] Failed to parse plugins.json:", e)
                root.plugins = []
            }
        }
    }

    function _load() {
        _reader.running = false
        _reader.running = true
    }

    function findPlugin(pluginId) {
        for (let i = 0; i < plugins.length; i++) {
            if (plugins[i].id === pluginId) return plugins[i]
        }
        return null
    }
}
