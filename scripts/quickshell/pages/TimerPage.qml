import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property var island

    Item {
        anchors.fill: parent
        anchors.margins: island.s(24)
        anchors.bottomMargin: island.s(72)

        ColumnLayout {
            anchors.fill: parent
            spacing: island.s(12)

            Text {
                text: "Timer & Stopwatch"
                font.family: "JetBrains Mono"
                font.pixelSize: island.s(16)
                font.weight: Font.Black
                color: island.text
                Layout.alignment: Qt.AlignHCenter
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: island.s(12)

                // Timer card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: island.s(188)
                    radius: island.s(14)
                    color: Qt.rgba(island.surface0.r, island.surface0.g, island.surface0.b, 0.55)
                    border.width: 1
                    border.color: Qt.rgba(island.mauve.r, island.mauve.g, island.mauve.b, 0.3)

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: island.s(12)
                        spacing: island.s(8)

                        Text {
                            text: "󰔛  Timer"
                            font.family: "Iosevka Nerd Font"
                            font.pixelSize: island.s(14)
                            color: island.mauve
                        }
                        Text {
                            text: island.fmtChrono(island.timerRemainingSec > 0 ? island.timerRemainingSec : island.timerPresetSec)
                            font.family: "JetBrains Mono"
                            font.pixelSize: island.s(30)
                            font.weight: Font.Black
                            color: island.text
                            Layout.alignment: Qt.AlignHCenter
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: island.s(8)

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: island.s(32)
                                radius: island.s(10)
                                color: island.timerRunning
                                    ? Qt.rgba(island.red.r, island.red.g, island.red.b, 0.82)
                                    : Qt.rgba(island.mauve.r, island.mauve.g, island.mauve.b, 0.82)
                                Text {
                                    anchors.centerIn: parent
                                    text: island.timerRunning ? "Pause" : "Start"
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: island.s(11)
                                    font.weight: Font.Black
                                    color: island.base
                                }
                                MouseArea { anchors.fill: parent; onClicked: island.toggleTimer() }
                            }
                            Rectangle {
                                Layout.preferredWidth: island.s(70)
                                Layout.preferredHeight: island.s(32)
                                radius: island.s(10)
                                color: Qt.rgba(island.surface1.r, island.surface1.g, island.surface1.b, 0.85)
                                border.width: 1
                                border.color: Qt.rgba(island.text.r, island.text.g, island.text.b, 0.16)
                                Text {
                                    anchors.centerIn: parent
                                    text: "Reset"
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: island.s(11)
                                    font.weight: Font.Black
                                    color: island.text
                                }
                                MouseArea { anchors.fill: parent; onClicked: island.resetTimer() }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: island.s(6)
                            Repeater {
                                model: [300, 600, 900, 1500]
                                Rectangle {
                                    required property int modelData
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: island.s(26)
                                    radius: island.s(8)
                                    color: Qt.rgba(island.surface1.r, island.surface1.g, island.surface1.b, 0.7)
                                    border.width: 1
                                    border.color: Qt.rgba(island.text.r, island.text.g, island.text.b, 0.14)
                                    Text {
                                        anchors.centerIn: parent
                                        text: Math.round(modelData / 60) + "m"
                                        font.family: "JetBrains Mono"
                                        font.pixelSize: island.s(10)
                                        font.weight: Font.Bold
                                        color: island.subtext0
                                    }
                                    MouseArea { anchors.fill: parent; onClicked: island.startTimer(modelData) }
                                }
                            }
                        }
                    }
                }

                // Stopwatch card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: island.s(188)
                    radius: island.s(14)
                    color: Qt.rgba(island.surface0.r, island.surface0.g, island.surface0.b, 0.55)
                    border.width: 1
                    border.color: Qt.rgba(island.blue.r, island.blue.g, island.blue.b, 0.3)

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: island.s(12)
                        spacing: island.s(8)

                        Text {
                            text: "󱎫  Stopwatch"
                            font.family: "Iosevka Nerd Font"
                            font.pixelSize: island.s(14)
                            color: island.blue
                        }
                        Text {
                            text: island.fmtChrono(island.stopwatchElapsedSec)
                            font.family: "JetBrains Mono"
                            font.pixelSize: island.s(30)
                            font.weight: Font.Black
                            color: island.text
                            Layout.alignment: Qt.AlignHCenter
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: island.s(8)
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: island.s(32)
                                radius: island.s(10)
                                color: island.stopwatchRunning
                                    ? Qt.rgba(island.red.r, island.red.g, island.red.b, 0.82)
                                    : Qt.rgba(island.blue.r, island.blue.g, island.blue.b, 0.82)
                                Text {
                                    anchors.centerIn: parent
                                    text: island.stopwatchRunning ? "Pause" : "Start"
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: island.s(11)
                                    font.weight: Font.Black
                                    color: island.base
                                }
                                MouseArea { anchors.fill: parent; onClicked: island.toggleStopwatch() }
                            }
                            Rectangle {
                                Layout.preferredWidth: island.s(70)
                                Layout.preferredHeight: island.s(32)
                                radius: island.s(10)
                                color: Qt.rgba(island.surface1.r, island.surface1.g, island.surface1.b, 0.85)
                                border.width: 1
                                border.color: Qt.rgba(island.text.r, island.text.g, island.text.b, 0.16)
                                Text {
                                    anchors.centerIn: parent
                                    text: "Reset"
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: island.s(11)
                                    font.weight: Font.Black
                                    color: island.text
                                }
                                MouseArea { anchors.fill: parent; onClicked: island.resetStopwatch() }
                            }
                        }
                    }
                }
            }
        }
    }
}
