import QtQuick

BaseBubble {
    id: root

    bubbleId: "sw"
    onTapped: island.currentPage = "timer"

    readonly property bool shouldShow: (island.stopwatchRunning || island.stopwatchElapsedSec > 0)
        && island.currentPage !== "timer"
        && !island.expanded

    property int bubbleH: island.s(36)
    height: bubbleH
    width: row.implicitWidth + island.s(24)

    opacity: shouldShow ? 1.0 : 0.0
    visible: opacity > 0.001
    scale:   shouldShow ? 1.0 : 0.05
    transformOrigin: Item.Right

    Behavior on opacity { NumberAnimation { duration: island.expanded ? 0 : 360; easing.type: Easing.OutCubic } }
    Behavior on scale   { SpringAnimation { spring: 5.5; damping: 0.7 } }

    property real _pulse: 1.0
    SequentialAnimation on _pulse {
        running: island.stopwatchRunning
        loops: Animation.Infinite
        NumberAnimation { to: 0.25; duration: 700; easing.type: Easing.InOutSine }
        NumberAnimation { to: 1.0;  duration: 700; easing.type: Easing.InOutSine }
    }

    Rectangle {
        anchors.fill: parent
        radius: parent.height / 2
        color: island.glassTheme
            ? Qt.rgba(island.surface2.r, island.surface2.g, island.surface2.b, 0.45)
            : Qt.rgba(island.base.r, island.base.g, island.base.b, 0.94)
        border.width: island.stopwatchRunning ? 1.5 : 1
        border.color: island.stopwatchRunning
            ? Qt.rgba(island.blue.r, island.blue.g, island.blue.b, root._pulse * 0.85)
            : (island.glassTheme
                ? Qt.rgba(1, 1, 1, 0.18)
                : Qt.rgba(island.text.r, island.text.g, island.text.b, 0.08))
        Behavior on color        { ColorAnimation { duration: 520; easing.type: Easing.InOutCubic } }
        Behavior on border.color { ColorAnimation { duration: 80 } }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: island.s(5)

        Text {
            text: "󱎫"
            font.family: "Iosevka Nerd Font"
            font.pixelSize: root.bubbleH * 0.40
            color: island.stopwatchRunning ? island.blue : island.subtext0
            anchors.verticalCenter: parent.verticalCenter
            Behavior on color { ColorAnimation { duration: 200 } }
        }
        Text {
            text: island.fmtChrono(island.stopwatchElapsedSec)
            font.family: "JetBrains Mono"
            font.pixelSize: root.bubbleH * 0.34
            font.weight: Font.Bold
            color: island.stopwatchRunning ? island.text : island.subtext0
            anchors.verticalCenter: parent.verticalCenter
            Behavior on color { ColorAnimation { duration: 200 } }
        }
    }
}
