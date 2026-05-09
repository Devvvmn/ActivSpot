import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services.UI

Item {
    id: root
    visible: false
    width: 0; height: 0

    property string pluginDir: ""
    property var    manifest:  ({})

    readonly property var pluginSettings: {
        let defaults = manifest?.metadata?.defaultSettings ?? {}
        return Object.assign({}, defaults, _userSettings[manifest?.id ?? ""] ?? {})
    }

    property var mainInstance: null

    // Which screen the plugin panel was last opened on. Plugins read this to
    // route closePanel() calls through PanelService.
    property var panelOpenScreen: null

    // Last-used anchor — lets togglePanel(screen) work when called from Main.qml
    // (no widget reference available).
    property var _lastAnchor: null

    // ── i18n ─────────────────────────────────────────────────────────────
    readonly property string _locale: Qt.locale().name.substring(0, 2)
    property var _i18n: ({})

    function tr(key, params) {
        if (!key) return ""
        let parts = key.split(".")
        let val   = _i18n
        for (let p of parts) {
            if (val === null || val === undefined || typeof val !== "object") return ""
            val = val[p]
        }
        if (typeof val !== "string") return ""
        if (params) {
            for (let k in params)
                val = val.replace(new RegExp("\\{" + k + "\\}", "g"), String(params[k]))
        }
        return val
    }

    Process {
        id: i18nReader
        running: false
        command: ["bash", "-c",
            "LOCALE='" + root._locale + "'; " +
            "DIR='" + root.pluginDir + "'; " +
            "F=\"$DIR/i18n/$LOCALE.json\"; " +
            "[ -f \"$F\" ] || F=\"$DIR/i18n/en.json\"; " +
            "cat \"$F\" 2>/dev/null || echo '{}'"
        ]
        stdout: StdioCollector {}
        onExited: {
            try { root._i18n = JSON.parse(i18nReader.stdout.text.trim()) ?? {} }
            catch (_) {}
        }
    }

    // ── Panel open/close/toggle ──────────────────────────────────────────
    function _panelSource() {
        let entry = manifest?.entryPoints?.panel
        if (!entry || !pluginDir) return ""
        return "file://" + pluginDir + "/" + entry
    }

    function openPanel(screen, anchor) {
        let src = _panelSource()
        if (!src) return false
        if (anchor) root._lastAnchor = anchor
        let pluginId = manifest?.id ?? ""
        let ok = PanelService.openPluginPanel(
            pluginId, src,
            { "pluginApi": root, "screen": screen ?? null },
            screen, anchor ?? root._lastAnchor)
        if (ok) root.panelOpenScreen = screen ?? null
        return ok
    }

    function closePanel(screen) {
        let pluginId = manifest?.id ?? ""
        let closed = PanelService.closePluginPanel(pluginId)
        if (closed) root.panelOpenScreen = null
        return closed
    }

    function togglePanel(screen, anchor) {
        let pluginId = manifest?.id ?? ""
        if (PanelService.isPanelOpenFor(pluginId)) {
            return closePanel(screen)
        }
        return openPanel(screen, anchor ?? root._lastAnchor)
    }

    // Watch global panel state — if our panel was closed by something else
    // (outside click, another plugin opening its panel), clear our flag.
    Connections {
        target: PanelService
        function onPanelVisibleChanged() {
            if (!PanelService.panelVisible) root.panelOpenScreen = null
        }
        function on_PanelPluginIdChanged() {
            if (PanelService._panelPluginId !== (root.manifest?.id ?? ""))
                root.panelOpenScreen = null
        }
    }

    // ── User settings ─────────────────────────────────────────────────────
    property var _userSettings: ({})

    Process {
        id: settingsReader
        running: false
        command: ["bash", "-c", "cat ~/.config/hypr/plugin-settings.json 2>/dev/null || echo '{}'"]
        stdout: StdioCollector {}
        onExited: {
            try {
                root._userSettings = JSON.parse(settingsReader.stdout.text.trim()) ?? {}
            } catch (_) {
                root._userSettings = {}
            }
        }
    }

    onPluginDirChanged: {
        settingsReader.running = false
        settingsReader.running = true
        i18nReader.running = false
        i18nReader.running = true
    }
}
