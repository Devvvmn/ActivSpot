import QtQuick

BaseBubble {
    id: root

    bubbleId: "rec"
    onTapped: island.currentPage = "recording"

    readonly property bool shouldShow: island.isRecording
        && island.currentPage !== "recording"
        && !island.expanded

    property int bubbleH: island.s(36)
    height: bubbleH
    width: bubbleRow.implicitWidth + island.s(24)

    opacity: shouldShow ? 1.0 : 0.0
    visible: opacity > 0.001
    scale:   shouldShow ? 1.0 : 0.05
    transformOrigin: Item.Left

    Behavior on opacity { NumberAnimation { duration: island.expanded ? 0 : 360; easing.type: Easing.OutCubic } }
    Behavior on scale   { SpringAnimation { spring: 5.5; damping: 0.7 } }

    Rectangle {
        anchors.fill: parent
        radius: parent.height / 2
        color: Qt.rgba(island.base.r, island.base.g, island.base.b, 0.94)
        border.width: 1.5
        border.color: Qt.rgba(island.red.r, island.red.g, island.red.b,
                              island.recordingDotOpacity * 0.85)
        Behavior on border.color { ColorAnimation { duration: 80 } }
    }

    Row {
        id: bubbleRow
        anchors.centerIn: parent
        spacing: island.s(6)

        Rectangle {
            width: island.s(10); height: island.s(10); radius: island.s(5)
            color: island.red
            opacity: island.isRecordingPaused ? 0.38 : island.recordingDotOpacity
            Behavior on opacity { NumberAnimation { duration: 80 } }
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: island.isRecordingPaused ? "PAUSED" : "REC"
            font.family: "JetBrains Mono"
            font.pixelSize: root.bubbleH * 0.34
            font.weight: Font.Black
            font.letterSpacing: island.s(1.5)
            color: island.isRecordingPaused ? island.subtext0 : island.red
            anchors.verticalCenter: parent.verticalCenter
            Behavior on color { ColorAnimation { duration: 200 } }
        }

        Text {
            text: {
                let t = island.recordingSeconds
                let m = Math.floor(t / 60), s2 = t % 60
                return (m < 10 ? "0"+m : m) + ":" + (s2 < 10 ? "0"+s2 : s2)
            }
            font.family: "JetBrains Mono"
            font.pixelSize: root.bubbleH * 0.32
            font.weight: Font.Bold
            color: island.subtext0
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
