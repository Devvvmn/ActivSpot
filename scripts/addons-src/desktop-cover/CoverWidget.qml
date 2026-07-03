import QtQuick
import Quickshell
import Quickshell.Io
import themes

// Wallpaper-level album cover. Polls music/music_info.sh, shows the current
// track's art with a blurred backdrop glow, crossfading on track change.
// Hides when nothing is playing. Never name a property `data` on an Item.
Item {
    id: root

    property var screen: null
    property string pluginDir: ""

    property var music: ({ status: "Stopped", artUrl: "", blur: "" })
    readonly property bool hasTrack: (music.status === "Playing" || music.status === "Paused")
    readonly property bool motion: !Theme.reduceMotion
    property string _shownArt: ""
    property string _shownBlur: ""

    Process {
        id: proc
        running: false
        command: ["bash", "-c", "bash ~/.config/hypr/scripts/quickshell/music/music_info.sh"]
        stdout: StdioCollector {
            onStreamFinished: { try { if (this.text) root.music = JSON.parse(this.text) } catch (e) {} }
        }
    }
    Timer {
        interval: 1500; running: true; repeat: true; triggeredOnStart: true
        onTriggered: { proc.running = false; proc.running = true }
    }

    readonly property string srcArt: hasTrack ? (music.artUrl || "") : ""
    onSrcArtChanged: {
        if (srcArt === _shownArt) return
        if (!motion) { _shownArt = srcArt; _shownBlur = music.blur || ""; return }
        artSwap.restart()
    }

    SequentialAnimation {
        id: artSwap
        NumberAnimation { target: stack; property: "opacity"; to: 0; duration: 220; easing.type: Easing.InCubic }
        ScriptAction { script: { root._shownArt = root.srcArt; root._shownBlur = root.music.blur || "" } }
        NumberAnimation { target: stack; property: "opacity"; to: 1; duration: 320; easing.type: Easing.OutCubic }
    }

    implicitWidth: 220
    implicitHeight: 220
    opacity: root.hasTrack ? 1.0 : 0.0
    Behavior on opacity { NumberAnimation { duration: 350 } }

    Item {
        id: stack
        anchors.fill: parent

        // Blurred glow backdrop (pre-blurred PNG from music_info.sh)
        Image {
            anchors.centerIn: parent
            width: parent.width * 1.18
            height: parent.height * 1.18
            source: root._shownBlur
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            opacity: 0.55
            visible: root._shownBlur.length > 0
        }

        // Sharp cover, rounded
        Rectangle {
            anchors.fill: parent
            radius: 18
            clip: true
            color: Qt.rgba(Theme.base.r, Theme.base.g, Theme.base.b, 0.5)
            border.width: 1
            border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.12)

            Image {
                anchors.fill: parent
                source: root._shownArt
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
            }
        }
    }
}
