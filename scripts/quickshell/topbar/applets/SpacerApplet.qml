import QtQuick

// Invisible gap between applet groups. Width can be tuned.
// In edit mode (Phase 2) this will render as a visible gap marker.
Item {
    id: root
    property var bar
    property bool editMode: false
    implicitWidth:  bar ? bar.s(4) : 4
    implicitHeight: bar ? bar.barHeight : 36
}
