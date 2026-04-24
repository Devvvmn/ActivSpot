import QtQuick

BaseBubble {
    id: root

    bubbleId: "vpn"
    onTapped: island.vpnBadgeVisible = false

    readonly property bool shouldShow: island.vpnBadgeVisible && !island.expanded

    property int bubbleH: island.s(36)
    height: bubbleH
    width: bubbleRow.implicitWidth + island.s(28)

    opacity: shouldShow ? 1.0 : 0.0
    visible: opacity > 0.001
    scale:   shouldShow ? 1.0 : 0.05
    transformOrigin: Item.Right

    Behavior on opacity { NumberAnimation { duration: island.expanded ? 0 : 360; easing.type: Easing.OutCubic } }
    Behavior on scale   { SpringAnimation { spring: 5.5; damping: 0.7 } }

    Rectangle {
        anchors.fill: parent
        radius: parent.height / 2
        color: Qt.rgba(island.base.r, island.base.g, island.base.b, 0.94)
        border.width: 1.5
        border.color: island.vpnBadgeConnect
            ? Qt.rgba(island.green.r, island.green.g, island.green.b, 0.65)
            : Qt.rgba(island.red.r,   island.red.g,   island.red.b,   0.65)
        Behavior on border.color { ColorAnimation { duration: 250 } }
    }

    Row {
        id: bubbleRow
        anchors.centerIn: parent
        spacing: island.s(6)

        Text {
            text: island.vpnBadgeConnect ? "󰒃" : "󰒄"
            font.family: "Iosevka Nerd Font"
            font.pixelSize: root.bubbleH * 0.42
            color: island.vpnBadgeConnect ? island.green : island.red
            anchors.verticalCenter: parent.verticalCenter
            Behavior on color { ColorAnimation { duration: 250 } }
        }

        Text {
            text: island.vpnInterface || "VPN"
            font.family: "JetBrains Mono"
            font.pixelSize: root.bubbleH * 0.35
            font.weight: Font.Bold
            color: island.vpnBadgeConnect ? island.green : island.red
            anchors.verticalCenter: parent.verticalCenter
            Behavior on color { ColorAnimation { duration: 250 } }
        }
    }
}
