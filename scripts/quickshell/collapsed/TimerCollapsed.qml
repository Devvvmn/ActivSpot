import QtQuick
import QtQuick.Layouts

Row {
    property var island
    property int preferredWidth: island.s(220)
    spacing: island.s(10)
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined

    // Timer slot
    Row {
        spacing: island.s(5)
        anchors.verticalCenter: parent.verticalCenter
        opacity: island.timerRunning || island.timerRemainingSec > 0 ? 1.0 : 0.45
        Behavior on opacity { NumberAnimation { duration: 200 } }

        Text {
            text: "󰔛"
            font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(15)
            color: island.mauve
            anchors.verticalCenter: parent.verticalCenter
        }
        Column {
            spacing: -1; anchors.verticalCenter: parent.verticalCenter
            Text {
                text: island.fmtChrono(island.timerRemainingSec > 0 ? island.timerRemainingSec : island.timerPresetSec)
                font.family: "JetBrains Mono"; font.pixelSize: island.s(14); font.weight: Font.Black
                color: island.timerRunning ? island.mauve : island.text
                Behavior on color { ColorAnimation { duration: 200 } }
            }
            Text {
                text: island.timerRunning ? "running" : "timer"
                font.family: "JetBrains Mono"; font.pixelSize: island.s(9)
                color: island.subtext0
            }
        }
    }

    Rectangle {
        width: 1; height: island.s(16); anchors.verticalCenter: parent.verticalCenter
        color: Qt.rgba(island.text.r, island.text.g, island.text.b, 0.10)
    }

    // Stopwatch slot
    Row {
        spacing: island.s(5)
        anchors.verticalCenter: parent.verticalCenter
        opacity: island.stopwatchRunning || island.stopwatchElapsedSec > 0 ? 1.0 : 0.45
        Behavior on opacity { NumberAnimation { duration: 200 } }

        Text {
            text: "󱎫"
            font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(15)
            color: island.blue
            anchors.verticalCenter: parent.verticalCenter
        }
        Column {
            spacing: -1; anchors.verticalCenter: parent.verticalCenter
            Text {
                text: island.fmtChrono(island.stopwatchElapsedSec)
                font.family: "JetBrains Mono"; font.pixelSize: island.s(14); font.weight: Font.Black
                color: island.stopwatchRunning ? island.blue : island.text
                Behavior on color { ColorAnimation { duration: 200 } }
            }
            Text {
                text: island.stopwatchRunning ? "running" : "stopwatch"
                font.family: "JetBrains Mono"; font.pixelSize: island.s(9)
                color: island.subtext0
            }
        }
    }
}
