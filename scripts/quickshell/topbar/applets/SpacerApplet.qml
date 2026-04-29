import QtQuick

// Separator slot. Splits applet groups for right-zone group frames.
// In edit mode renders as a thin vertical line; otherwise invisible.
// Multiple instances are supported via unique IDs ("spacer", "spacer-<n>").
Item {
    id: root
    property var bar
    property bool editMode: false

    implicitWidth:  bar ? bar.s(editMode ? 22 : 16) : (editMode ? 24 : 18)
    implicitHeight: bar ? bar.barHeight : 36

    Behavior on implicitWidth { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: 2
        height: parent.height * 0.5
        radius: 1
        color: bar ? Qt.rgba(bar.mauve.r, bar.mauve.g, bar.mauve.b, 0.55)
                   : Qt.rgba(1, 1, 1, 0.4)
        opacity: root.editMode ? 1 : 0
        visible: opacity > 0.001
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    }
}
