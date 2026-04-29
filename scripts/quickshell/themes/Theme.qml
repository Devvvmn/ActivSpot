pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Single source of truth for theming.
//
// Holds the active theme id, the palette, and the structural surface style.
// Reads ~/.config/hypr/settings.json once at startup and re-reads on
// inotify events, so TopBar / DynamicIsland / AppletPicker / popups just
// bind to Theme.* and never duplicate the IO.
//
// Adding a palette-only theme: extend `themePalette()` with a new branch
// that returns a colour map. Adding a structural theme: introduce a new
// `surfaceStyle` value and let call sites switch on it.
QtObject {
    id: root

    property string themeId: "mocha"

    readonly property string surfaceStyle: themeId === "glass" ? "glass" : "solid"
    readonly property bool isGlass: surfaceStyle === "glass"

    // ── Palette ────────────────────────────────────────────────────
    // Catppuccin Mocha — used by the mocha and glass themes, and as the
    // fallback for any key matugen hasn't supplied.
    readonly property var _mochaPalette: ({
        base: "#1e1e2e", mantle: "#181825", crust: "#11111b",
        text: "#cdd6f4", subtext0: "#a6adc8", subtext1: "#bac2de",
        surface0: "#313244", surface1: "#45475a", surface2: "#585b70",
        overlay0: "#6c7086", overlay1: "#7f849c", overlay2: "#9399b2",
        blue: "#89b4fa", sapphire: "#74c7ec", peach: "#fab387",
        green: "#a6e3a1", red: "#f38ba8", mauve: "#cba6f7",
        pink: "#f5c2e7", yellow: "#f9e2af", maroon: "#eba0ac",
        teal: "#94e2d5"
    })

    // Gruvbox Light (Hard) — warm cream paper palette.
    readonly property var _gruvboxPalette: ({
        base: "#f9f5d7", mantle: "#f2e5bc", crust: "#ebdbb2",
        text: "#3c3836", subtext0: "#7c6f64", subtext1: "#504945",
        surface0: "#ebdbb2", surface1: "#d5c4a1", surface2: "#bdae93",
        overlay0: "#a89984", overlay1: "#928374", overlay2: "#7c6f64",
        blue: "#076678", sapphire: "#427b58", peach: "#af3a03",
        green: "#79740e", red: "#9d0006", mauve: "#d65d0e",
        pink: "#b16286", yellow: "#b57614", maroon: "#cc241d",
        teal: "#427b58"
    })

    // Apple-like — macOS default (light) with system blue accent.
    readonly property var _applePalette: ({
        base: "#f5f5f7", mantle: "#ffffff", crust: "#e5e5ea",
        text: "#1d1d1f", subtext0: "#6e6e73", subtext1: "#3a3a3c",
        surface0: "#ebebf0", surface1: "#d1d1d6", surface2: "#c7c7cc",
        overlay0: "#aeaeb2", overlay1: "#8e8e93", overlay2: "#636366",
        blue: "#007aff", sapphire: "#5ac8fa", peach: "#ff9500",
        green: "#34c759", red: "#ff3b30", mauve: "#007aff",
        pink: "#ff2d55", yellow: "#ffcc00", maroon: "#ff6961",
        teal: "#5ac8fa"
    })

    // Nord — arctic, north-bluish palette.
    readonly property var _nordPalette: ({
        base: "#2e3440", mantle: "#272c36", crust: "#1f242c",
        text: "#eceff4", subtext0: "#d8dee9", subtext1: "#e5e9f0",
        surface0: "#3b4252", surface1: "#434c5e", surface2: "#4c566a",
        overlay0: "#616e88", overlay1: "#7b88a1", overlay2: "#8fbcbb",
        blue: "#81a1c1", sapphire: "#88c0d0", peach: "#d08770",
        green: "#a3be8c", red: "#bf616a", mauve: "#88c0d0",
        pink: "#b48ead", yellow: "#ebcb8b", maroon: "#bf616a",
        teal: "#8fbcbb"
    })

    function _staticPalette(id) {
        switch (id) {
            case "gruvbox": return _gruvboxPalette
            case "apple":   return _applePalette
            case "nord":    return _nordPalette
            default:        return _mochaPalette
        }
    }

    // Active palette. Gets reassigned (always a new object) whenever the
    // theme changes or matugen output is reloaded — that's what makes the
    // colour bindings below re-evaluate.
    property var _palette: _mochaPalette

    // Each colour is a binding on _palette, so swapping the palette object
    // updates every consumer in one go.
    readonly property color base:     _palette.base
    readonly property color mantle:   _palette.mantle
    readonly property color crust:    _palette.crust
    readonly property color text:     _palette.text
    readonly property color subtext0: _palette.subtext0
    readonly property color subtext1: _palette.subtext1
    readonly property color surface0: _palette.surface0
    readonly property color surface1: _palette.surface1
    readonly property color surface2: _palette.surface2
    readonly property color overlay0: _palette.overlay0
    readonly property color overlay1: _palette.overlay1
    readonly property color overlay2: _palette.overlay2
    readonly property color blue:     _palette.blue
    readonly property color sapphire: _palette.sapphire
    readonly property color peach:    _palette.peach
    readonly property color green:    _palette.green
    readonly property color red:      _palette.red
    readonly property color mauve:    _palette.mauve
    readonly property color pink:     _palette.pink
    readonly property color yellow:   _palette.yellow
    readonly property color maroon:   _palette.maroon
    readonly property color teal:     _palette.teal

    // Semantic aliases — prefer these in new code so a theme that doesn't
    // share Catppuccin's naming can slot in without renaming applets.
    readonly property color accent: mauve
    readonly property color accentAlt: blue
    readonly property color warning: peach
    readonly property color danger: red
    readonly property color positive: green

    // ── Computed surface colours ──────────────────────────────────
    readonly property color pillColor: isGlass
        ? Qt.rgba(1, 1, 1, 0.09)
        : Qt.rgba(mantle.r, mantle.g, mantle.b, 1.0)
    readonly property color pillBorderColor: isGlass
        ? Qt.rgba(1, 1, 1, 0.18)
        : Qt.rgba(text.r, text.g, text.b, 0.12)

    function surfaceTint(alpha) {
        return Qt.rgba(base.r, base.g, base.b, isGlass ? alpha * 0.4 : alpha)
    }

    // ── Theme switching ───────────────────────────────────────────
    function _matugenMerged(jsonText) {
        // Returns a new palette object, falling back to mocha values for
        // any key matugen didn't supply. Returns null on parse failure.
        if (!jsonText || !jsonText.trim().length) return null
        try {
            const d = JSON.parse(jsonText)
            const out = {}
            const keys = Object.keys(_mochaPalette)
            for (let i = 0; i < keys.length; i++) {
                const k = keys[i]
                out[k] = (typeof d[k] === "string" && d[k].length) ? d[k] : _mochaPalette[k]
            }
            return out
        } catch (e) {
            return null
        }
    }

    onThemeIdChanged: _applyTheme()

    function _applyTheme() {
        if (themeId === "matugen") {
            // Restart reader so it pulls latest qs_colors.json. Watcher is
            // managed imperatively to avoid binding-break races.
            colorsReader.running = false
            colorsReader.running = true
            colorsWatcher.running = false
            colorsWatcher.running = true
        } else {
            colorsReader.running = false
            colorsWatcher.running = false
            _palette = _staticPalette(themeId)
        }
    }

    // ── Settings IO ───────────────────────────────────────────────
    property Process _settingsReader: Process {
        id: settingsReader
        running: true
        command: ["bash", "-c", "cat ~/.config/hypr/settings.json 2>/dev/null || echo '{}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(this.text.trim() || "{}")
                    if (typeof d.topbarTheme === "string" && d.topbarTheme.length
                        && root.themeId !== d.topbarTheme) {
                        root.themeId = d.topbarTheme
                    }
                } catch (e) {}
            }
        }
    }

    property Process _settingsWatcher: Process {
        id: settingsWatcher
        running: true
        command: ["bash", "-c",
            "while [ ! -f ~/.config/hypr/settings.json ]; do sleep 1; done; " +
            "inotifywait -qq -e modify,close_write,move_self,attrib ~/.config/hypr/settings.json"]
        stdout: StdioCollector {
            onStreamFinished: {
                settingsReader.running = false
                settingsReader.running = true
                settingsWatcher.running = false
                settingsWatcher.running = true
            }
        }
    }

    // ── Matugen palette source ────────────────────────────────────
    property Process _colorsReader: Process {
        id: colorsReader
        running: false
        command: ["bash", "-c", "cat ~/.config/hypr/scripts/quickshell/qs_colors.json 2>/dev/null || echo ''"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (root.themeId !== "matugen") return
                const merged = root._matugenMerged(this.text)
                root._palette = merged ? merged : root._mochaPalette
            }
        }
    }

    // inotify-driven reload: matugen rewrites qs_colors.json on each
    // wallpaper change. running is set imperatively from _applyTheme().
    property Process _colorsWatcher: Process {
        id: colorsWatcher
        running: false
        command: ["bash", "-c",
            "F=~/.config/hypr/scripts/quickshell/qs_colors.json; " +
            "while [ ! -f \"$F\" ]; do sleep 1; done; " +
            "inotifywait -qq -e modify,close_write,move_self,create \"$F\""]
        stdout: StdioCollector {
            onStreamFinished: {
                if (root.themeId !== "matugen") return
                colorsReader.running = false
                colorsReader.running = true
                colorsWatcher.running = false
                colorsWatcher.running = true
            }
        }
    }
}
