import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property var island

    Item {
        anchors.fill: parent
        anchors.margins: island.s(28)
        anchors.bottomMargin: island.s(68)

        ColumnLayout {
            anchors.centerIn: parent
            width: parent.width
            spacing: island.s(10)

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: island.timeStrSec
                font.family: "JetBrains Mono"; font.pixelSize: island.s(52); font.weight: Font.Black
                font.letterSpacing: -1
                color: island.text
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: island.dateStr
                font.family: "JetBrains Mono"; font.pixelSize: island.s(14); font.weight: Font.Medium
                color: island.subtext0
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: island.s(6); Layout.bottomMargin: island.s(2)
                height: 1
                color: Qt.rgba(island.text.r, island.text.g, island.text.b, 0.08)
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: island.s(16)

                Text {
                    text: island.weatherIcon || "󰖔"
                    font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(32)
                    color: island.mauve
                }
                ColumnLayout {
                    spacing: island.s(2)
                    Text {
                        text: island.weatherTemp
                        font.family: "JetBrains Mono"; font.pixelSize: island.s(26); font.weight: Font.Black
                        color: island.peach
                    }
                    Text {
                        text: island.weatherTemp === "--°" ? "No data" : "Clear Sky"
                        font.family: "JetBrains Mono"; font.pixelSize: island.s(11)
                        color: island.subtext0
                    }
                }
            }
        }
    }
}
