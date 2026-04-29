import QtQuick

// Visual separator slot — a thin vertical line rendered inside the group frame.
// Unlike SpacerApplet, this does NOT split applet groups; it lives inside one.
// Multi-instance via unique IDs ("separator-<n>").
Item {
    id: root
    property var bar
    property bool editMode: false

    implicitWidth:  bar ? bar.s(10) : 12
    implicitHeight: bar ? bar.barHeight : 36

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: 1
        height: parent.height * 0.45
        radius: 1
        color: bar ? Qt.rgba(bar.text.r, bar.text.g, bar.text.b, 0.25)
                   : Qt.rgba(1, 1, 1, 0.25)
    }
}
