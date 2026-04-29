import QtQuick
import Quickshell

Rectangle {
    id: root
    property var bar
    property bool editMode: false

    property bool isHovered: batMouse.containsMouse

    radius: bar.s(16)
    border.width: 1
    border.color: bar.pillBorderColor
    color: bar.pillColor
    Behavior on color        { ColorAnimation { duration: 520; easing.type: Easing.InOutCubic } }
    Behavior on border.color { ColorAnimation { duration: 520; easing.type: Easing.InOutCubic } }

    implicitHeight: bar.barHeight - bar.s(10)
    implicitWidth:  bar.isDesktop ? bar.barHeight : (batRow.width + bar.s(24))
    clip: true

    Behavior on implicitWidth { NumberAnimation { duration: 500; easing.type: Easing.OutQuint } }

    scale: isHovered ? 1.05 : 1.0
    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }

    Row {
        id: batRow
        anchors.centerIn: parent
        spacing: bar.s(8)
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: bar.isDesktop ? "\uf011" : bar.batIcon
            font.family: "Iosevka Nerd Font"
            font.pixelSize: bar.isDesktop ? bar.s(18) : bar.s(16)
            color: bar.text
            Behavior on color { ColorAnimation { duration: 300 } }
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: !bar.isDesktop
            text: bar.batPercent
            font.family: "JetBrains Mono"
            font.pixelSize: bar.s(13)
            font.weight: Font.Black
            color: bar.text
            Behavior on color { ColorAnimation { duration: 300 } }
        }
    }

    MouseArea {
        id: batMouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: !root.editMode
        onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle battery"])
    }
}
