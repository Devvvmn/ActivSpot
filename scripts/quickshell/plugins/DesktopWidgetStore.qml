pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Shared state for desktop widgets (manifest "desktopWidget" plugins):
//   • per-plugin transform { x, y, scale, enabled }, persisted to
//     ~/.cache/quickshell/desktop_widgets.json
//   • editMode, mirrored from the unified edit mode (/tmp/qs_edit_mode, written
//     by DynamicIsland.enter/exitEditBarMode)
//
// Consumed by PluginDesktopHost (renders + drag/scale) and AppletPickerPage
// (lists installed desktop widgets + show/hide toggle). Both already share the
// PluginLoader singleton, so this is shared across all windows in the engine.
Singleton {
    id: root

    property var store: ({})
    property bool editMode: false

    // pid of the widget currently being dragged/scaled. While set, that widget's
    // window grabs full-screen input (so the cursor can't leave the input mask
    // and drop the grab) and every other desktop widget disables input.
    property string activeDrag: ""

    Component.onCompleted: { _load(); _watcher.running = true; _editWatcher.running = true }

    function entry(id)     { return store[id] || ({}) }
    function isEnabled(id) { return entry(id).enabled !== false }

    function saveEntry(id, data) {
        const next = Object.assign({}, store)
        next[id] = Object.assign({}, next[id] || {}, data)
        store = next
        const b64 = Qt.btoa(JSON.stringify(next))
        Quickshell.execDetached(["bash", "-c",
            "mkdir -p ~/.cache/quickshell && echo '" + b64 +
            "' | base64 -d > ~/.cache/quickshell/desktop_widgets.json"])
    }

    function toggleEnabled(id) { saveEntry(id, { enabled: !isEnabled(id) }) }

    // ── store file ───────────────────────────────────────────────────────────
    function _load() { _reader.running = false; _reader.running = true }

    Process {
        id: _reader
        running: false
        command: ["bash", "-c", "cat ~/.cache/quickshell/desktop_widgets.json 2>/dev/null || echo '{}'"]
        stdout: StdioCollector {}
        onExited: {
            try {
                const parsed = JSON.parse(_reader.stdout.text.trim() || "{}")
                root.store = (parsed && typeof parsed === "object") ? parsed : ({})
            } catch (e) {
                console.warn("[DesktopWidgetStore] bad json:", e)
                root.store = ({})
            }
        }
    }

    // External writes (e.g. the picker toggling enabled) re-sync every consumer.
    Process {
        id: _watcher
        running: false
        command: ["bash", "-c",
            "while inotifywait -qq -e close_write,moved_to ~/.cache/quickshell/desktop_widgets.json 2>/dev/null; do echo r; done"]
        stdout: SplitParser { onRead: root._load() }
    }

    // ── edit-mode flag (persistent, not consumed) ────────────────────────────
    Process {
        id: _editWatcher
        running: false
        command: ["bash", "-c",
            "inotifywait -qq -e close_write,moved_to,create --include 'qs_edit_mode$' /tmp/ 2>/dev/null; " +
            "cat /tmp/qs_edit_mode 2>/dev/null || echo 0"]
        stdout: StdioCollector {}
        onExited: {
            root.editMode = (_editWatcher.stdout.text.trim() === "1")
            _editWatcher.running = false
            _editWatcher.running = true
        }
    }
}
