import QtQuick
import Quickshell
import Quickshell.Io
import themes

// Wallpaper-level picture frame. Scans a configurable folder, then slowly
// cycles through the images with a paper matte and a crossfade between shots.
//
// Settings come from ~/.config/hypr/plugin-settings.json["photo-frame"] (written
// by the config-ui Addons section), merged over the defaults below and watched
// for live updates. Schema is declared in manifest.json → "settings".
//
// Desktop-widget contract: root is an Item, size via implicitWidth/Height,
// never anchor to screen edges — the host positions/scales us. Don't name any
// Item property `data` (silently kills child rendering).
Item {
    id: root

    property var screen: null
    property string pluginDir: ""
    readonly property string pluginId: "photo-frame"
    // Set by PluginDesktopHost for extra instances ("photo-frame#2", …). The base
    // instance leaves this empty and keys its settings under the plain plugin id.
    property string instanceId: ""
    readonly property string cfgKey: instanceId || pluginId

    // ── settings (defaults; overridden by plugin-settings.json) ───────────────
    property var _cfg: ({})
    readonly property string cfgDir: _cfg.dir || "~/Pictures/Wallpapers"
    readonly property int advanceMs: Math.max(2, _cfg.advanceSec || 8) * 1000
    readonly property int fadeMs: (_cfg.fadeMs === undefined) ? 700 : Math.max(0, _cfg.fadeMs)
    readonly property bool shuffle: _cfg.shuffle === true
    readonly property int rescanMs: 60000   // re-scan folder for new files

    readonly property string resolvedDir:
        cfgDir.replace(/^~(?=$|\/)/, Quickshell.env("HOME"))

    // ── geometry ─────────────────────────────────────────────────────────────
    readonly property int frameW: 12           // outer frame thickness
    readonly property int matteW: 16           // inner paper matte border
    readonly property int photoW: 300
    readonly property int photoH: 190

    implicitWidth:  photoW + 2 * (frameW + matteW)
    implicitHeight: photoH + 2 * (frameW + matteW)

    readonly property bool motion: !Theme.reduceMotion

    // ── settings file (read + live watch) ─────────────────────────────────────
    function _loadCfg() { cfgReader.running = false; cfgReader.running = true }

    // instanceId arrives after load (host sets it) → re-read under the new key.
    onCfgKeyChanged: _loadCfg()

    Process {
        id: cfgReader
        running: false
        command: ["bash", "-c",
            "cat ~/.config/hypr/plugin-settings.json 2>/dev/null || echo '{}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const all = JSON.parse((this.text || "{}").trim() || "{}")
                    root._cfg = (all && all[root.cfgKey]) ? all[root.cfgKey] : ({})
                } catch (e) { root._cfg = ({}) }
            }
        }
    }
    // Single-shot inotify + restart (the pattern used across the shell). Anchored
    // --include so we only wake on writes to the settings file itself.
    Process {
        id: cfgWatcher
        running: true
        command: ["bash", "-c",
            "inotifywait -qq -e close_write,moved_to,create " +
            "--include 'plugin-settings.json$' ~/.config/hypr/ 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                root._loadCfg()
                cfgWatcher.running = false
                cfgWatcher.running = true
            }
        }
    }

    // Re-scan and restart from the first image whenever the folder changes.
    onResolvedDirChanged: { _shownA = ""; _shownB = ""; idx = 0; _scan() }

    // ── photo list ───────────────────────────────────────────────────────────
    property var files: []
    property int idx: 0
    property bool _useA: true          // which Image layer is currently on top
    property string _shownA: ""
    property string _shownB: ""

    function _scan() { scanProc.running = false; scanProc.running = true }

    Process {
        id: scanProc
        running: false
        // $1 = resolved folder; passed as argv so paths with spaces are safe.
        command: ["bash", "-c",
            "find \"$1\" -maxdepth 1 -type f " +
            "\\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' " +
            "-o -iname '*.webp' -o -iname '*.gif' \\) 2>/dev/null | sort",
            "_", root.resolvedDir]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = (this.text || "").trim()
                const arr = lines.length ? lines.split("\n").filter(s => s.length) : []
                const changed = JSON.stringify(arr) !== JSON.stringify(root.files)
                root.files = arr
                if (changed && arr.length && root._shownA === "" && root._shownB === "")
                    root._show(0, false)   // first paint, no fade
            }
        }
    }

    function _srcAt(i) {
        if (!files.length) return ""
        const n = ((i % files.length) + files.length) % files.length
        return "file://" + files[n]
    }

    // Load `i` into the hidden layer, then crossfade it to the front.
    function _show(i, animate) {
        if (!files.length) return
        idx = ((i % files.length) + files.length) % files.length
        const src = _srcAt(idx)
        if (!animate || !motion || fadeMs === 0) {
            _shownA = src; _shownB = ""; _useA = true
            imgA.opacity = 1; imgB.opacity = 0
            return
        }
        if (_useA) { _shownB = src } else { _shownA = src }
        _useA = !_useA
        fade.restart()
    }

    function _nextIdx() {
        if (files.length <= 1) return idx
        if (!shuffle) return idx + 1
        let n = idx
        while (n === idx) n = Math.floor(Math.random() * files.length)
        return n
    }
    function _advance() { if (files.length > 1) _show(_nextIdx(), true) }

    ParallelAnimation {
        id: fade
        NumberAnimation { target: imgA; property: "opacity"; to: root._useA ? 1 : 0; duration: root.fadeMs; easing.type: Easing.InOutCubic }
        NumberAnimation { target: imgB; property: "opacity"; to: root._useA ? 0 : 1; duration: root.fadeMs; easing.type: Easing.InOutCubic }
    }

    Timer { interval: root.advanceMs; running: root.files.length > 1; repeat: true; onTriggered: root._advance() }
    Timer { interval: root.rescanMs; running: true; repeat: true; onTriggered: root._scan() }
    Component.onCompleted: { _loadCfg(); _scan() }

    // ── soft drop shadow ─────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: frame
        anchors.topMargin: 6
        anchors.leftMargin: 3
        radius: 8
        color: Qt.rgba(0, 0, 0, 0.45)
        z: -1
    }

    // ── frame (bevelled) ─────────────────────────────────────────────────────
    Rectangle {
        id: frame
        anchors.fill: parent
        radius: 8
        border.width: 1
        border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.18)
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.lighter(Theme.surface1, 1.12) }
            GradientStop { position: 0.5; color: Theme.surface0 }
            GradientStop { position: 1.0; color: Qt.darker(Theme.surface0, 1.25) }
        }

        // paper matte
        Rectangle {
            id: matte
            anchors.fill: parent
            anchors.margins: root.frameW
            radius: 3
            // warm paper matte — intentional light tone so photos read like prints
            color: Qt.rgba(0.93, 0.91, 0.87, 1.0)
            border.width: 1
            border.color: Qt.rgba(0, 0, 0, 0.10)

            // photo well
            Rectangle {
                id: well
                anchors.fill: parent
                anchors.margins: root.matteW
                radius: 2
                clip: true
                color: Qt.rgba(0, 0, 0, 0.9)

                // inner shadow line so the photo sits "inside" the matte
                border.width: 1
                border.color: Qt.rgba(0, 0, 0, 0.35)

                Image {
                    id: imgA
                    anchors.fill: parent
                    source: root._shownA
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                    opacity: 1
                }
                Image {
                    id: imgB
                    anchors.fill: parent
                    source: root._shownB
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                    opacity: 0
                }

                // empty-folder hint
                Text {
                    anchors.centerIn: parent
                    width: parent.width - 24
                    visible: root.files.length === 0
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: "No images in\n" + root.cfgDir
                    color: Qt.rgba(1, 1, 1, 0.7)
                    font.pixelSize: 13
                }
            }
        }
    }
}
