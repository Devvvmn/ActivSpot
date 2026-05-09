import QtQuick
import "../pet"

Row {
    property var island
    property int preferredWidth: island.s(240)
    spacing: island.s(12)

    // Pulsing green mic dot
    Rectangle {
        width: island.s(28); height: island.s(28); radius: island.s(14)
        color: Qt.rgba(island.green.r, island.green.g, island.green.b, 0.12)
        anchors.verticalCenter: parent.verticalCenter
        Rectangle {
            anchors.centerIn: parent
            width: island.s(14); height: island.s(14); radius: island.s(7)
            color: island.green
            SequentialAnimation on opacity {
                running: island.discordInCall; loops: Animation.Infinite
                NumberAnimation { to: 0.25; duration: 900; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0;  duration: 900; easing.type: Easing.InOutSine }
            }
        }
    }

    // VOICE + timer
    Column {
        spacing: -1; anchors.verticalCenter: parent.verticalCenter
        Text {
            text: "VOICE"
            font.family: "JetBrains Mono"; font.pixelSize: island.s(13); font.weight: Font.Black
            font.letterSpacing: island.s(2); color: island.green
        }
        Text {
            text: {
                let t = island.discordCallSeconds
                let h = Math.floor(t / 3600)
                let m = Math.floor((t % 3600) / 60)
                let s2 = t % 60
                if (h > 0)
                    return (h < 10 ? "0"+h : h) + ":" + (m < 10 ? "0"+m : m) + ":" + (s2 < 10 ? "0"+s2 : s2)
                return (m < 10 ? "0"+m : m) + ":" + (s2 < 10 ? "0"+s2 : s2)
            }
            font.family: "JetBrains Mono"; font.pixelSize: island.s(11); font.weight: Font.Bold
            color: Qt.rgba(island.green.r, island.green.g, island.green.b, 0.6)
        }
    }

    // Discord icon
    Text {
        text: "󰙯"
        font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(18)
        color: Qt.rgba(island.green.r, island.green.g, island.green.b, 0.7)
        anchors.verticalCenter: parent.verticalCenter
    }

    CatPill {
        width: island.s(24); height: island.s(24); anchors.verticalCenter: parent.verticalCenter
        playing: island.musicData.status === "Playing"
        notifActive: island.notifActive || island.notifBadgeVisible
        showQuestion: false; catColor: island.text; eyeColor: island.base; accentColor: island.mauve
    }
}
