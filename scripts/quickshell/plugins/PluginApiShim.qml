import QtQuick
import Quickshell
import Quickshell.Io

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

    // ── i18n ─────────────────────────────────────────────────────────────
    readonly property string _locale: Qt.locale().name.substring(0, 2)
    property var _i18n: ({})

    // Resolve "some.nested.key" → value, replace {param} placeholders.
    // Returns "" on miss so plugin-side `|| fallback` chains work.
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

    // Panel opener stub — TODO: open Panel.qml inside island pages
    function openPanel(screen, anchor) {}

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
