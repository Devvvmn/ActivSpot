import QtQuick

QtObject {
    id: root

    readonly property var themes: [
        { id: "mocha",    label: "Mocha",    icon: "󰸌" },
        { id: "matugen",  label: "Matugen",  icon: "󰸉" },
        { id: "apple",    label: "Apple",    icon: "" },
        { id: "nord",     label: "Nord",     icon: "󰔎" },
        { id: "carbon",   label: "Carbon",   icon: "󰚩" },
        { id: "midnight", label: "Midnight", icon: "󰖔" },
    ]

    function themeLabel(id) {
        for (let t of themes) { if (t.id === id) return t.label }
        return id
    }
}
