import QtQuick
import QtQuick.Layouts

Row {
    property var island
    property int preferredWidth: island.s(150)
    spacing: island.s(8)

    Text {
        text: "󰏫"
        font.family: "Iosevka Nerd Font"
        font.pixelSize: island.s(18)
        color: island.mauve
        anchors.verticalCenter: parent.verticalCenter

        SequentialAnimation on opacity {
            running: true; loops: Animation.Infinite
            NumberAnimation { to: 0.55; duration: 900; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.00; duration: 900; easing.type: Easing.InOutSine }
        }
    }

    Text {
        text: "EDIT MODE"
        font.family: "JetBrains Mono"
        font.pixelSize: island.s(12)
        font.weight: Font.Black
        font.letterSpacing: 1.4
        color: island.text
        anchors.verticalCenter: parent.verticalCenter
    }
}
