import QtQuick
import QtQuick.Layouts

Row {
    property var island
    property int preferredWidth: island.s(250)
    spacing: island.s(12)

    ColumnLayout {
        spacing: -1; anchors.verticalCenter: parent.verticalCenter
        Text {
            text: island.timeStr
            font.family: "JetBrains Mono"; font.pixelSize: island.s(15); font.weight: Font.Black
            font.letterSpacing: -0.3
            color: island.text
        }
        Text { text: island.dateStr; font.family: "JetBrains Mono"; font.pixelSize: island.s(10); font.weight: Font.Medium; color: island.subtext0 }
    }

    // Vertical hairline divider
    Rectangle {
        width: 1; height: island.s(16); anchors.verticalCenter: parent.verticalCenter
        color: Qt.rgba(island.text.r, island.text.g, island.text.b, 0.10)
    }

    // Weather row — centered to the parent Row's vertical axis
    Row {
        spacing: island.s(6); anchors.verticalCenter: parent.verticalCenter
        Text {
            text: island.weatherIcon; visible: island.weatherIcon !== ""
            font.family: "JetBrains Mono"; font.pixelSize: island.s(18)
            color: island.mauve
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: island.weatherTemp; visible: island.weatherTemp !== "--°"
            font.family: "JetBrains Mono"; font.pixelSize: island.s(13); font.weight: Font.Black
            color: island.peach
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
