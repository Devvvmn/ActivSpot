import QtQuick
import "../themes"

// Collapsed island state while a game is active.
// Layout: [● ABR  144fps  |  GPU 76%  |  CPU 38%  |  38°]
Row {
    property var island
    property int preferredWidth: island.s(340)

    readonly property color cText:    Theme.text
    readonly property color cMuted:   Theme.overlay0
    readonly property color cDivider: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.10)

    spacing: 0
    anchors.verticalCenter: parent !== null ? parent.verticalCenter : undefined
    leftPadding:  island.s(14)
    rightPadding: island.s(14)

    readonly property color healthColor: {
        if (island.gameFps > 100 && island.gamePing < 22) return island.green;
        if (island.gameFps > 60  && island.gamePing < 45) return island.yellow;
        return island.red;
    }
    readonly property string gameAbbrev: {
        var n = (island.gameName || "").trim();
        if (n.length === 0) return "GAME";
        var parts = n.split(/[\s\-_:]+/).filter(function(p){ return p.length > 0; });
        var s = "";
        if (parts.length >= 2) {
            for (var i = 0; i < Math.min(3, parts.length); i++) s += parts[i].charAt(0);
        } else {
            s = parts[0].substring(0, 3);
        }
        return s.toUpperCase();
    }

    // Health dot
    Rectangle {
        width: island.s(7); height: island.s(7); radius: island.s(4)
        anchors.verticalCenter: parent.verticalCenter
        color: parent.healthColor
        Behavior on color { ColorAnimation { duration: 400 } }
    }

    Item { width: island.s(8); height: 1 }

    // Game abbreviation
    Text {
        text: parent.gameAbbrev
        font.family: "JetBrains Mono"; font.pixelSize: island.s(12); font.weight: Font.Black
        color: parent.cText
        anchors.verticalCenter: parent.verticalCenter
    }

    Item { width: island.s(10); height: 1 }
    Rectangle { width: 1; height: island.s(14); color: parent.cDivider; anchors.verticalCenter: parent.verticalCenter }
    Item { width: island.s(10); height: 1 }

    // FPS
    Text {
        text: island.gameFps
        font.family: "JetBrains Mono"; font.pixelSize: island.s(13); font.weight: Font.Black
        color: parent.healthColor; anchors.verticalCenter: parent.verticalCenter
        Behavior on color { ColorAnimation { duration: 400 } }
    }
    Text {
        text: "fps"
        font.family: "JetBrains Mono"; font.pixelSize: island.s(8)
        color: parent.cMuted; anchors.verticalCenter: parent.verticalCenter
    }

    Item { width: island.s(10); height: 1 }
    Rectangle { width: 1; height: island.s(12); color: parent.cDivider; anchors.verticalCenter: parent.verticalCenter }
    Item { width: island.s(10); height: 1 }

    // GPU
    Text { text: "GPU"; font.family: "JetBrains Mono"; font.pixelSize: island.s(8); font.weight: Font.Black; color: parent.cMuted; anchors.verticalCenter: parent.verticalCenter }
    Item { width: island.s(3); height: 1 }
    Text { text: island.gameGpu; font.family: "JetBrains Mono"; font.pixelSize: island.s(13); font.weight: Font.Black; color: island.blue; anchors.verticalCenter: parent.verticalCenter }
    Text { text: "%"; font.family: "JetBrains Mono"; font.pixelSize: island.s(8); color: parent.cMuted; anchors.verticalCenter: parent.verticalCenter }

    Item { width: island.s(10); height: 1 }
    Rectangle { width: 1; height: island.s(12); color: parent.cDivider; anchors.verticalCenter: parent.verticalCenter }
    Item { width: island.s(10); height: 1 }

    // CPU
    Text { text: "CPU"; font.family: "JetBrains Mono"; font.pixelSize: island.s(8); font.weight: Font.Black; color: parent.cMuted; anchors.verticalCenter: parent.verticalCenter }
    Item { width: island.s(3); height: 1 }
    Text { text: island.gameCpu; font.family: "JetBrains Mono"; font.pixelSize: island.s(13); font.weight: Font.Black; color: island.mauve; anchors.verticalCenter: parent.verticalCenter }
    Text { text: "%"; font.family: "JetBrains Mono"; font.pixelSize: island.s(8); color: parent.cMuted; anchors.verticalCenter: parent.verticalCenter }

    Item { width: island.s(10); height: 1 }
    Rectangle { width: 1; height: island.s(12); color: parent.cDivider; anchors.verticalCenter: parent.verticalCenter }
    Item { width: island.s(10); height: 1 }

    // GPU Temp
    Text {
        text: island.gameGpuTemp + "°"
        font.family: "JetBrains Mono"; font.pixelSize: island.s(12); font.weight: Font.Bold
        color: island.gameGpuTemp > 85 ? island.peach : island.teal
        anchors.verticalCenter: parent.verticalCenter
        Behavior on color { ColorAnimation { duration: 400 } }
    }
}
