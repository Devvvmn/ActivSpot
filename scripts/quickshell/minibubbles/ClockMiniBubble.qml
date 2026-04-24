import QtQuick

BaseBubble {
    id: root

    bubbleId: "clock"
    onTapped: island.currentPage = "clock"

    readonly property bool shouldShow: island.currentPage !== "clock"
        && !island.expanded

    property int bubbleH: island.s(36)
    height: bubbleH
    width: timeText.implicitWidth + island.s(28)

    opacity: shouldShow ? 1.0 : 0.0
    visible: opacity > 0.001
    scale:   shouldShow ? 1.0 : 0.5
    transformOrigin: Item.Left

    Behavior on opacity { NumberAnimation { duration: 360; easing.type: Easing.OutCubic } }
    Behavior on scale   { NumberAnimation { duration: 420; easing.type: Easing.OutBack  } }

    Rectangle {
        anchors.fill: parent
        radius: parent.height / 2
        color: Qt.rgba(island.base.r, island.base.g, island.base.b, 0.94)
        border.width: 1
        border.color: Qt.rgba(island.text.r, island.text.g, island.text.b, 0.08)
    }

    Text {
        id: timeText
        anchors.centerIn: parent
        text: island.timeStr
        font.family: "JetBrains Mono"
        font.pixelSize: root.bubbleH * 0.38
        font.weight: Font.Bold
        color: island.text
    }
}
