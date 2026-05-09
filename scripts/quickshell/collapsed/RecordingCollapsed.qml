import QtQuick
import "../pet"

Row {
    property var island
    property int preferredWidth: island.s(270)
    spacing: island.s(14)

    // Pulsing dot
    Rectangle {
        width: island.s(28); height: island.s(28); radius: island.s(14)
        color: Qt.rgba(island.red.r, island.red.g, island.red.b, 0.12)
        anchors.verticalCenter: parent.verticalCenter
        Rectangle {
            anchors.centerIn: parent
            width: island.s(14); height: island.s(14); radius: island.s(7)
            color: island.red
            opacity: island.recordingDotOpacity
            Behavior on opacity { NumberAnimation { duration: 80 } }
        }
    }

    // REC / PAUSED + timer
    Column {
        spacing: -1; anchors.verticalCenter: parent.verticalCenter
        Text {
            text: island.isRecordingPaused ? "PAUSED" : "REC"
            font.family: "JetBrains Mono"; font.pixelSize: island.s(13); font.weight: Font.Black
            font.letterSpacing: island.s(2)
            color: island.isRecordingPaused ? island.subtext0 : island.red
            Behavior on color { ColorAnimation { duration: 200 } }
        }
        Text {
            text: {
                let total = island.recordingSeconds
                let m  = Math.floor(total / 60)
                let s2 = total % 60
                return (m < 10 ? "0" + m : m) + ":" + (s2 < 10 ? "0" + s2 : s2)
            }
            font.family: "JetBrains Mono"; font.pixelSize: island.s(11); font.weight: Font.Bold
            color: island.isRecordingPaused
                ? Qt.rgba(island.subtext0.r, island.subtext0.g, island.subtext0.b, 0.45)
                : island.subtext0
            Behavior on color { ColorAnimation { duration: 200 } }
        }
    }

    // Pause + Stop
    Row {
        spacing: island.s(4); anchors.verticalCenter: parent.verticalCenter
        Rectangle {
            width: island.s(26); height: island.s(26); radius: island.s(13)
            color: pauseM.containsMouse ? Qt.rgba(island.surface1.r, island.surface1.g, island.surface1.b, 0.7) : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }
            Text {
                anchors.centerIn: parent
                text: island.isRecordingPaused ? "󰐊" : "󰏤"
                font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(13)
                color: island.isRecordingPaused ? island.green : island.subtext0
                Behavior on color { ColorAnimation { duration: 150 } }
            }
            MouseArea {
                id: pauseM; anchors.fill: parent; hoverEnabled: true
                onClicked: {
                    if (island.isRecordingPaused)
                        island.exec("bash ~/.config/hypr/scripts/screenshot.sh --resume")
                    else
                        island.exec("bash ~/.config/hypr/scripts/screenshot.sh --pause")
                    mouse.accepted = true
                }
            }
        }
        Rectangle {
            width: island.s(26); height: island.s(26); radius: island.s(13)
            color: stopM.containsMouse
                ? Qt.rgba(island.red.r, island.red.g, island.red.b, 0.28)
                : Qt.rgba(island.surface0.r, island.surface0.g, island.surface0.b, 0.5)
            Behavior on color { ColorAnimation { duration: 120 } }
            Text {
                anchors.centerIn: parent; text: "■"
                font.family: "JetBrains Mono"; font.pixelSize: island.s(10); font.weight: Font.Black
                color: island.red
            }
            MouseArea {
                id: stopM; anchors.fill: parent; hoverEnabled: true
                onClicked: { island.exec("bash ~/.config/hypr/scripts/screenshot.sh"); mouse.accepted = true }
            }
        }
    }

    CatPill {
        width: island.s(24); height: island.s(24); anchors.verticalCenter: parent.verticalCenter
        playing: island.musicData.status === "Playing"
        notifActive: island.notifActive || island.notifBadgeVisible
        showQuestion: false
        catColor: island.text; eyeColor: island.base; accentColor: island.mauve
    }
}
