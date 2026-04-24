import QtQuick
import QtQuick.Layouts
import Quickshell
import "../pet"

Row {
    property var island
    property int preferredWidth: {
        let max = Screen.width - island.s(32)
        let len = Math.min(12, (island.musicData.title || "").length)
        return Math.min(Math.max(island.s(390), island.s(330) + len * island.s(5)), max)
    }
    spacing: island.s(14)

    // Cover art
    Rectangle {
        width: island.s(28); height: island.s(28); radius: island.s(8); clip: true
        color: island.surface2; anchors.verticalCenter: parent.verticalCenter
        Image {
            anchors.fill: parent
            source: island.musicData.artUrl || ""
            fillMode: Image.PreserveAspectCrop; asynchronous: true
        }
    }

    // Title + artist
    ColumnLayout {
        spacing: -2; anchors.verticalCenter: parent.verticalCenter
        Text { text: island.musicData.title || "Unknown"; font.family: "JetBrains Mono"; font.pixelSize: island.s(13); font.weight: Font.Black; color: island.text; Layout.maximumWidth: island.s(160); elide: Text.ElideRight }
        Text { text: island.musicData.artist || ""; visible: !!island.musicData.artist; font.family: "JetBrains Mono"; font.pixelSize: island.s(10); color: island.subtext0; Layout.maximumWidth: island.s(160); elide: Text.ElideRight }
    }

    // Playback controls
    Row {
        spacing: island.s(2); anchors.verticalCenter: parent.verticalCenter
        Rectangle {
            width: island.s(22); height: island.s(22); radius: island.s(11)
            color: prevM.containsMouse ? Qt.rgba(island.surface1.r, island.surface1.g, island.surface1.b, 0.7) : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }
            Text { anchors.centerIn: parent; text: "󰒮"; font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(13); color: island.subtext0 }
            MouseArea { id: prevM; anchors.fill: parent; hoverEnabled: true; onClicked: { island.exec("playerctl previous"); mouse.accepted = true } }
        }
        Rectangle {
            width: island.s(26); height: island.s(26); radius: island.s(13)
            color: playM.containsMouse ? Qt.rgba(island.mauve.r, island.mauve.g, island.mauve.b, 0.22) : Qt.rgba(island.surface0.r, island.surface0.g, island.surface0.b, 0.5)
            Behavior on color { ColorAnimation { duration: 120 } }
            Text { anchors.centerIn: parent; text: island.musicData.status === "Playing" ? "󰏤" : "󰐊"; font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(14); color: island.text }
            MouseArea { id: playM; anchors.fill: parent; hoverEnabled: true; onClicked: { island.exec("playerctl play-pause"); mouse.accepted = true } }
        }
        Rectangle {
            width: island.s(22); height: island.s(22); radius: island.s(11)
            color: nextM.containsMouse ? Qt.rgba(island.surface1.r, island.surface1.g, island.surface1.b, 0.7) : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }
            Text { anchors.centerIn: parent; text: "󰒭"; font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(13); color: island.subtext0 }
            MouseArea { id: nextM; anchors.fill: parent; hoverEnabled: true; onClicked: { island.exec("playerctl next"); mouse.accepted = true } }
        }
    }

    // Cava bars
    Item {
        width: island.s(36); height: island.s(18); anchors.verticalCenter: parent.verticalCenter
        Repeater {
            model: 6
            Rectangle {
                property color barColor: index === 0 ? island.blue
                    : index === 1 ? island.mauve
                    : index === 2 ? island.pink
                    : index === 3 ? island.peach
                    : index === 4 ? island.pink
                    : island.blue
                property real barVal: index === 0 ? island.cavaBar0
                    : index === 1 ? island.cavaBar1
                    : index === 2 ? island.cavaBar2
                    : index === 3 ? island.cavaBar3
                    : index === 4 ? island.cavaBar4
                    : island.cavaBar5
                x: index * island.s(6); width: island.s(4); anchors.bottom: parent.bottom
                height: island.musicData.status !== "Playing"
                    ? island.s(18) * 0.12
                    : Math.max(island.s(18) * 0.12, island.s(18) * barVal)
                Behavior on height { NumberAnimation { duration: 60; easing.type: Easing.Linear } }
                radius: island.s(2)
                opacity: island.musicData.status === "Playing" ? 1.0 : 0.3
                Behavior on opacity { NumberAnimation { duration: 300 } }
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: Qt.lighter(barColor, 1.3) }
                    GradientStop { position: 0.5; color: barColor }
                    GradientStop { position: 1.0; color: Qt.darker(barColor, 1.15) }
                }
            }
        }
    }

    CatPill {
        width: island.s(24); height: island.s(24); anchors.verticalCenter: parent.verticalCenter
        playing: island.musicData.status === "Playing"
        notifActive: island.notifActive || island.notifBadgeVisible
        showQuestion: false
        catColor: island.text; eyeColor: island.base
    }
}
