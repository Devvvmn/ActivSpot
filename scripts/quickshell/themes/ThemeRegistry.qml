import QtQuick

QtObject {
    id: root

    readonly property var themes: [
        { id: "mocha",   label: "Mocha",   icon: "󰸌" },
        { id: "glass",   label: "Glass",   icon: "󰈈" },
        { id: "matugen", label: "Matugen", icon: "󰸉" },
        { id: "gruvbox", label: "Gruvbox", icon: "󱓻" },
        { id: "apple",   label: "Apple",   icon: "" },
        { id: "nord",    label: "Nord",    icon: "󰔎" },
    ]

    function themeLabel(id) {
        for (let t of themes) { if (t.id === id) return t.label }
        return id
    }
}
