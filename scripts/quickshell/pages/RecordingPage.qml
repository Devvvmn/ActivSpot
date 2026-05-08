import QtQuick
import QtQuick.Layouts
import "../themes"

Item {
    property var island

    ColumnLayout {
        anchors.centerIn: parent
        spacing: island.s(18)

        // Concentric pulsing dot — dims when paused
        Item {
            Layout.alignment: Qt.AlignHCenter
            width: island.s(88); height: island.s(88)

            Rectangle {
                anchors.fill: parent; radius: width / 2
                color: Qt.rgba(island.red.r, island.red.g, island.red.b, 0.07)
                opacity: island.recordingDotOpacity
                Behavior on opacity { NumberAnimation { duration: 80 } }
            }
            Rectangle {
                anchors.centerIn: parent
                width: island.s(58); height: island.s(58); radius: width / 2
                color: Qt.rgba(island.red.r, island.red.g, island.red.b, 0.13)
                opacity: island.recordingDotOpacity
                Behavior on opacity { NumberAnimation { duration: 80 } }
            }
            Rectangle {
                anchors.centerIn: parent
                width: island.s(30); height: island.s(30); radius: width / 2
                color: island.isRecordingPaused ? island.subtext0 : island.red
                opacity: island.recordingDotOpacity
                Behavior on color   { ColorAnimation  { duration: 250 } }
                Behavior on opacity { NumberAnimation { duration: 80 } }
            }
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: island.s(5)

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: island.isRecordingPaused ? "PAUSED" : "RECORDING"
                font.family: "JetBrains Mono"
                font.pixelSize: island.s(13)
                font.weight: Font.Black
                font.letterSpacing: island.s(3)
                color: island.isRecordingPaused ? island.subtext0 : island.red
                Behavior on color { ColorAnimation { duration: 250 } }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: {
                    let total = island.recordingSeconds;
                    let h  = Math.floor(total / 3600);
                    let m  = Math.floor((total % 3600) / 60);
                    let s2 = total % 60;
                    if (h > 0)
                        return (h  < 10 ? "0" + h  : h)  + ":"
                             + (m  < 10 ? "0" + m  : m)  + ":"
                             + (s2 < 10 ? "0" + s2 : s2);
                    return (m  < 10 ? "0" + m  : m)  + ":"
                         + (s2 < 10 ? "0" + s2 : s2);
                }
                font.family: "JetBrains Mono"
                font.pixelSize: island.s(38)
                font.weight: Font.Black
                color: island.isRecordingPaused
                    ? Qt.rgba(island.text.r, island.text.g, island.text.b, 0.45)
                    : island.text
                Behavior on color { ColorAnimation { duration: 250 } }
            }
        }

        // Buttons row: Pause/Resume  +  Stop
        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: island.s(10)

            // Pause / Resume
            Rectangle {
                width: island.s(140); height: island.s(44); radius: island.s(22)
                color: pauseMouse.containsMouse
                    ? Qt.rgba(island.surface1.r, island.surface1.g, island.surface1.b, 0.85)
                    : Qt.rgba(island.surface0.r, island.surface0.g, island.surface0.b, 0.65)
                Behavior on color { ColorAnimation { duration: 150 } }
                border.color: Qt.rgba(island.surface2.r, island.surface2.g, island.surface2.b, 0.6)
                border.width: island.s(1.5)

                Row {
                    anchors.centerIn: parent; spacing: island.s(7)
                    Text {
                        text: island.isRecordingPaused ? "󰐊" : "󰏤"
                        font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(16)
                        color: island.isRecordingPaused ? island.green : island.text
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                    Text {
                        text: island.isRecordingPaused ? "Resume" : "Pause"
                        font.family: Theme.fontUI; font.pixelSize: island.s(13); font.weight: Font.Medium
                        color: island.isRecordingPaused ? island.green : island.text
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                }

                MouseArea {
                    id: pauseMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (island.isRecordingPaused)
                            island.exec("bash ~/.config/hypr/scripts/screenshot.sh --resume")
                        else
                            island.exec("bash ~/.config/hypr/scripts/screenshot.sh --pause")
                    }
                }
            }

            // Stop
            Rectangle {
                width: island.s(140); height: island.s(44); radius: island.s(22)
                color: stopMouse.containsMouse
                    ? Qt.rgba(island.red.r, island.red.g, island.red.b, 0.22)
                    : Qt.rgba(island.red.r, island.red.g, island.red.b, 0.10)
                Behavior on color { ColorAnimation { duration: 150 } }
                border.color: Qt.rgba(island.red.r, island.red.g, island.red.b, 0.55)
                border.width: island.s(1.5)

                Row {
                    anchors.centerIn: parent; spacing: island.s(7)
                    Text {
                        text: "■"
                        font.family: "JetBrains Mono"; font.pixelSize: island.s(13); font.weight: Font.Black
                        color: island.red; anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "Stop"
                        font.family: Theme.fontUI; font.pixelSize: island.s(13); font.weight: Font.Medium
                        color: island.red; anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: stopMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: island.exec("bash ~/.config/hypr/scripts/screenshot.sh")
                }
            }
        }
    }
}
