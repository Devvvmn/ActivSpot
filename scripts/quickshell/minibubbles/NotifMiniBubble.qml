import QtQuick

BaseBubble {
    id: root

    bubbleId: "notif"
    onTapped: island.currentPage = "notifs"

    readonly property bool shouldShow: island.notifBadgeVisible && !island.expanded

    property int sz: island.s(36)
    height: sz
    width: sz

    opacity: shouldShow ? 1.0 : 0.0
    visible: opacity > 0.001
    scale:   shouldShow ? 1.0 : 0.05
    transformOrigin: Item.Left

    Behavior on opacity { NumberAnimation { duration: island.expanded ? 0 : 360; easing.type: Easing.OutCubic } }
    Behavior on scale   { SpringAnimation { spring: 5.5; damping: 0.7 } }

    Rectangle {
        anchors.fill: parent
        radius: parent.width / 2
        color: Qt.rgba(island.base.r, island.base.g, island.base.b, 0.94)
        border.width: 1.5

        SequentialAnimation on border.color {
            running: root.shouldShow; loops: Animation.Infinite
            ColorAnimation { to: Qt.rgba(island.peach.r, island.peach.g, island.peach.b, 0.65); duration: 1100; easing.type: Easing.InOutSine }
            ColorAnimation { to: Qt.rgba(island.peach.r, island.peach.g, island.peach.b, 0.25); duration: 1100; easing.type: Easing.InOutSine }
        }

        Text {
            anchors.centerIn: parent
            text: island.notifHistory.count > 9 ? "9+"
                : (island.notifHistory.count > 1 ? island.notifHistory.count.toString() : "󰂚")
            font.family:    island.notifHistory.count > 1 ? "JetBrains Mono" : "Iosevka Nerd Font"
            font.weight:    island.notifHistory.count > 1 ? Font.Black : Font.Normal
            font.pixelSize: island.notifHistory.count > 1 ? root.sz * 0.40 : root.sz * 0.48
            color: island.peach
        }
    }
}
