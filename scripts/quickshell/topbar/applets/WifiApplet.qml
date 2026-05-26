import QtQuick
import QtQuick.Effects
import Quickshell

Rectangle {
    id: root
    property var bar
    property var barZone
    property bool editMode: false

    property bool isHovered: wifiMouse.containsMouse
    property bool isActive:  bar.showEthernet ? (bar.ethStatus === "Connected") : bar.isWifiOn

    color: "transparent"
    border.width: 0

    implicitHeight: bar.barHeight
    implicitWidth:  wifiRow.width + bar.s(16)
    clip: true

    Behavior on implicitWidth { NumberAnimation { duration: 240; easing.type: Easing.OutQuint } }

    scale: wifiMouse.pressed ? 0.95 : (isHovered ? 1.04 : 1.0)
    Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }

    Row {
        id: wifiRow
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
            text: bar.showEthernet ? "󰈀" : bar.wifiIcon
            font.family: "Iosevka Nerd Font"
            font.pixelSize: bar.s(16)
            color: root.isActive ? barZone.adaptiveText : barZone.adaptiveSubtext
            Behavior on color { ColorAnimation { duration: 250 } }
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: bar.showEthernet
                ? bar.ethStatus
                : (bar.isWifiOn ? (bar.wifiSsid !== "" ? bar.wifiSsid : "On") : "Off")
            visible: text !== ""
            font.family: "JetBrains Mono"
            font.pixelSize: bar.s(12)
            font.weight: Font.DemiBold
            color: root.isActive ? barZone.adaptiveText : barZone.adaptiveSubtext
            width: Math.min(implicitWidth, bar.s(90))
            elide: Text.ElideRight
            Behavior on color { ColorAnimation { duration: 250 } }
        }
    }

    MouseArea {
        id: wifiMouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: !root.editMode
        onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle network wifi"])
    }
}
