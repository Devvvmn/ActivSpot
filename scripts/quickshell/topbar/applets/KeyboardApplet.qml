import QtQuick
import Quickshell

Rectangle {
    id: root
    property var bar
    property bool editMode: false

    property bool isHovered: kbMouse.containsMouse

    radius: bar.s(14)
    border.width: 1
    border.color: Qt.rgba(bar.text.r, bar.text.g, bar.text.b, 0.05)
    color: isHovered
        ? Qt.rgba(bar.surface1.r, bar.surface1.g, bar.surface1.b, 0.9)
        : Qt.rgba(bar.base.r,     bar.base.g,     bar.base.b,     0.75)

    implicitHeight: bar.barHeight
    implicitWidth:  kbRow.width + bar.s(24)
    clip: true

    Behavior on implicitWidth { NumberAnimation { duration: 500; easing.type: Easing.OutQuint } }
    Behavior on color         { ColorAnimation  { duration: 200 } }

    scale: isHovered ? 1.05 : 1.0
    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }

    Row {
        id: kbRow
        anchors.centerIn: parent
        spacing: bar.s(8)
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "󰌌"
            font.family: "Iosevka Nerd Font"
            font.pixelSize: bar.s(16)
            color: root.isHovered ? bar.text : bar.overlay2
            Behavior on color { ColorAnimation { duration: 200 } }
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: bar.kbLayout
            font.family: "JetBrains Mono"
            font.pixelSize: bar.s(13)
            font.weight: Font.Black
            color: bar.text
        }
    }

    MouseArea {
        id: kbMouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: !root.editMode
        onClicked: Quickshell.execDetached(["hyprctl", "switchxkblayout", "main", "next"])
    }
}
