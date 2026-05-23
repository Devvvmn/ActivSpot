import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import "../"

Item {
    id: root

    Scaler { id: scaler; currentWidth: Screen.width }
    function s(val) { return scaler.s(val); }

    MatugenColors { id: _theme }

    readonly property color base:     _theme.base
    readonly property color surface0: _theme.surface0
    readonly property color surface1: _theme.surface1
    readonly property color text:     _theme.text
    readonly property color subtext0: _theme.subtext0
    readonly property color mauve:    _theme.mauve
    readonly property color blue:     _theme.blue
    readonly property color green:    _theme.green

    property var musicData: ({
        "title": "Nothing playing", "artist": "", "status": "Stopped",
        "percent": 0, "length": 0, "lengthStr": "0:00", "positionStr": "0:00",
        "artUrl": "", "playerName": ""
    })
    property var eqData: ({ "preset": "Flat" })
    property bool userIsSeeking: false
    property string activeTab: "music"

    // ── Decorative visualizer (sine-wave, plays when music is Playing) ──────
    property real _t: 0
    property real _vizAmp: 0
    Behavior on _vizAmp { NumberAnimation { duration: 1100; easing.type: Easing.OutCubic } }

    readonly property var _vizFreqs:  [0.85, 1.10, 0.62, 1.35, 0.78, 1.02, 0.55, 1.48, 0.91, 0.68, 1.22, 0.82, 1.05, 0.73, 1.38, 0.60, 0.96, 1.15, 0.77, 1.28]
    readonly property var _vizPhases: [0.0,  1.2,  2.4,  0.8,  3.1,  1.9,  0.4,  2.8,  1.5,  3.5,  0.2,  2.1,  1.0,  3.8,  0.6,  2.6,  1.7,  0.9,  3.3,  1.4]

    FrameAnimation {
        running: true
        onTriggered: {
            root._t += frameTime
            root._vizAmp = (root.musicData.status === "Playing") ? 1.0 : 0.0
        }
    }

    // ── Data refresh ─────────────────────────────────────────────────────────
    Timer {
        interval: 500; running: true; repeat: true; triggeredOnStart: true
        onTriggered: { musicProc.running = true; eqProc.running = true }
    }

    Process {
        id: musicProc
        command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/music/music_info.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { if (this.text) root.musicData = JSON.parse(this.text) } catch(e) {}
            }
        }
    }

    Process {
        id: eqProc
        command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/music/equalizer.sh get"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { if (this.text) root.eqData = JSON.parse(this.text) } catch(e) {}
            }
        }
    }

    function exec(cmd) { Quickshell.execDetached(["bash", "-c", cmd]) }

    // ── Cinematic crossfade tracking ─────────────────────────────────────────
    property string _trackedArtUrl: ""

    onMusicDataChanged: {
        let newUrl = root.musicData.artUrl || ""
        if (newUrl !== root._trackedArtUrl) {
            root._trackedArtUrl = newUrl
            coverPrev.source = coverCur.source
            coverPrev.opacity = 1.0
            coverPrev.scale   = 1.0
            coverCur.source   = newUrl
            coverCur.opacity  = 0.0
            coverCur.scale    = 1.04
            xfadeAnim.start()
        }
    }

    ParallelAnimation {
        id: xfadeAnim
        NumberAnimation { target: coverPrev; property: "opacity"; from: 1.0;  to: 0.0;  duration: 520; easing.type: Easing.OutCubic }
        NumberAnimation { target: coverPrev; property: "scale";   from: 1.0;  to: 1.08; duration: 520; easing.type: Easing.OutCubic }
        NumberAnimation { target: coverCur;  property: "opacity"; from: 0.0;  to: 1.0;  duration: 520; easing.type: Easing.OutCubic }
        NumberAnimation { target: coverCur;  property: "scale";   from: 1.04; to: 1.0;  duration: 520; easing.type: Easing.OutCubic }
    }

    // ── Container ────────────────────────────────────────────────────────────
    Rectangle {
        id: container
        anchors.fill: parent
        color: Qt.rgba(root.base.r, root.base.g, root.base.b, 0.97)
        radius: root.s(20)
        border.color: Qt.rgba(root.text.r, root.text.g, root.text.b, 0.07)
        border.width: 1
        clip: true

        // ── Hero: full-width cover ────────────────────────────────────────
        Item {
            id: heroArea
            anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
            height: parent.height * 0.52
            clip: true

            // Blurred ambient background
            Image {
                id: ambientBg
                anchors.fill: parent
                source: root.musicData.artUrl || ""
                fillMode: Image.PreserveAspectCrop
                opacity: 0.40
                Behavior on opacity { NumberAnimation { duration: 400 } }
                layer.enabled: true
                layer.effect: MultiEffect { blurEnabled: true; blurMax: 80; blur: 1.0; saturation: 0.25 }
            }

            // Previous cover (fades out on track change)
            Image {
                id: coverPrev
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                opacity: 0; scale: 1.0
                transformOrigin: Item.Center
            }

            // Current cover (fades in on track change)
            Image {
                id: coverCur
                anchors.fill: parent
                source: root.musicData.artUrl || ""
                fillMode: Image.PreserveAspectCrop
                opacity: 1; scale: 1.0
                transformOrigin: Item.Center
            }

            // Mild dark scrim so white text pops
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.18)
            }

            // Bottom gradient scrim for text readability
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width; height: parent.height * 0.72
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 1.0; color: Qt.rgba(root.base.r, root.base.g, root.base.b, 0.96) }
                }
            }

            // Track info overlay (bottom-left)
            Column {
                anchors.left: parent.left; anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: root.s(28); anchors.rightMargin: root.s(28)
                anchors.bottomMargin: root.s(16)
                spacing: root.s(5)

                Row {
                    spacing: root.s(6)
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: root.s(7); height: root.s(7); radius: width / 2
                        color: root.musicData.status === "Playing" ? root.green : root.subtext0
                        SequentialAnimation on opacity {
                            running: root.musicData.status === "Playing"
                            loops: Animation.Infinite
                            NumberAnimation { from: 1.0; to: 0.28; duration: 900; easing.type: Easing.InOutSine }
                            NumberAnimation { from: 0.28; to: 1.0; duration: 900; easing.type: Easing.InOutSine }
                        }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.musicData.status === "Playing" ? "NOW PLAYING" : "PAUSED"
                        font.family: "JetBrains Mono"; font.pixelSize: root.s(10)
                        font.weight: Font.Black; font.letterSpacing: 2.8
                        color: Qt.rgba(1, 1, 1, 0.72)
                    }
                }

                Text {
                    width: parent.width
                    text: root.musicData.title || "Nothing playing"
                    font.family: "JetBrains Mono"
                    font.pixelSize: text.length > 30 ? root.s(20) : root.s(24)
                    font.weight: Font.Black; font.letterSpacing: -0.4
                    color: "white"; elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: root.musicData.artist || "—"
                    font.family: "JetBrains Mono"; font.pixelSize: root.s(13); font.weight: Font.Medium
                    color: Qt.rgba(1, 1, 1, 0.65); elide: Text.ElideRight
                }
            }
        }

        // ── Content below hero ────────────────────────────────────────────
        Item {
            anchors.top: heroArea.bottom; anchors.left: parent.left
            anchors.right: parent.right; anchors.bottom: parent.bottom
            anchors.topMargin: root.s(16)
            anchors.leftMargin: root.s(24); anchors.rightMargin: root.s(24)
            anchors.bottomMargin: root.s(18)

            ColumnLayout {
                anchors.fill: parent
                spacing: root.s(12)

                // ── Progress ─────────────────────────────────────────────
                ColumnLayout {
                    Layout.fillWidth: true; spacing: root.s(4)

                    Slider {
                        id: progSlider; Layout.fillWidth: true; height: root.s(16)
                        from: 0; to: 100; value: root.musicData.percent || 0
                        onMoved: {
                            root.userIsSeeking = true
                            root.exec(`~/.config/hypr/scripts/quickshell/music/player_control.sh seek ${value} ${root.musicData.length} "${root.musicData.playerName}"`)
                        }
                        onPressedChanged: if (!pressed) root.userIsSeeking = false

                        background: Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: progSlider.pressed ? root.s(5) : root.s(3)
                            radius: height / 2
                            color: Qt.rgba(root.text.r, root.text.g, root.text.b, 0.14)
                            Behavior on height { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                            Rectangle {
                                width: progSlider.visualPosition * parent.width
                                height: parent.height; radius: height / 2
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: root.mauve }
                                    GradientStop { position: 1.0; color: root.blue }
                                }
                            }
                        }
                        handle: Rectangle {
                            x: progSlider.visualPosition * (progSlider.width - width)
                            y: (progSlider.height - height) / 2
                            width: progSlider.pressed ? root.s(14) : root.s(10)
                            height: width; radius: width / 2
                            color: root.text; border.width: 1; border.color: root.mauve
                            Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: root.musicData.positionStr || "0:00"; font.family: "JetBrains Mono"; font.pixelSize: root.s(10); color: root.subtext0 }
                        Item { Layout.fillWidth: true }
                        Text { text: root.musicData.lengthStr || "0:00"; font.family: "JetBrains Mono"; font.pixelSize: root.s(10); color: root.subtext0 }
                    }
                }

                // ── Tab pills ────────────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true; spacing: root.s(8)

                    Rectangle {
                        Layout.fillWidth: true; height: root.s(34); radius: root.s(17)
                        color: root.activeTab === "music" ? root.mauve : Qt.rgba(root.surface0.r, root.surface0.g, root.surface0.b, 0.65)
                        Behavior on color { ColorAnimation { duration: 180 } }
                        scale: _tabMusicMa.pressed ? 0.96 : 1.0
                        Behavior on scale { NumberAnimation { duration: 100 } }
                        Row {
                            anchors.centerIn: parent; spacing: root.s(6)
                            Text { anchors.verticalCenter: parent.verticalCenter; text: "󰝚"; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(14); color: root.activeTab === "music" ? root.base : root.text }
                            Text { anchors.verticalCenter: parent.verticalCenter; text: "Now Playing"; font.family: "JetBrains Mono"; font.pixelSize: root.s(12); font.weight: Font.Medium; color: root.activeTab === "music" ? root.base : root.text }
                        }
                        MouseArea { id: _tabMusicMa; anchors.fill: parent; onClicked: root.activeTab = "music" }
                    }

                    Rectangle {
                        Layout.fillWidth: true; height: root.s(34); radius: root.s(17)
                        color: root.activeTab === "eq" ? root.mauve : Qt.rgba(root.surface0.r, root.surface0.g, root.surface0.b, 0.65)
                        Behavior on color { ColorAnimation { duration: 180 } }
                        scale: _tabEqMa.pressed ? 0.96 : 1.0
                        Behavior on scale { NumberAnimation { duration: 100 } }
                        Row {
                            anchors.centerIn: parent; spacing: root.s(6)
                            Text { anchors.verticalCenter: parent.verticalCenter; text: "󰕾"; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(14); color: root.activeTab === "eq" ? root.base : root.text }
                            Text { anchors.verticalCenter: parent.verticalCenter; text: "Equalizer"; font.family: "JetBrains Mono"; font.pixelSize: root.s(12); font.weight: Font.Medium; color: root.activeTab === "eq" ? root.base : root.text }
                        }
                        MouseArea { id: _tabEqMa; anchors.fill: parent; onClicked: root.activeTab = "eq" }
                    }
                }

                // ── Music tab content ────────────────────────────────────
                Item {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    opacity: root.activeTab === "music" ? 1.0 : 0.0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                    ColumnLayout {
                        anchors.fill: parent; spacing: root.s(14)

                        // Decorative visualizer
                        Item {
                            Layout.fillWidth: true; Layout.preferredHeight: root.s(44)

                            Row {
                                anchors.fill: parent; spacing: root.s(4)
                                Repeater {
                                    model: 20
                                    delegate: Item {
                                        id: vizBar
                                        width: (parent.width - 19 * root.s(4)) / 20
                                        height: parent.height
                                        property real _v: root._vizAmp * (0.28 + 0.72 * (0.5 + 0.5 * Math.sin(root._t * 2 * Math.PI * root._vizFreqs[index] + root._vizPhases[index])))

                                        Rectangle {
                                            property real _h: Math.max(root.s(4), vizBar._v * parent.height)
                                            Behavior on _h { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
                                            anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
                                            width: parent.width; height: _h; radius: width / 2
                                            gradient: Gradient {
                                                orientation: Gradient.Vertical
                                                GradientStop { position: 0.0; color: Qt.rgba(root.mauve.r, root.mauve.g, root.mauve.b, 0.28 + 0.68 * vizBar._v) }
                                                GradientStop { position: 1.0; color: Qt.rgba(root.blue.r, root.blue.g, root.blue.b, 0.55) }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Playback controls
                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: root.s(36)

                            Rectangle {
                                Layout.preferredWidth: root.s(52); Layout.preferredHeight: root.s(52); radius: root.s(26)
                                color: _pm.containsMouse ? root.surface1 : Qt.rgba(root.surface0.r, root.surface0.g, root.surface0.b, 0.55)
                                border.width: 1; border.color: Qt.rgba(root.text.r, root.text.g, root.text.b, 0.07)
                                scale: _pm.pressed ? 0.92 : 1.0
                                Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
                                Behavior on color { ColorAnimation { duration: 180 } }
                                Text { anchors.centerIn: parent; text: "󰒮"; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(24); color: root.text }
                                MouseArea { id: _pm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: root.exec("playerctl previous") }
                            }

                            Rectangle {
                                Layout.preferredWidth: root.s(72); Layout.preferredHeight: root.s(72); radius: root.s(36)
                                scale: _plm.pressed ? 0.93 : (_plm.containsMouse ? 1.05 : 1.0)
                                Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
                                gradient: Gradient {
                                    orientation: Gradient.Vertical
                                    GradientStop { position: 0.0; color: root.mauve }
                                    GradientStop { position: 1.0; color: root.blue }
                                }
                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    shadowEnabled: true; shadowColor: root.mauve
                                    blurMax: 28; shadowBlur: 1.0
                                    shadowOpacity: 0.42; shadowVerticalOffset: root.s(4)
                                }
                                Text { anchors.centerIn: parent; text: root.musicData.status === "Playing" ? "󰏤" : "󰐊"; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(32); color: root.base }
                                MouseArea { id: _plm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: root.exec("playerctl play-pause") }
                            }

                            Rectangle {
                                Layout.preferredWidth: root.s(52); Layout.preferredHeight: root.s(52); radius: root.s(26)
                                color: _nm.containsMouse ? root.surface1 : Qt.rgba(root.surface0.r, root.surface0.g, root.surface0.b, 0.55)
                                border.width: 1; border.color: Qt.rgba(root.text.r, root.text.g, root.text.b, 0.07)
                                scale: _nm.pressed ? 0.92 : 1.0
                                Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
                                Behavior on color { ColorAnimation { duration: 180 } }
                                Text { anchors.centerIn: parent; text: "󰒭"; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(24); color: root.text }
                                MouseArea { id: _nm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: root.exec("playerctl next") }
                            }
                        }
                    }
                }

                // ── EQ tab content ───────────────────────────────────────
                Item {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    opacity: root.activeTab === "eq" ? 1.0 : 0.0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                    ColumnLayout {
                        anchors.fill: parent; spacing: root.s(10)

                        // 10 EQ band sliders
                        Item {
                            Layout.fillWidth: true; Layout.fillHeight: true

                            Row {
                                anchors.fill: parent; spacing: root.s(8)
                                Repeater {
                                    model: 10
                                    delegate: Item {
                                        id: eqBandItem
                                        property int bandIndex: index
                                        width: (parent.width - 9 * root.s(8)) / 10
                                        height: parent.height

                                        ColumnLayout {
                                            anchors.fill: parent; spacing: root.s(4)

                                            Slider {
                                                id: eqSlider
                                                Layout.fillWidth: true; Layout.fillHeight: true
                                                orientation: Qt.Vertical
                                                from: -12; to: 12; stepSize: 1
                                                value: root.eqData["b" + (eqBandItem.bandIndex + 1)] || 0
                                                onMoved: root.exec(`~/.config/hypr/scripts/quickshell/music/equalizer.sh set_band ${eqBandItem.bandIndex + 1} ${value}`)

                                                background: Rectangle {
                                                    anchors.centerIn: parent
                                                    width: root.s(4); height: parent.height; radius: 2
                                                    color: Qt.rgba(root.text.r, root.text.g, root.text.b, 0.11)

                                                    Rectangle {
                                                        width: parent.width; radius: 2; color: root.mauve
                                                        property real _midPct: 0.5
                                                        property real _valPct: 1.0 - eqSlider.visualPosition
                                                        y: Math.min(_midPct, _valPct) * parent.height
                                                        height: Math.abs(_midPct - _valPct) * parent.height
                                                        opacity: 0.85
                                                    }
                                                }

                                                handle: Rectangle {
                                                    x: (eqSlider.width - width) / 2
                                                    y: eqSlider.visualPosition * (eqSlider.height - height)
                                                    width: root.s(14); height: root.s(14); radius: root.s(7)
                                                    color: root.mauve
                                                    border.width: 2; border.color: root.base
                                                    layer.enabled: true
                                                    layer.effect: MultiEffect {
                                                        shadowEnabled: true; shadowColor: root.mauve
                                                        blurMax: 10; shadowBlur: 1.0; shadowOpacity: 0.30
                                                    }
                                                }
                                            }

                                            Text {
                                                Layout.alignment: Qt.AlignHCenter
                                                text: ["32", "64", "125", "250", "500", "1K", "2K", "4K", "8K", "16K"][eqBandItem.bandIndex]
                                                font.family: "JetBrains Mono"; font.pixelSize: root.s(9)
                                                color: root.subtext0
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Preset chips
                        RowLayout {
                            Layout.fillWidth: true; spacing: root.s(8)

                            Repeater {
                                model: ["Flat", "Bass", "Treble", "Rock", "Pop"]
                                delegate: Rectangle {
                                    Layout.fillWidth: true; height: root.s(34); radius: root.s(17)
                                    color: root.eqData.preset === modelData ? root.mauve : Qt.rgba(root.surface0.r, root.surface0.g, root.surface0.b, 0.65)
                                    Behavior on color { ColorAnimation { duration: 180 } }
                                    scale: _pma.pressed ? 0.94 : 1.0
                                    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData; font.family: "JetBrains Mono"
                                        font.pixelSize: root.s(11); font.weight: Font.Medium
                                        color: root.eqData.preset === modelData ? root.base : root.text
                                    }
                                    MouseArea { id: _pma; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: root.exec(`~/.config/hypr/scripts/quickshell/music/equalizer.sh preset ${modelData}`) }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
