import QtQuick
import Quickshell
import Quickshell.Io
import themes

// Wallpaper-level weather card. Sources the shell's own weather.sh (--json),
// shows the condition icon, current temperature (nearest hourly), description
// and daily hi/lo. Refreshes every 10 minutes.
// Never name a property `data` on an Item.
Item {
    id: root

    property var screen: null
    property string pluginDir: ""

    property var today: ({})
    readonly property bool ready: today && today.desc !== undefined
    readonly property color shadow: Qt.rgba(0, 0, 0, 0.6)

    // current temperature = nearest hourly entry to now, else feels_like
    readonly property string curTemp: {
        if (!ready) return "—"
        const hrs = today.hourly || []
        if (hrs.length > 0) {
            const nowMin = new Date().getHours() * 60 + new Date().getMinutes()
            let best = hrs[0], bestD = 1e9
            for (const h of hrs) {
                const p = String(h.time || "0:0").split(":")
                const m = parseInt(p[0]) * 60 + parseInt(p[1] || "0")
                const d = Math.abs(m - nowMin)
                if (d < bestD) { bestD = d; best = h }
            }
            if (best && best.temp !== undefined) return Math.round(parseFloat(best.temp)) + "°"
        }
        return today.feels_like !== undefined ? Math.round(parseFloat(today.feels_like)) + "°" : "—"
    }

    Process {
        id: proc
        running: false
        command: ["bash", "-c", "bash ~/.config/hypr/scripts/quickshell/calendar/weather.sh --json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(this.text || "{}")
                    if (j.forecast && j.forecast.length) root.today = j.forecast[0]
                } catch (e) {}
            }
        }
    }
    Timer {
        interval: 600000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: { proc.running = false; proc.running = true }
    }

    implicitWidth: row.width
    implicitHeight: row.height

    Row {
        id: row
        spacing: 18

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.ready ? today.icon : ""
            color: root.ready && today.hex ? today.hex : Theme.accent
            font.family: "Iosevka Nerd Font"
            font.pixelSize: 76
            style: Text.Raised; styleColor: root.shadow
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                text: root.curTemp
                color: Theme.text
                font.pixelSize: 56
                font.weight: Font.Bold
                style: Text.Raised; styleColor: root.shadow
            }
            Text {
                text: root.ready ? today.desc : "loading…"
                color: Theme.text
                font.pixelSize: 17
                font.weight: Font.Medium
                style: Text.Raised; styleColor: root.shadow
            }
            Text {
                visible: root.ready
                text: root.ready ? ("H " + Math.round(parseFloat(today.max)) + "°   L "
                                   + Math.round(parseFloat(today.min)) + "°") : ""
                color: Theme.subtext0
                font.pixelSize: 13
                font.weight: Font.Medium
                font.letterSpacing: 1
                style: Text.Raised; styleColor: root.shadow
            }
        }
    }
}
