import QtQuick
import QtQuick.Effects
import Quickshell

Rectangle {
    id: root
    property var bar
    property var barZone
    property bool editMode: false

    property bool isHovered: batMouse.containsMouse

    color: "transparent"
    border.width: 0

    implicitHeight: bar.barHeight
    implicitWidth:  batRow.width + bar.s(16)
    clip: true

    Behavior on implicitWidth { NumberAnimation { duration: 240; easing.type: Easing.OutQuint } }

    scale: batMouse.pressed ? 0.95 : (isHovered ? 1.04 : 1.0)
    Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }

    Row {
        id: batRow
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
            text: bar.batCap <= 20 && !bar.isCharging ? "󰂃" : bar.batIcon
            font.family: "Iosevka Nerd Font"
            font.pixelSize: bar.s(16)
            color: bar.batCap <= 20 && !bar.isCharging ? bar.red
                 : bar.isCharging ? bar.green
                 : barZone.adaptiveText
            Behavior on color { ColorAnimation { duration: 250 } }
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: !bar.isDesktop
            text: bar.batPercent
            font.family: "JetBrains Mono"
            font.pixelSize: bar.s(12)
            font.weight: Font.DemiBold
            color: barZone.adaptiveText
            Behavior on color { ColorAnimation { duration: 250 } }
        }
    }

    // Battery popup was removed (Control Center covers it) — the applet is a
    // passive indicator; click opens the island control page instead.
    MouseArea {
        id: batMouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: !root.editMode
        onClicked: Quickshell.execDetached(["bash", "-c", "echo page:control > /tmp/qs_island_toggle"])
    }
}
