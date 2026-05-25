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

    // ── User-configurable extension (driven by config-ui) ─────────
    // Palette overrides: { "crust": "#bbc1c9", … } merged on top of the
    // active theme palette. Empty by default.
    property var paletteOverrides: ({})

    // Enabled minibubble / page IDs (by short name, e.g. "Music", "Notif").
    // Empty array means "all enabled" — first config-ui save populates them.
    property var enabledBubbles: []
    property var enabledPages: []

    // Animation timings (ms). Defaults match the pre-config values used
    // throughout the shell, so an unset settings.json keeps existing feel.
    property int bubbleShowMs: 220
    property int bubbleHideMs: 360
    property int pageAnimDuration: 300

    // Lookup helpers used by minibubbles / page registry.
    function _hasCi(arr, id) {
        if (!arr || !arr.length || !id) return false
        const lo = String(id).toLowerCase()
        for (let i = 0; i < arr.length; i++) {
            if (String(arr[i]).toLowerCase() === lo) return true
        }
        return false
    }
    function bubbleEnabled(id) {
        if (!enabledBubbles || enabledBubbles.length === 0) return true
        return _hasCi(enabledBubbles, id)
    }
    // System pages users can't disable from the UI (no corresponding bubble
    // or core navigation surfaces).
    readonly property var _alwaysOnPages: ["appletPicker"]
    function pageEnabled(id) {
        if (_hasCi(_alwaysOnPages, id)) return true
        if (!enabledPages || enabledPages.length === 0) return true
        return _hasCi(enabledPages, id)
    }

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

    // Carbon + Silver — minimal premium dark palette. True graphite base,
    // silver accent, desaturated status colours so nothing fights for attention.
    readonly property var _carbonPalette: ({
        base: "#111111", mantle: "#1a1a1a", crust: "#0a0a0a",
        text: "#f5f5f5", subtext0: "#a1a1aa", subtext1: "#d4d4d8",
        surface0: "#242424", surface1: "#2e2e2e", surface2: "#3a3a3a",
        overlay0: "#52525b", overlay1: "#71717a", overlay2: "#a1a1aa",
        blue: "#60a5fa", sapphire: "#93c5fd", peach: "#fdba74",
        green: "#86efac", red: "#fca5a5", mauve: "#d4d4d8",
        pink: "#f0abfc", yellow: "#fde68a", maroon: "#fb923c",
        teal: "#5eead4"
    })

    // Midnight Indigo — deep space black base, electric indigo accent,
    // cool-white text. Vision Pro / Figma-grade dark aesthetic.
    readonly property var _midnightPalette: ({
        base: "#08080f", mantle: "#0f0f1a", crust: "#04040a",
        text: "#e2e2ff", subtext0: "#9898c8", subtext1: "#c4c4f0",
        surface0: "#16162a", surface1: "#1e1e38", surface2: "#272748",
        overlay0: "#4040a0", overlay1: "#5858b8", overlay2: "#7878d0",
        blue: "#4fc3f7", sapphire: "#93c5fd", peach: "#fdba74",
        green: "#4ade80", red: "#f87171", mauve: "#7c7cf5",
        pink: "#e879f9", yellow: "#fde68a", maroon: "#fb923c",
        teal: "#2dd4bf"
    })

    function _staticPalette(id) {
        switch (id) {
            case "apple":    return _applePalette
            case "nord":     return _nordPalette
            case "carbon":   return _carbonPalette
            case "midnight": return _midnightPalette
            default:         return _mochaPalette
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

    // ── Design tokens ─────────────────────────────────────────────
    readonly property int durFast:  120
    readonly property int durMed:   220
    readonly property int durSlow:  320
    readonly property int durEnter: 280
    readonly property int durExit:  180

    readonly property int sp1: 4
    readonly property int sp2: 8
    readonly property int sp3: 12
    readonly property int sp4: 16
    readonly property int sp5: 24
    readonly property int sp6: 32

    readonly property int radXs: 6
    readonly property int radSm: 10
    readonly property int radMd: 14
    readonly property int radLg: 20
    readonly property int radXl: 28

    // ── Elevation tokens ──────────────────────────────────────────
    // Apple-grade depth: low opacity, large blur, small offset. Apply to
    // MultiEffect via shadowMaximumBlur=elev*Max, shadowBlur=1.0,
    // shadowOpacity=elev*Op, shadowVerticalOffset=elev*Off, shadowColor=shadowColor.
    //
    // elev1 — buttons, chips, hover cards
    // elev2 — popups, sheets, expanded surfaces
    // elev3 — modal/hero surfaces (album art, full-screen lock)
    readonly property color shadowColor: "#000000"

    readonly property real elev1Op:  isLight ? 0.08 : 0.18
    readonly property real elev1Max: 24
    readonly property int  elev1Off: 2

    readonly property real elev2Op:  isLight ? 0.10 : 0.22
    readonly property real elev2Max: 40
    readonly property int  elev2Off: 6

    readonly property real elev3Op:  isLight ? 0.12 : 0.28
    readonly property real elev3Max: 64
    readonly property int  elev3Off: 12

    // Light themes need lower-density shadows; structural light flag for
    // anyone consuming elevation tokens.
    readonly property bool isLight: themeId === "apple"

    property bool reduceMotion: false

    // Typography tokens. fontUI for prose/labels, fontMono for numbers/data,
    // fontDisplay for large hero text (time, big headings).
    readonly property string fontUI:      "SF Pro Text"
    readonly property string fontDisplay: "SF Pro Display"
    readonly property string fontMono:    "JetBrains Mono"

    function withAlpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }

    // ── Surface state tokens (interactive elements) ───────────────
    // On light themes, hover/pressed use darker (text-tinted) overlays so
    // states stand out on white surfaces; on dark themes lighter (surface)
    // overlays. Same semantic, inverted lightness.
    readonly property color surfaceIdle:    isLight
        ? withAlpha(text, 0.04) : withAlpha(surface0, 0.50)
    readonly property color surfaceHover:   isLight
        ? withAlpha(text, 0.08) : withAlpha(surface1, 0.75)
    readonly property color surfacePressed: isLight
        ? withAlpha(text, 0.14) : withAlpha(surface1, 0.95)
    readonly property color surfaceActive:  withAlpha(accent, isLight ? 0.14 : 0.20)
    readonly property color accentGlow:     withAlpha(accent, isLight ? 0.16 : 0.22)

    // ── Computed surface colours ──────────────────────────────────
    // Glass surface: white tint on dark, black tint on light. Keeps the
    // "translucent material" feel without inverting brand into something
    // murky on white wallpapers.
    //
    // Solid surface on light: tinted off-white with translucency rather
    // than mantle's pure #ffff at full alpha — pure white at 100% reads
    // as harsh on bright wallpapers; Apple's own UI is materials-tinted.
    readonly property color pillColor: isGlass
        ? (isLight ? Qt.rgba(0, 0, 0, 0.05) : Qt.rgba(1, 1, 1, 0.09))
        : (isLight
            ? Qt.rgba(base.r, base.g, base.b, 0.78)
            : Qt.rgba(mantle.r, mantle.g, mantle.b, 1.0))
    readonly property color pillBorderColor: isGlass
        ? (isLight ? Qt.rgba(0, 0, 0, 0.10) : Qt.rgba(1, 1, 1, 0.18))
        : Qt.rgba(text.r, text.g, text.b, isLight ? 0.10 : 0.12)

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
            _palette = _withOverrides(_staticPalette(themeId))
        }
    }

    // Merge paletteOverrides on top of `base`, returning a new object so
    // the bindings on _palette re-evaluate. Only known keys are accepted.
    function _withOverrides(base) {
        if (!paletteOverrides || typeof paletteOverrides !== "object") return base
        const out = {}
        const keys = Object.keys(_mochaPalette)
        for (let i = 0; i < keys.length; i++) {
            const k = keys[i]
            const ov = paletteOverrides[k]
            out[k] = (typeof ov === "string" && /^#[0-9a-fA-F]{3,8}$/.test(ov)) ? ov : base[k]
        }
        return out
    }

    onPaletteOverridesChanged: _applyTheme()

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
                    // Palette overrides
                    const ov = (d.theme && typeof d.theme.overrides === "object") ? d.theme.overrides : {}
                    if (JSON.stringify(ov) !== JSON.stringify(root.paletteOverrides)) {
                        root.paletteOverrides = ov
                    }
                    // Enabled bubble / page lists
                    const bub = (d.minibubbles && Array.isArray(d.minibubbles.enabled)) ? d.minibubbles.enabled : []
                    if (JSON.stringify(bub) !== JSON.stringify(root.enabledBubbles)) {
                        root.enabledBubbles = bub
                    }
                    const pg = (d.pages && Array.isArray(d.pages.enabled)) ? d.pages.enabled : []
                    if (JSON.stringify(pg) !== JSON.stringify(root.enabledPages)) {
                        root.enabledPages = pg
                    }
                    // Timings
                    if (d.minibubbles && d.minibubbles.timing) {
                        const t = d.minibubbles.timing
                        if (typeof t.showMs === "number" && t.showMs >= 0) root.bubbleShowMs = t.showMs
                        if (typeof t.hideMs === "number" && t.hideMs >= 0) root.bubbleHideMs = t.hideMs
                    }
                    if (d.pages && d.pages.animations) {
                        const a = d.pages.animations
                        if (typeof a.duration === "number" && a.duration >= 0) root.pageAnimDuration = a.duration
                    }
                    if (typeof d.reduceMotion === "boolean" && root.reduceMotion !== d.reduceMotion) {
                        root.reduceMotion = d.reduceMotion
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
                root._palette = root._withOverrides(merged ? merged : root._mochaPalette)
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
