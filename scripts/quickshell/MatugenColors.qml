import QtQuick
import "./themes"

// Compatibility shim. All theme state lives in the Theme singleton; this
// type just mirrors Theme's palette so existing consumers (popups, lock,
// etc.) that instantiate `MatugenColors { id: _theme }` keep working
// without edits. New code should import "themes" and read Theme.* directly.
Item {
    readonly property color base: Theme.base
    readonly property color mantle: Theme.mantle
    readonly property color crust: Theme.crust
    readonly property color text: Theme.text
    readonly property color subtext0: Theme.subtext0
    readonly property color subtext1: Theme.subtext1
    readonly property color surface0: Theme.surface0
    readonly property color surface1: Theme.surface1
    readonly property color surface2: Theme.surface2
    readonly property color overlay0: Theme.overlay0
    readonly property color overlay1: Theme.overlay1
    readonly property color overlay2: Theme.overlay2
    readonly property color blue: Theme.blue
    readonly property color sapphire: Theme.sapphire
    readonly property color peach: Theme.peach
    readonly property color green: Theme.green
    readonly property color red: Theme.red
    readonly property color mauve: Theme.mauve
    readonly property color pink: Theme.pink
    readonly property color yellow: Theme.yellow
    readonly property color maroon: Theme.maroon
    readonly property color teal: Theme.teal
}
