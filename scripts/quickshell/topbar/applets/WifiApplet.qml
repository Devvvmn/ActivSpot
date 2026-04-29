import QtQuick
import Quickshell

Rectangle {
    id: root
    property var bar
    property bool editMode: false

    height: bar.barHeight - bar.s(8)
    implicitHeight: height

    property bool isHovered: wifiMouse.containsMouse
    property bool isActive:  bar.showEthernet ? (bar.ethStatus === "Connected") : bar.isWifiOn

    radius: bar.s(16)
    border.width: 0
    color: bar.pillColor

    implicitWidth:  wifiRow.width + bar.s(24)
    clip: true

    Behavior on implicitWidth { NumberAnimation { duration: 500; easing.type: Easing.OutQuint } }
    Behavior on color         { ColorAnimation  { duration: 200 } }

    Rectangle {
        anchors.fill: parent
        radius: bar.s(14)
        opacity: root.isActive ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 300 } }
        color: bar.glassTheme
            ? Qt.rgba(bar.mauve.r, bar.mauve.g, bar.mauve.b, 0.12)
            : bar.base
        Behavior on color { ColorAnimation { duration: 520; easing.type: Easing.InOutCubic } }
    }

    scale: isHovered ? 1.05 : 1.0
    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }

    Row {
        id: wifiRow
        anchors.centerIn: parent
        spacing: bar.s(8)
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: bar.showEthernet ? "󰈀" : bar.wifiIcon
            font.family: "Iosevka Nerd Font"
            font.pixelSize: bar.s(16)
            color: root.isActive ? bar.text : bar.subtext0
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: bar.showEthernet
                ? bar.ethStatus
                : (bar.isWifiOn ? (bar.wifiSsid !== "" ? bar.wifiSsid : "On") : "Off")
            visible: text !== ""
            font.family: "JetBrains Mono"
            font.pixelSize: bar.s(13)
            font.weight: Font.Black
            color: root.isActive ? bar.text : bar.text
            width: Math.min(implicitWidth, bar.s(100))
            elide: Text.ElideRight
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
