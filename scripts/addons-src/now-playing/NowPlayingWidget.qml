import QtQuick
import Quickshell
import Quickshell.Io
import themes

// Wallpaper-level synced-lyrics widget (karaoke). Polls nowplaying.sh for the
// current track + playback position, fetches synced LRC lyrics via lyrics.sh
// (lrclib.net), and scrolls them line-by-line, highlighting the current line.
//
// No layer.enabled / MultiEffect (breaks compositing on the Bottom layer).
// Never name a property `data` on an Item — it's Item's default property.
Item {
    id: root

    property var screen: null
    property string pluginDir: ""

    // ── Track state ────────────────────────────────────────────────────────────
    property var track: ({ status: "Stopped", title: "", artist: "", position: 0, length: 0 })
    readonly property bool isPlaying: track.status === "Playing"
    readonly property bool hasTrack:  (track.status === "Playing" || track.status === "Paused") && !!track.title
    readonly property string srcTitle:  hasTrack ? track.title  : ""
    readonly property string srcArtist: hasTrack ? track.artist : ""
    readonly property bool motion: !Theme.reduceMotion
    readonly property color shadow: Qt.rgba(0, 0, 0, 0.6)

    // ── Lyrics state ───────────────────────────────────────────────────────────
    property var lines: []                 // [{ t: seconds, text }]
    property int curIndex: 0
    property string lyricsState: "idle"    // idle | loading | ok | none
    property string _fetchedFor: ""        // title we last fetched

    // Smoothed playback position (polled value + local interpolation).
    property real posSec: 0

    // ── Polling: track + position ──────────────────────────────────────────────
    Process {
        id: npProc
        running: false
        command: ["bash", "-c", "bash '" + root.pluginDir + "/nowplaying.sh'"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    if (!this.text) return
                    const t = JSON.parse(this.text)
                    root.track = t
                    root.posSec = t.position || 0          // resync interpolation
                } catch (e) {}
            }
        }
    }
    Timer {
        interval: 1000; running: root.pluginDir !== ""; repeat: true; triggeredOnStart: true
        onTriggered: { npProc.running = false; npProc.running = true }
    }
    // Interpolate position between polls so line changes feel on-beat.
    Timer {
        interval: 200; running: root.isPlaying && root.lines.length > 0; repeat: true
        onTriggered: root.posSec += 0.2
    }

    onPosSecChanged: root.curIndex = root._indexFor(root.posSec)

    function _indexFor(p) {
        const L = lines
        if (!L || L.length === 0) return 0
        let lo = 0
        for (let i = 0; i < L.length; i++) { if (L[i].t <= p) lo = i; else break }
        return lo
    }

    // ── Lyrics fetch on track change ───────────────────────────────────────────
    Process {
        id: lyricsProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const parsed = root._parseLRC(this.text || "")
                root.lines = parsed
                root.lyricsState = parsed.length > 0 ? "ok" : "none"
                root.curIndex = root._indexFor(root.posSec)
            }
        }
    }

    onSrcTitleChanged: {
        if (!hasTrack || srcTitle === _fetchedFor) return
        _fetchedFor = srcTitle
        lines = []
        curIndex = 0
        lyricsState = "loading"
        lyricsProc.running = false
        lyricsProc.command = ["bash", "-c",
            "bash '" + pluginDir + "/lyrics.sh' " +
            _q(srcArtist) + " " + _q(srcTitle) + " " + (track.length || 0)]
        lyricsProc.running = true
    }

    function _q(s) { return "'" + String(s).replace(/'/g, "'\\''") + "'" }

    function _parseLRC(txt) {
        const out = []
        const re = /\[(\d+):(\d+)(?:[.:](\d+))?\]/g
        const rows = txt.split("\n")
        for (const row of rows) {
            const text = row.replace(/\[[^\]]*\]/g, "").trim()
            let m; re.lastIndex = 0
            while ((m = re.exec(row)) !== null) {
                const mm = parseInt(m[1]), ss = parseInt(m[2])
                const fr = m[3] ? parseInt((m[3] + "00").substring(0, 3)) / 1000 : 0
                out.push({ t: mm * 60 + ss + fr, text: text })
            }
        }
        out.sort((a, b) => a.t - b.t)
        return out
    }

    // ── Layout ──────────────────────────────────────────────────────────────────
    implicitWidth: 640
    implicitHeight: 240
    opacity: root.hasTrack ? 1.0 : 0.0
    Behavior on opacity { NumberAnimation { duration: 350 } }

    // Karaoke list
    ListView {
        id: lv
        anchors.fill: parent
        visible: root.lyricsState === "ok"
        clip: true
        interactive: false
        model: root.lines

        readonly property int slotH: 46
        currentIndex: Math.max(0, Math.min(root.curIndex, count - 1))
        highlightFollowsCurrentItem: true
        highlightRangeMode: ListView.StrictlyEnforceRange
        highlightMoveDuration: root.motion ? 420 : 0
        preferredHighlightBegin: (height - slotH) / 2
        preferredHighlightEnd:   (height + slotH) / 2

        delegate: Item {
            width: lv.width
            height: lv.slotH
            readonly property bool cur: index === lv.currentIndex

            Text {
                anchors.centerIn: parent
                width: parent.width - 28
                height: parent.height
                text: modelData.text.length ? modelData.text : "♪"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                // Long lines shrink to fit the width instead of clipping; short
                // lines stay at the full (emphasised) size.
                fontSizeMode: Text.HorizontalFit
                minimumPixelSize: 12
                elide: Text.ElideRight   // last resort if even min doesn't fit
                color: cur ? Theme.text : Theme.subtext0
                opacity: cur ? 1.0 : Math.max(0.18, 0.5 - Math.abs(index - lv.currentIndex) * 0.13)
                font.pixelSize: cur ? 25 : 20
                font.weight: cur ? Font.Bold : Font.Medium
                style: Text.Raised
                styleColor: root.shadow
                Behavior on opacity { NumberAnimation { duration: 280 } }
                Behavior on color   { ColorAnimation  { duration: 280 } }
            }
        }
    }

    // Fallback (loading / no lyrics) — show track title + artist
    Column {
        anchors.centerIn: parent
        width: parent.width - 32
        spacing: 6
        visible: root.lyricsState !== "ok"
        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: root.srcTitle
            color: Theme.text
            font.pixelSize: 26; font.weight: Font.Bold
            elide: Text.ElideRight
            style: Text.Raised; styleColor: root.shadow
        }
        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: root.srcArtist
            color: Theme.subtext0
            font.pixelSize: 16
            elide: Text.ElideRight
            style: Text.Raised; styleColor: root.shadow
        }
        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: root.lyricsState === "loading" ? "loading lyrics…" : "no synced lyrics"
            color: Theme.accent
            font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 2
            visible: root.hasTrack
        }
    }
}
