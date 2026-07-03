import QtQuick
import QtQuick.Layouts
import "../themes"

Item {
    id: root
    property var island

    Item {
        anchors.fill: parent
        anchors.margins: island.s(24)
        anchors.bottomMargin: island.s(72)

        ColumnLayout {
            anchors.fill: parent
            spacing: island.s(16)

            // ── Timer (primary) ──────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                spacing: island.s(10)

                Text {
                    text: island.fmtChrono(island.timerRemainingSec > 0 ? island.timerRemainingSec : island.timerPresetSec)
                    font.family: "JetBrains Mono"
                    font.pixelSize: island.s(44)
                    font.weight: Font.Black
                    color: (island.timerRunning && island.timerRemainingSec > 0 && island.timerRemainingSec <= 10)
                        ? island.red : island.text
                    Layout.alignment: Qt.AlignHCenter
                    Behavior on color { ColorAnimation { duration: 180 } }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: island.s(8)

                    // Start / Pause
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: island.s(34)
                        radius: island.s(10)
                        color: startMouse.containsMouse
                            ? Qt.rgba(island.surface1.r, island.surface1.g, island.surface1.b, 0.90)
                            : Qt.rgba(island.surface0.r, island.surface0.g, island.surface0.b, 0.70)
                        border.width: 1
                        border.color: island.timerRunning
                            ? Qt.rgba(island.red.r,   island.red.g,   island.red.b,   0.35)
                            : Qt.rgba(island.mauve.r, island.mauve.g, island.mauve.b, 0.35)
                        Behavior on color        { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 180 } }
                        Text {
                            anchors.centerIn: parent
                            text: island.timerRunning ? "Pause" : "Start"
                            font.family: Theme.fontUI
                            font.pixelSize: island.s(12)
                            font.weight: Font.DemiBold
                            color: island.timerRunning ? island.red : island.mauve
                            Behavior on color { ColorAnimation { duration: 180 } }
                        }
                        MouseArea {
                            id: startMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: island.toggleTimer()
                        }
                    }

                    // Reset
                    Rectangle {
                        Layout.preferredWidth: island.s(70)
                        Layout.preferredHeight: island.s(34)
                        radius: island.s(10)
                        color: resetMouse.containsMouse
                            ? Qt.rgba(island.surface2.r, island.surface2.g, island.surface2.b, 0.85)
                            : Qt.rgba(island.surface1.r, island.surface1.g, island.surface1.b, 0.85)
                        border.width: 1
                        border.color: Qt.rgba(island.text.r, island.text.g, island.text.b, 0.10)
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Text {
                            anchors.centerIn: parent
                            text: "Reset"
                            font.family: Theme.fontUI
                            font.pixelSize: island.s(12)
                            font.weight: Font.Medium
                            color: island.subtext0
                        }
                        MouseArea {
                            id: resetMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: island.resetTimer()
                        }
                    }
                }

                // Preset chips
                RowLayout {
                    Layout.fillWidth: true
                    spacing: island.s(6)
                    Repeater {
                        model: [300, 600, 900, 1500]
                        Item {
                            required property int modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: island.s(26)

                            readonly property bool isSelected:
                                island.timerPresetSec === modelData &&
                                !island.timerRunning   &&
                                island.timerRemainingSec === 0

                            Rectangle {
                                anchors.fill: parent
                                radius: island.s(8)
                                color: chipMouse.containsMouse
                                    ? Qt.rgba(island.surface2.r, island.surface2.g, island.surface2.b, 0.85)
                                    : parent.isSelected
                                        ? Qt.rgba(island.mauve.r, island.mauve.g, island.mauve.b, 0.12)
                                        : Qt.rgba(island.surface1.r, island.surface1.g, island.surface1.b, 0.70)
                                border.width: 1
                                border.color: parent.isSelected
                                    ? Qt.rgba(island.mauve.r, island.mauve.g, island.mauve.b, 0.28)
                                    : Qt.rgba(island.text.r,  island.text.g,  island.text.b,  0.10)
                                Behavior on color        { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }
                                Text {
                                    anchors.centerIn: parent
                                    text: Math.round(parent.parent.modelData / 60) + "m"
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: island.s(10)
                                    font.weight: Font.Bold
                                    color: parent.parent.isSelected ? island.mauve : island.subtext0
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                                MouseArea {
                                    id: chipMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: island.startTimer(parent.parent.modelData)
                                }
                            }
                        }
                    }
                }
            }

            // ── Divider ──────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(island.text.r, island.text.g, island.text.b, 0.08)
            }

            // ── Stopwatch (secondary) ─────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: island.s(10)

                Text {
                    text: "󱎫"
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: island.s(13)
                    color: island.subtext0
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    text: "Stopwatch"
                    font.family: Theme.fontUI
                    font.pixelSize: island.s(11)
                    color: island.subtext0
                    verticalAlignment: Text.AlignVCenter
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: island.fmtChrono(island.stopwatchElapsedSec)
                    font.family: "JetBrains Mono"
                    font.pixelSize: island.s(20)
                    font.weight: Font.Black
                    color: island.stopwatchRunning ? island.text : island.subtext0
                    verticalAlignment: Text.AlignVCenter
                    Behavior on color { ColorAnimation { duration: 180 } }
                }

                // Stopwatch Start / Pause
                Rectangle {
                    implicitWidth: island.s(60)
                    implicitHeight: island.s(28)
                    radius: island.s(8)
                    color: swStartMouse.containsMouse
                        ? Qt.rgba(island.surface2.r, island.surface2.g, island.surface2.b, 0.85)
                        : Qt.rgba(island.surface1.r, island.surface1.g, island.surface1.b, 0.85)
                    border.width: 1
                    border.color: island.stopwatchRunning
                        ? Qt.rgba(island.red.r,  island.red.g,  island.red.b,  0.28)
                        : Qt.rgba(island.blue.r, island.blue.g, island.blue.b, 0.28)
                    Behavior on color        { ColorAnimation { duration: 120 } }
                    Behavior on border.color { ColorAnimation { duration: 180 } }
                    Text {
                        anchors.centerIn: parent
                        text: island.stopwatchRunning ? "Pause" : "Start"
                        font.family: Theme.fontUI
                        font.pixelSize: island.s(11)
                        font.weight: Font.Medium
                        color: island.stopwatchRunning ? island.red : island.blue
                        Behavior on color { ColorAnimation { duration: 180 } }
                    }
                    MouseArea {
                        id: swStartMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: island.toggleStopwatch()
                    }
                }

                // Stopwatch Reset
                Rectangle {
                    implicitWidth: island.s(52)
                    implicitHeight: island.s(28)
                    radius: island.s(8)
                    color: swResetMouse.containsMouse
                        ? Qt.rgba(island.surface2.r, island.surface2.g, island.surface2.b, 0.85)
                        : Qt.rgba(island.surface1.r, island.surface1.g, island.surface1.b, 0.85)
                    border.width: 1
                    border.color: Qt.rgba(island.text.r, island.text.g, island.text.b, 0.10)
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Text {
                        anchors.centerIn: parent
                        text: "Reset"
                        font.family: Theme.fontUI
                        font.pixelSize: island.s(11)
                        font.weight: Font.Medium
                        color: island.subtext0
                    }
                    MouseArea {
                        id: swResetMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: island.resetStopwatch()
                    }
                }
            }
        }
    }
}
