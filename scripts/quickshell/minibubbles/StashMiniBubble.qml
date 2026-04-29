import QtQuick

BaseBubble {
    id: root

    bubbleId: "stash"
    onTapped: {
        island.currentPage = "stash"
        island.expanded = true
    }

    readonly property bool shouldShow: island.stashModel.count > 0
        && island.currentPage !== "stash"
        && !island.expanded

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
        color: island.glassTheme
            ? Qt.rgba(island.surface2.r, island.surface2.g, island.surface2.b, 0.45)
            : Qt.rgba(island.base.r, island.base.g, island.base.b, 0.94)
        Behavior on color { ColorAnimation { duration: 520; easing.type: Easing.InOutCubic } }
        border.width: 1.5
        border.color: Qt.rgba(island.mauve.r, island.mauve.g, island.mauve.b, 0.55)
    }

    Row {
        id: bubbleRow
        anchors.centerIn: parent
        spacing: island.s(6)

        Text {
            text: ""
            font.family: "Iosevka Nerd Font"
            font.pixelSize: root.bubbleH * 0.45
            color: island.mauve
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: island.stashModel.count.toString()
            font.family: "JetBrains Mono"
            font.pixelSize: root.bubbleH * 0.38
            font.weight: Font.Bold
            color: island.text
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
