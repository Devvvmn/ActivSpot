import QtQuick
import Quickshell

Rectangle {
    id: root
    property var bar
    property bool editMode: false

    property bool isHovered: btMouse.containsMouse

    radius: bar.s(14)
    border.width: 0
    color: "transparent"

    // Hidden on desktop (no BT indicator needed)
    property real targetW: bar.isDesktop ? 0 : (btRow.width + bar.s(24))
    implicitWidth:  targetW
    implicitHeight: bar.barHeight
    visible: targetW > 0
    clip: true

    Behavior on targetW   { NumberAnimation { duration: 500; easing.type: Easing.OutQuint } }
    Behavior on color     { ColorAnimation  { duration: 200 } }

    Rectangle {
        anchors.fill: parent
        radius: bar.s(14)
        opacity: bar.isBtOn ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 300 } }
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: bar.mauve }
            GradientStop { position: 1.0; color: Qt.lighter(bar.mauve, 1.3) }
        }
    }

    scale: isHovered ? 1.05 : 1.0
    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }

    Row {
        id: btRow
        anchors.centerIn: parent
        spacing: bar.s(8)
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: bar.btIcon
            font.family: "Iosevka Nerd Font"
            font.pixelSize: bar.s(16)
            color: bar.isBtOn ? bar.base : bar.subtext0
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: bar.btDevice
            visible: text !== ""
            font.family: "JetBrains Mono"
            font.pixelSize: bar.s(13)
            font.weight: Font.Black
            color: bar.isBtOn ? bar.base : bar.text
            width: Math.min(implicitWidth, bar.s(100))
            elide: Text.ElideRight
        }
    }

    MouseArea {
        id: btMouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: !root.editMode
        onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle network bt"])
    }
}
