import QtQuick
import QtQuick.Layouts

Row {
    property var island
    property int preferredWidth: island.s(180)
    spacing: island.s(14)

    RowLayout {
        anchors.verticalCenter: parent.verticalCenter
        spacing: island.s(8)

        Text {
            text: " " // box icon
            font.family: "Iosevka Nerd Font"
            font.pixelSize: island.s(22)
            color: island.mauve
        }

        Text {
            text: "Stash"
            font.family: "JetBrains Mono"
            font.pixelSize: island.s(16)
            font.weight: Font.Bold
            color: island.text
        }
    }
}
