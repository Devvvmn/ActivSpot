import QtQuick
import QtQuick.Effects
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
    implicitWidth:  kbRow.width + bar.s(16)
    clip: true

    Behavior on implicitWidth { NumberAnimation { duration: 240; easing.type: Easing.OutQuint } }

    scale: kbMouse.pressed ? 0.95 : (isHovered ? 1.04 : 1.0)
    Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }

    Row {
        id: kbRow
        anchors.centerIn: parent
        spacing: bar.s(6)

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.55)
            shadowBlur: 0.5
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 1
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "󰌌"
            font.family: "Iosevka Nerd Font"
            font.pixelSize: bar.s(16)
            color: root.isHovered ? bar.adaptiveText : bar.adaptiveSubtext
            Behavior on color { ColorAnimation { duration: 200 } }
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: bar.kbLayout
            font.family: "JetBrains Mono"
            font.pixelSize: bar.s(13)
            font.weight: Font.DemiBold
            color: bar.adaptiveText
            Behavior on color { ColorAnimation { duration: 200 } }
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
