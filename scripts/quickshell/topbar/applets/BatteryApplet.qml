import QtQuick
import Quickshell

Rectangle {
    id: root
    property var bar
    property bool editMode: false

    property bool isHovered: batMouse.containsMouse

    radius: bar.s(16)
    border.width: 1
    border.color: Qt.rgba(bar.text.r, bar.text.g, bar.text.b, 0.05)
    color: "transparent"

    implicitHeight: bar.barHeight
    implicitWidth:  bar.isDesktop ? bar.barHeight : (batRow.width + bar.s(24))
    clip: true

    Behavior on implicitWidth { NumberAnimation { duration: 500; easing.type: Easing.OutQuint } }

    // Gradient background — always visible (battery status drives color)
    Rectangle {
        anchors.fill: parent
        radius: bar.s(14)
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop {
                position: 0.0
                color: bar.isDesktop ? bar.red : bar.batDynamicColor
                Behavior on color { ColorAnimation { duration: 300 } }
            }
            GradientStop {
                position: 1.0
                color: bar.isDesktop
                    ? Qt.lighter(bar.red, 1.3)
                    : Qt.lighter(bar.batDynamicColor, 1.3)
                Behavior on color { ColorAnimation { duration: 300 } }
            }
        }
    }

    scale: isHovered ? 1.05 : 1.0
    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }

    Row {
        id: batRow
        anchors.centerIn: parent
        spacing: bar.s(8)
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: bar.isDesktop ? "" : bar.batIcon
            font.family: "Iosevka Nerd Font"
            font.pixelSize: bar.isDesktop ? bar.s(18) : bar.s(16)
            color: bar.base
            Behavior on color { ColorAnimation { duration: 300 } }
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: !bar.isDesktop
            text: bar.batPercent
            font.family: "JetBrains Mono"
            font.pixelSize: bar.s(13)
            font.weight: Font.Black
            color: bar.base
            Behavior on color { ColorAnimation { duration: 300 } }
        }
    }

    MouseArea {
        id: batMouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle battery"])
    }
}
