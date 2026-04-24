import QtQuick

BaseBubble {
    id: root

    bubbleId: "discord"
    onTapped: island.currentPage = "discord"

    readonly property bool shouldShow: island.discordInCall
        && island.currentPage !== "discord"
        && !island.expanded

    property int bubbleH: island.s(36)
    height: bubbleH
    width: bubbleRow.implicitWidth + island.s(24)

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
        SequentialAnimation on border.color {
            running: root.shouldShow; loops: Animation.Infinite
            ColorAnimation { to: Qt.rgba(island.green.r, island.green.g, island.green.b, 0.7);  duration: 900; easing.type: Easing.InOutSine }
            ColorAnimation { to: Qt.rgba(island.green.r, island.green.g, island.green.b, 0.25); duration: 900; easing.type: Easing.InOutSine }
        }
    }

    Row {
        id: bubbleRow
        anchors.centerIn: parent
        spacing: island.s(6)

        Text {
            text: "󰙯"
            font.family: "Iosevka Nerd Font"
            font.pixelSize: root.bubbleH * 0.44
            color: island.green
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: {
                let t = island.discordCallSeconds
                let m = Math.floor(t / 60), s2 = t % 60
                return (m < 10 ? "0"+m : m) + ":" + (s2 < 10 ? "0"+s2 : s2)
            }
            font.family: "JetBrains Mono"
            font.pixelSize: root.bubbleH * 0.36
            font.weight: Font.Bold
            color: island.green
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
