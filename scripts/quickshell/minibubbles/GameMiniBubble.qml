import QtQuick
import QtQuick.Effects
import "../themes"

BaseBubble {
    id: root

    bubbleId: "game"
    onTapped: island.currentPage = "game"

    readonly property bool shouldShow: island.gameActive
        && island.currentPage !== "game"
        && !island.expanded

    property int bubbleH: island.s(36)
    height: bubbleH
    width:  bubbleRow.implicitWidth + island.s(22)

    opacity: shouldShow ? 1.0 : 0.0
    visible: opacity > 0.001
    scale:   shouldShow ? 1.0 : 0.05
    transformOrigin: Item.Right

    Behavior on scale   { SpringAnimation { spring: 4.0; damping: 0.38 } }

    readonly property color fpsColor: {
        if (island.gameFps > 90) return island.green;
        if (island.gameFps > 45) return island.yellow;
        return island.red;
    }
    readonly property color pingColor: {
        if (island.gamePing < 30) return island.green;
        if (island.gamePing < 70) return island.yellow;
        return island.red;
    }

    // Glow ring
    Rectangle {
        anchors.centerIn: pillBg
        width: pillBg.width + island.s(8); height: pillBg.height + island.s(8)
        radius: height / 2
        color: "transparent"
        border.width: island.s(2)
        border.color: root.fpsColor
        opacity: 0.18
        Behavior on border.color { ColorAnimation { duration: 400 } }
        layer.enabled: true
        layer.effect: MultiEffect { blurEnabled: true; blurMax: 20; blur: 1.0 }
    }

    Rectangle {
        id: pillBg
        anchors.fill: parent
        radius: parent.height / 2
        color: island.glassTheme
            ? Qt.rgba(island.surface2.r, island.surface2.g, island.surface2.b, 0.45)
            : Qt.rgba(island.base.r, island.base.g, island.base.b, 0.94)
        border.width: 1
        border.color: island.glassTheme
            ? Qt.rgba(1, 1, 1, 0.18)
            : Qt.rgba(island.text.r, island.text.g, island.text.b, 0.06)
    }

    Row {
        id: bubbleRow
        anchors.centerIn: parent
        spacing: island.s(6)

        // Pulsing health dot
        Rectangle {
            width: island.s(6); height: island.s(6); radius: island.s(3)
            color: root.fpsColor
            anchors.verticalCenter: parent.verticalCenter
            Behavior on color { ColorAnimation { duration: 400 } }
        }

        // FPS
        Text {
            text: island.gameFps
            font.family: "JetBrains Mono"; font.pixelSize: island.s(13); font.weight: Font.Black
            color: root.fpsColor; anchors.verticalCenter: parent.verticalCenter
            Behavior on color { ColorAnimation { duration: 400 } }
        }
        Text {
            text: "fps"
            font.family: "JetBrains Mono"; font.pixelSize: island.s(8)
            color: Theme.overlay0; anchors.verticalCenter: parent.verticalCenter
        }

        // Divider
        Rectangle {
            width: 1; height: island.s(12)
            color: Qt.rgba(island.text.r, island.text.g, island.text.b, 0.12)
            anchors.verticalCenter: parent.verticalCenter
        }

        // Ping
        Text {
            text: island.gamePing
            font.family: "JetBrains Mono"; font.pixelSize: island.s(12); font.weight: Font.Black
            color: root.pingColor; anchors.verticalCenter: parent.verticalCenter
            Behavior on color { ColorAnimation { duration: 400 } }
        }
        Text {
            text: "ms"
            font.family: "JetBrains Mono"; font.pixelSize: island.s(8)
            color: Theme.overlay0; anchors.verticalCenter: parent.verticalCenter
        }
    }
}
