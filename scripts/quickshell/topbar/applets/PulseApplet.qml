import QtQuick
import QtQuick.Effects
import Quickshell

Rectangle {
    id: root
    property var bar
    property var barZone
    property bool editMode: false

    property bool isHovered: pulseMouse.containsMouse

    color: "transparent"
    border.width: 0

    implicitHeight: bar.barHeight
    implicitWidth:  pulseRow.width + bar.s(16)
    clip: true

    Behavior on implicitWidth { NumberAnimation { duration: 240; easing.type: Easing.OutQuint } }

    scale: pulseMouse.pressed ? 0.95 : (isHovered ? 1.04 : 1.0)
    Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }

    Row {
        id: pulseRow
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
            text: bar.pulseIcon || "󰏤"
            font.family: "Iosevka Nerd Font"
            font.pixelSize: bar.s(16)
            color: barZone.adaptiveText
            Behavior on color { ColorAnimation { duration: 250 } }
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: bar.pulseRate || "72"
            font.family: "JetBrains Mono"
            font.pixelSize: bar.s(12)
            font.weight: Font.DemiBold
            color: barZone.adaptiveText
            Behavior on color { ColorAnimation { duration: 250 } }
        }
    }

    MouseArea {
        id: pulseMouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: !root.editMode
        onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle pulse"])
    }
}
