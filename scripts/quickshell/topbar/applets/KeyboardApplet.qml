import QtQuick
import Quickshell

Rectangle {
    id: root
    property var bar
    property bool editMode: false

    property bool isHovered: kbMouse.containsMouse

    radius: bar.s(14)
    border.width: 0
    color: "transparent"

    implicitHeight: bar.barHeight
    implicitWidth:  kbRow.width + bar.s(24)
    clip: true

    Behavior on implicitWidth { NumberAnimation { duration: 240; easing.type: Easing.OutQuint } }
    Behavior on color         { ColorAnimation  { duration: 200 } }

    scale: kbMouse.pressed ? 0.95 : (isHovered ? 1.04 : 1.0)
    Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }

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
            font.weight: Font.DemiBold
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
