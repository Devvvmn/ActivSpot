import QtQuick
import QtQuick.Layouts
import "../themes"

Item {
    id: root
    property var island

    readonly property bool hasWeather: island.weatherTemp !== "--°"

    // Split "hh:mm" into chars so each digit can flip independently.
    readonly property string h0: (island.timeStr || "00:00").charAt(0)
    readonly property string h1: (island.timeStr || "00:00").charAt(1)
    readonly property string m0: (island.timeStr || "00:00").charAt(3)
    readonly property string m1: (island.timeStr || "00:00").charAt(4)
    readonly property string seconds: (island.timeStrSec || "00:00:00").substring(6, 8)

    // ── Animated weather background ──────────────────────────────────────
    WeatherScene {
        anchors.fill: parent
        island: root.island
        desc: root.island.weatherDesc
        timeStr: root.island.timeStr
    }

    Item {
        anchors.fill: parent
        anchors.margins: island.s(28)
        anchors.topMargin: island.s(28)
        anchors.bottomMargin: island.s(28)

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            Item { Layout.fillHeight: true; Layout.preferredHeight: 1 }

            // ── Hero time: HH : MM with flipping digits + breathing colon ──
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: island.s(2)

                FlipDigit { island: root.island; digit: root.h0; fontSize: island.s(72) }
                FlipDigit { island: root.island; digit: root.h1; fontSize: island.s(72) }

                Text {
                    text: ":"
                    font.family: Theme.fontDisplay
                    font.pixelSize: island.s(72)
                    font.weight: Font.Light
                    color: island.text
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: island.s(4)
                    Layout.rightMargin: island.s(4)
                    SequentialAnimation on opacity {
                        running: !Theme.reduceMotion
                        loops: Animation.Infinite
                        NumberAnimation { from: 1.0; to: 0.35; duration: 800; easing.type: Easing.InOutSine }
                        NumberAnimation { from: 0.35; to: 1.0; duration: 800; easing.type: Easing.InOutSine }
                    }
                }

                FlipDigit { island: root.island; digit: root.m0; fontSize: island.s(72) }
                FlipDigit { island: root.island; digit: root.m1; fontSize: island.s(72) }

                // Tiny seconds badge — tabular for stability
                Text {
                    text: root.seconds
                    font.family: Theme.fontMono
                    font.pixelSize: island.s(13)
                    font.weight: Font.Medium
                    color: island.subtext0
                    Layout.alignment: Qt.AlignBottom
                    Layout.bottomMargin: island.s(14)
                    Layout.leftMargin: island.s(6)
                }
            }

            // ── Date line ─────────────────────────────────────────────────
            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: island.s(2)
                text: island.dateStr
                font.family: Theme.fontUI
                font.pixelSize: island.s(14)
                font.weight: Font.Medium
                color: island.subtext0
            }

            // ── Divider ───────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: island.s(18)
                Layout.bottomMargin: island.s(18)
                height: 1
                color: Qt.rgba(island.text.r, island.text.g, island.text.b, 0.07)
            }

            // ── Weather hero row ──────────────────────────────────────────
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: island.s(18)
                visible: root.hasWeather

                Text {
                    id: weatherIcon
                    text: island.weatherIcon || "󰖔"
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: island.s(56)
                    color: island.mauve
                    SequentialAnimation on scale {
                        running: !Theme.reduceMotion && root.hasWeather
                        loops: Animation.Infinite
                        NumberAnimation { from: 1.0; to: 1.05; duration: 2400; easing.type: Easing.InOutSine }
                        NumberAnimation { from: 1.05; to: 1.0; duration: 2400; easing.type: Easing.InOutSine }
                    }
                }

                ColumnLayout {
                    spacing: island.s(4)

                    // Temperature — display-weight hero typography. Tabular
                    // figures so "21°" doesn't shimmy when value updates.
                    Text {
                        text: island.weatherTemp
                        font.family: Theme.fontDisplay
                        font.pixelSize: island.s(52)
                        font.weight: Font.Thin
                        color: island.text
                    }

                    Text {
                        text: island.weatherDesc || ""
                        font.family: Theme.fontUI
                        font.pixelSize: island.s(13)
                        font.weight: Font.Medium
                        color: island.subtext0
                        visible: text !== ""
                    }

                    // Hi/Lo as inline chips — more compact than stacked rows.
                    RowLayout {
                        spacing: island.s(8)
                        visible: island.weatherHi !== "" || island.weatherLo !== ""

                        Rectangle {
                            visible: island.weatherHi !== ""
                            Layout.preferredHeight: island.s(20)
                            Layout.preferredWidth:  hiLabel.implicitWidth + island.s(14)
                            radius: height / 2
                            color: Qt.rgba(island.peach.r, island.peach.g, island.peach.b, 0.18)
                            border.width: 1
                            border.color: Qt.rgba(island.peach.r, island.peach.g, island.peach.b, 0.30)
                            Text {
                                id: hiLabel
                                anchors.centerIn: parent
                                text: "↑ " + (island.weatherHi || "--°")
                                font.family: Theme.fontMono
                                font.pixelSize: island.s(11)
                                font.weight: Font.Bold
                                color: island.peach
                            }
                        }
                        Rectangle {
                            visible: island.weatherLo !== ""
                            Layout.preferredHeight: island.s(20)
                            Layout.preferredWidth:  loLabel.implicitWidth + island.s(14)
                            radius: height / 2
                            color: Qt.rgba(island.blue.r, island.blue.g, island.blue.b, 0.18)
                            border.width: 1
                            border.color: Qt.rgba(island.blue.r, island.blue.g, island.blue.b, 0.30)
                            Text {
                                id: loLabel
                                anchors.centerIn: parent
                                text: "↓ " + (island.weatherLo || "--°")
                                font.family: Theme.fontMono
                                font.pixelSize: island.s(11)
                                font.weight: Font.Bold
                                color: island.blue
                            }
                        }
                    }
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                visible: !root.hasWeather
                text: "No weather data"
                font.family: Theme.fontUI
                font.pixelSize: island.s(13)
                color: Qt.rgba(island.subtext0.r, island.subtext0.g, island.subtext0.b, 0.45)
            }

            // ── Weather detail grid ───────────────────────────────────────
            // Three glass tiles. Top: large mono value. Bottom: label.
            // Subtle accent stripe on top edge ties value colour to category.
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: island.s(18)
                spacing: island.s(10)
                visible: root.hasWeather && (island.weatherFeels !== "" || island.weatherHumidity !== "" || island.weatherWind !== "")

                Rectangle {
                    Layout.fillWidth: true
                    height: island.s(64)
                    radius: island.s(14)
                    color: Qt.rgba(island.surface0.r, island.surface0.g, island.surface0.b, 0.55)
                    border.width: 1
                    border.color: Qt.rgba(island.text.r, island.text.g, island.text.b, 0.06)
                    visible: island.weatherFeels !== ""

                    Rectangle {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: island.s(2)
                        color: Qt.rgba(island.mauve.r, island.mauve.g, island.mauve.b, 0.55)
                        radius: parent.radius
                    }
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: island.s(2)
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: island.weatherFeels
                            font.family: Theme.fontMono
                            font.pixelSize: island.s(22)
                            font.weight: Font.Bold
                            color: island.text
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "FEELS LIKE"
                            font.family: Theme.fontUI
                            font.pixelSize: island.s(9)
                            font.weight: Font.Medium
                            font.letterSpacing: island.s(0.6)
                            color: island.subtext0
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: island.s(64)
                    radius: island.s(14)
                    color: Qt.rgba(island.surface0.r, island.surface0.g, island.surface0.b, 0.55)
                    border.width: 1
                    border.color: Qt.rgba(island.text.r, island.text.g, island.text.b, 0.06)
                    visible: island.weatherHumidity !== ""

                    Rectangle {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: island.s(2)
                        color: Qt.rgba(island.blue.r, island.blue.g, island.blue.b, 0.55)
                        radius: parent.radius
                    }
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: island.s(2)
                        // Split value + unit so any ligature/fallback weirdness
                        // around "%" can't bind them as a single token.
                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: island.s(1)
                            Text {
                                text: (island.weatherHumidity || "").replace("%", "")
                                font.family: Theme.fontMono
                                font.pixelSize: island.s(22)
                                font.weight: Font.Bold
                                color: island.blue
                                Layout.alignment: Qt.AlignBaseline
                            }
                            Text {
                                text: "%"
                                font.family: Theme.fontUI
                                font.pixelSize: island.s(14)
                                font.weight: Font.Medium
                                color: Qt.rgba(island.blue.r, island.blue.g, island.blue.b, 0.75)
                                Layout.alignment: Qt.AlignBaseline
                                Layout.bottomMargin: island.s(2)
                            }
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "HUMIDITY"
                            font.family: Theme.fontUI
                            font.pixelSize: island.s(9)
                            font.weight: Font.Medium
                            font.letterSpacing: island.s(0.6)
                            color: island.subtext0
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: island.s(64)
                    radius: island.s(14)
                    color: Qt.rgba(island.surface0.r, island.surface0.g, island.surface0.b, 0.55)
                    border.width: 1
                    border.color: Qt.rgba(island.text.r, island.text.g, island.text.b, 0.06)
                    visible: island.weatherWind !== ""

                    Rectangle {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: island.s(2)
                        color: Qt.rgba(island.teal.r, island.teal.g, island.teal.b, 0.55)
                        radius: parent.radius
                    }
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: island.s(2)
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: island.weatherWind
                            font.family: Theme.fontMono
                            font.pixelSize: island.s(22)
                            font.weight: Font.Bold
                            color: island.teal
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "WIND"
                            font.family: Theme.fontUI
                            font.pixelSize: island.s(9)
                            font.weight: Font.Medium
                            font.letterSpacing: island.s(0.6)
                            color: island.subtext0
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true; Layout.preferredHeight: 1 }
        }
    }
}
