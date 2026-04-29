import QtQuick
import qs.Commons

// Compat NIcon: renders a Tabler / Material icon glyph.
// If `icon` is a single character it's used directly (already a codepoint).
// Otherwise it's looked up in IconsTabler (the Noctalia icon name table).
Text {
    id: root

    property string icon: ""
    property real   pointSize: Style.fontSizeL
    property bool   applyUiScale: true

    readonly property string _glyph: {
        if (!icon || icon.length === 0) return ""
        // Already a glyph (single codepoint, possibly multi-code-unit in JS)
        if ([...icon].length === 1) return icon
        // Resolve alias first, then look up in icons table
        let resolved = IconsTabler.aliases[icon] ?? icon
        return IconsTabler.icons[resolved]
            ?? IconsTabler.icons[icon]
            ?? IconsTabler.icons[IconsTabler.defaultIcon]
            ?? "?"
    }

    text: _glyph
    font.family: "tabler-icons"
    font.pointSize: root.pointSize
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
}
