import QtQuick
import "../themes"

Row {
    property var island
    property int preferredWidth: island.s(170)
    spacing: island.s(8)
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined

    Text {
        text: "󰨙"
        font.family: "Iosevka Nerd Font"
        font.pixelSize: island.s(15)
        color: Theme.accent
        anchors.verticalCenter: parent.verticalCenter
    }
    Column {
        spacing: -1
        anchors.verticalCenter: parent.verticalCenter
        Text {
            text: "Controls"
            font.family: "JetBrains Mono"
            font.pixelSize: island.s(13)
            font.weight: Font.Black
            color: island.text
        }
        Text {
            text: (island.dndEnabled ? "dnd on" : "vol " + island.currentVol + "%")
                + (island.vpnActive ? " · vpn" : "")
            font.family: "JetBrains Mono"
            font.pixelSize: island.s(9)
            color: island.subtext0
        }
    }

    Rectangle {
        width: 1; height: island.s(16)
        anchors.verticalCenter: parent.verticalCenter
        color: Qt.rgba(island.text.r, island.text.g, island.text.b, 0.10)
    }

    Row {
        spacing: island.s(5)
        anchors.verticalCenter: parent.verticalCenter
        Text {
            text: island.currentVol === 0 ? "󰖁" : (island.currentVol > 55 ? "󰕾" : "󰖀")
            font.family: "Iosevka Nerd Font"
            font.pixelSize: island.s(13)
            color: island.subtext0
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            visible: island.dndEnabled
            text: "󰂛"
            font.family: "Iosevka Nerd Font"
            font.pixelSize: island.s(13)
            color: island.mauve
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
