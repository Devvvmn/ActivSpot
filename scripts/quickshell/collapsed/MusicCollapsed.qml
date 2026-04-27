import QtQuick
import QtQuick.Layouts
import Quickshell
import "../pet"

Row {
    id: row
    property var island
    // Content-driven width: hugs whatever the inner Row actually measures
    // (cover + text + controls + cava + cat + spacings), plus pill padding.
    // Floor keeps it from collapsing on very short metadata; cap respects screen edge.
    property int preferredWidth: {
        let max = Screen.width - island.s(32)
        let pad = island.s(28)
        let want = row.implicitWidth + pad
        return Math.min(Math.max(island.s(280), want), max)
    }
    spacing: island.s(12)

    // Cover art
    Rectangle {
        width: island.s(26); height: island.s(26); radius: island.s(7); clip: true
        color: island.surface0; anchors.verticalCenter: parent.verticalCenter
        Image {
            anchors.fill: parent
            source: island.musicData.artUrl || ""
            fillMode: Image.PreserveAspectCrop; asynchronous: true
        }
    }

    // Title + artist
    ColumnLayout {
        spacing: -1; anchors.verticalCenter: parent.verticalCenter
        Text { text: island.musicData.title || "Unknown"; font.family: "JetBrains Mono"; font.pixelSize: island.s(12); font.weight: Font.Black; color: island.text; Layout.maximumWidth: island.s(200); elide: Text.ElideRight }
        Text { text: island.musicData.artist || ""; visible: !!island.musicData.artist; font.family: "JetBrains Mono"; font.pixelSize: island.s(9); color: island.subtext0; Layout.maximumWidth: island.s(200); elide: Text.ElideRight }
    }

    // Playback controls
    Row {
        spacing: island.s(2); anchors.verticalCenter: parent.verticalCenter
        Rectangle {
            width: island.s(21); height: island.s(21); radius: island.s(11)
            color: prevM.containsMouse ? Qt.rgba(island.surface1.r, island.surface1.g, island.surface1.b, 0.6) : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }
            Text { anchors.centerIn: parent; text: "󰒮"; font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(12); color: island.subtext0 }
            MouseArea { id: prevM; anchors.fill: parent; hoverEnabled: true; onClicked: { island.exec("playerctl previous"); mouse.accepted = true } }
        }
        Rectangle {
            width: island.s(25); height: island.s(25); radius: island.s(13)
            color: playM.containsMouse
                ? Qt.rgba(island.mauve.r, island.mauve.g, island.mauve.b, 0.22)
                : Qt.rgba(island.mauve.r, island.mauve.g, island.mauve.b, 0.15)
            Behavior on color { ColorAnimation { duration: 120 } }
            Text { anchors.centerIn: parent; text: island.musicData.status === "Playing" ? "󰏤" : "󰐊"; font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(13); color: island.text }
            MouseArea { id: playM; anchors.fill: parent; hoverEnabled: true; onClicked: { island.exec("playerctl play-pause"); mouse.accepted = true } }
        }
        Rectangle {
            width: island.s(21); height: island.s(21); radius: island.s(11)
            color: nextM.containsMouse ? Qt.rgba(island.surface1.r, island.surface1.g, island.surface1.b, 0.6) : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }
            Text { anchors.centerIn: parent; text: "󰒭"; font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(12); color: island.subtext0 }
            MouseArea { id: nextM; anchors.fill: parent; hoverEnabled: true; onClicked: { island.exec("playerctl next"); mouse.accepted = true } }
        }
    }

    // Cava bars — centered mirror, grow up AND down from middle axis
    Item {
        id: cavaCollapsed
        width: island.s(28); height: island.s(16); anchors.verticalCenter: parent.verticalCenter
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
                property real halfMax: cavaCollapsed.height / 2
                property real halfH: island.musicData.status !== "Playing"
                    ? Math.max(1, halfMax * 0.10)
                    : Math.max(1, halfMax * barVal)

                x: index * island.s(5); width: island.s(3); radius: island.s(1.5)
                y: cavaCollapsed.height / 2 - halfH
                height: halfH * 2
                Behavior on height { NumberAnimation { duration: 60; easing.type: Easing.Linear } }
                Behavior on y      { NumberAnimation { duration: 60; easing.type: Easing.Linear } }
                opacity: island.musicData.status === "Playing" ? 1.0 : 0.35
                Behavior on opacity { NumberAnimation { duration: 300 } }
                color: barColor
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
