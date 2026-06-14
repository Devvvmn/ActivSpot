import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import "../themes"

Item {
    id: root
    property var island
    clip: true

    readonly property string _musicDir: Qt.resolvedUrl("../music").toString().replace("file://", "")

    // ── Background — drifting colour blobs ─────────────────────────────────
    Item {
        id: maskShape
        anchors.fill: parent; visible: false; layer.enabled: true
        Rectangle { anchors.fill: parent; radius: island.s(28); color: "white" }
    }

    Item {
        id: bgLayer
        anchors.fill: parent
        readonly property real cw: width
        readonly property real ch: height
        property real t: 0
        readonly property real tau: 2 * Math.PI

        FrameAnimation {
            running: island.expanded && island.currentPage === "music" && !Theme.reduceMotion
            onTriggered: bgLayer.t += frameTime / 24.0
        }

        Rectangle {
            anchors.fill: parent
            color: island.glassTheme
                ? Qt.rgba(island.base.r, island.base.g, island.base.b, 0)
                : Qt.rgba(island.base.r, island.base.g, island.base.b, 1)
            Behavior on color { ColorAnimation { duration: 520; easing.type: Easing.InOutCubic } }
        }
        Image {
            source: island.musicData.artUrl || ""
            fillMode: Image.PreserveAspectCrop; asynchronous: true
            opacity: island.glassTheme ? 0.32 : 0.65
            Behavior on opacity { NumberAnimation { duration: 520; easing.type: Easing.InOutCubic } }
            visible: source !== ""
            width: bgLayer.cw * 1.7; height: bgLayer.ch * 1.7
            x: (bgLayer.cw - width) / 2 + Math.cos(bgLayer.t * bgLayer.tau)        * island.s(60)
            y: (bgLayer.ch - height) / 2 + Math.sin(bgLayer.t * bgLayer.tau * 0.7) * island.s(30)
            scale: 1.06 + Math.sin(bgLayer.t * bgLayer.tau * 0.55) * 0.06
            layer.enabled: true
            layer.effect: MultiEffect { blurEnabled: true; blurMax: 96; blur: 1.0; saturation: 0.35; brightness: -0.02 }
        }
        Rectangle {
            width: bgLayer.cw * 1.10; height: bgLayer.ch * 0.95; radius: width / 2; color: island.mauve
            opacity: island.glassTheme ? 0.16 : 0.32
            x: bgLayer.cw * 0.50 - width / 2 + Math.cos(bgLayer.t * bgLayer.tau * 0.85)        * bgLayer.cw * 0.32
            y: bgLayer.ch * 0.50 - height / 2 + Math.sin(bgLayer.t * bgLayer.tau * 0.65 + 0.4) * bgLayer.ch * 0.42
            layer.enabled: true; layer.effect: MultiEffect { blurEnabled: true; blurMax: 128; blur: 1.0 }
        }
        Rectangle {
            width: bgLayer.cw * 0.95; height: bgLayer.ch * 1.05; radius: width / 2; color: island.blue
            opacity: island.glassTheme ? 0.14 : 0.28
            x: bgLayer.cw * 0.50 - width / 2 + Math.cos(bgLayer.t * bgLayer.tau * 1.10 + 2.1) * bgLayer.cw * 0.36
            y: bgLayer.ch * 0.50 - height / 2 + Math.sin(bgLayer.t * bgLayer.tau * 0.95 + 1.3) * bgLayer.ch * 0.35
            layer.enabled: true; layer.effect: MultiEffect { blurEnabled: true; blurMax: 128; blur: 1.0 }
        }
        Rectangle {
            width: bgLayer.cw * 0.80; height: bgLayer.ch * 0.85; radius: width / 2; color: island.peach
            opacity: island.glassTheme ? 0.10 : 0.20
            x: bgLayer.cw * 0.50 - width / 2 + Math.cos(bgLayer.t * bgLayer.tau * 0.55 + 4.2) * bgLayer.cw * 0.30
            y: bgLayer.ch * 0.50 - height / 2 + Math.sin(bgLayer.t * bgLayer.tau * 0.80 + 3.0) * bgLayer.ch * 0.40
            layer.enabled: true; layer.effect: MultiEffect { blurEnabled: true; blurMax: 128; blur: 1.0 }
        }
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: Qt.rgba(island.base.r, island.base.g, island.base.b, island.glassTheme ? 0.10 : 0.28) }
                GradientStop { position: 1.0; color: Qt.rgba(island.base.r, island.base.g, island.base.b, island.glassTheme ? 0.22 : 0.52) }
            }
        }
        layer.enabled: true
        layer.effect: MultiEffect { maskEnabled: true; maskSource: maskShape; maskThresholdMin: 0.5 }
    }

    // ── Foreground — macOS Dynamic Island style ────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin:   island.s(16)
        anchors.rightMargin:  island.s(16)
        anchors.topMargin:    island.s(14)
        anchors.bottomMargin: island.s(14)
        spacing: island.s(10)

        // ── Header: small art left, title + waveform right ─────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: island.s(16)

            // Album art — small square
            Item {
                Layout.preferredWidth:  island.s(70)
                Layout.preferredHeight: island.s(70)

                Item {
                    id: _coverMask; anchors.fill: parent; visible: false; layer.enabled: true
                    Rectangle { anchors.fill: parent; radius: island.s(14); color: "white" }
                }
                Rectangle {
                    anchors.fill: parent; radius: island.s(14); color: island.surface0
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true; shadowColor: Theme.shadowColor
                        blurMax: Theme.elev3Max; shadowBlur: 1.0
                        shadowOpacity: Theme.elev3Op + 0.10
                        shadowVerticalOffset: Theme.elev3Off + island.s(1)
                    }
                }
                Item {
                    anchors.fill: parent
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        maskEnabled: true; maskSource: _coverMask
                        maskThresholdMin: 0.5; maskSpreadAtMin: 1.0
                    }
                    Image {
                        id: _coverImg; anchors.fill: parent
                        source: island.musicData.artUrl || ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true; smooth: true; mipmap: true
                        opacity: status === Image.Ready ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                    }
                    // Placeholder when no art
                    Item {
                        anchors.fill: parent
                        visible: _coverImg.status !== Image.Ready
                        Rectangle {
                            anchors.fill: parent
                            gradient: Gradient {
                                orientation: Gradient.Vertical
                                GradientStop { position: 0.0; color: Qt.rgba(island.mauve.r, island.mauve.g, island.mauve.b, 0.30) }
                                GradientStop { position: 1.0; color: Qt.rgba(island.blue.r,  island.blue.g,  island.blue.b,  0.15) }
                            }
                        }
                        Text {
                            anchors.centerIn: parent
                            text: "󰝛"; font.family: "Iosevka Nerd Font"
                            font.pixelSize: island.s(32)
                            color: Qt.rgba(island.mauve.r, island.mauve.g, island.mauve.b, 0.50)
                        }
                    }
                    // Subtle gloss
                    Rectangle {
                        anchors.fill: parent
                        gradient: Gradient {
                            orientation: Gradient.Vertical
                            GradientStop { position: 0.0; color: Qt.rgba(1,1,1, 0.08) }
                            GradientStop { position: 0.5; color: "transparent" }
                        }
                    }
                }
            }

            // Track info + cava waveform
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: island.s(3)

                // Title row with waveform on the right
                RowLayout {
                    Layout.fillWidth: true
                    spacing: island.s(8)

                    Text {
                        Layout.fillWidth: true
                        text: island.musicData.title || "Nothing playing"
                        font.family: Theme.fontDisplay
                        font.pixelSize: island.s(18)
                        font.weight: Font.Bold
                        color: island.text
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }

                    // Cava waveform — 4 bars, inline, real audio data
                    Item {
                        id: cavaWrap
                        Layout.preferredWidth: island.s(28)
                        Layout.preferredHeight: island.s(20)
                        Layout.alignment: Qt.AlignVCenter

                        readonly property var _vals: [island.cavaBar1, island.cavaBar3, island.cavaBar2, island.cavaBar4]

                        Row {
                            anchors.fill: parent
                            spacing: island.s(3)
                            Repeater {
                                model: 4
                                delegate: Item {
                                    width: (parent.width - 3 * island.s(3)) / 4
                                    height: parent.height
                                    property real _v: cavaWrap._vals[index]
                                    Rectangle {
                                        property real _h: Math.max(island.s(3), _v * parent.height)
                                        Behavior on _h { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
                                        anchors.bottom: parent.bottom
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: parent.width; height: _h
                                        radius: width / 2
                                        color: island.musicData.status === "Playing"
                                            ? Qt.rgba(island.text.r, island.text.g, island.text.b, 0.55 + 0.40 * _v)
                                            : Qt.rgba(island.text.r, island.text.g, island.text.b, 0.20)
                                        Behavior on color { ColorAnimation { duration: 400 } }
                                    }
                                }
                            }
                        }
                    }
                }

                // Artist
                Text {
                    Layout.fillWidth: true
                    text: island.musicData.artist || "—"
                    font.family: Theme.fontUI
                    font.pixelSize: island.s(13)
                    font.weight: Font.Medium
                    color: Qt.rgba(island.text.r, island.text.g, island.text.b, 0.55)
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
            }
        }

        // ── Progress bar + timestamps ───────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            spacing: island.s(5)

            Slider {
                id: prog
                Layout.fillWidth: true; height: island.s(14)
                from: 0; to: 100; value: island.musicData.percent || 0
                onMoved: {
                    island.userIsSeeking = true
                    island.exec(`${root._musicDir}/player_control.sh seek ${value} ${island.musicData.length} "${island.selectedPlayer || island.musicData.playerName}"`)
                }
                onPressedChanged: if (!pressed) island.userIsSeeking = false

                background: Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: prog.pressed ? island.s(5) : island.s(3)
                    radius: height / 2
                    color: Qt.rgba(island.text.r, island.text.g, island.text.b, 0.14)
                    Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                    Rectangle {
                        width: prog.visualPosition * parent.width
                        height: parent.height; radius: height / 2
                        color: island.text
                    }
                }
                handle: Rectangle {
                    x: prog.visualPosition * (prog.width - width)
                    y: (prog.height - height) / 2
                    width: prog.pressed ? island.s(12) : island.s(0)
                    height: width; radius: width / 2
                    color: island.text
                    Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: island.musicData.positionStr || "0:00"
                    font.family: Theme.fontMono; font.pixelSize: island.s(10)
                    color: Qt.rgba(island.text.r, island.text.g, island.text.b, 0.45)
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: island.musicData.lengthStr || "0:00"
                    font.family: Theme.fontMono; font.pixelSize: island.s(10)
                    color: Qt.rgba(island.text.r, island.text.g, island.text.b, 0.45)
                }
            }
        }

        // ── Playback controls ───────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 0

            Item { Layout.fillWidth: true }

            // Previous
            Item {
                width: island.s(48); height: island.s(48)
                Text {
                    anchors.centerIn: parent
                    text: "󰒮"; font.family: "Iosevka Nerd Font"
                    font.pixelSize: island.s(26)
                    color: Qt.rgba(island.text.r, island.text.g, island.text.b, _pm.containsMouse ? 1.0 : 0.75)
                    Behavior on color { ColorAnimation { duration: 150 } }
                    scale: _pm.pressed ? 0.88 : 1.0
                    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                }
                MouseArea { id: _pm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: island.exec("playerctl" + (island.selectedPlayer ? " -p " + island.selectedPlayer : "") + " previous") }
            }

            Item { Layout.fillWidth: true }

            // Play / Pause — larger, white circle
            Item {
                width: island.s(52); height: island.s(52)
                Rectangle {
                    anchors.fill: parent; radius: width / 2
                    color: Qt.rgba(island.text.r, island.text.g, island.text.b, _plm.containsMouse ? 0.22 : 0.12)
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
                Text {
                    anchors.centerIn: parent
                    text: island.musicData.status === "Playing" ? "󰏤" : "󰐊"
                    font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(26)
                    color: island.text
                    scale: _plm.pressed ? 0.88 : 1.0
                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }
                }
                MouseArea { id: _plm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: island.exec("playerctl" + (island.selectedPlayer ? " -p " + island.selectedPlayer : "") + " play-pause") }
            }

            Item { Layout.fillWidth: true }

            // Next
            Item {
                width: island.s(48); height: island.s(48)
                Text {
                    anchors.centerIn: parent
                    text: "󰒭"; font.family: "Iosevka Nerd Font"
                    font.pixelSize: island.s(26)
                    color: Qt.rgba(island.text.r, island.text.g, island.text.b, _nm.containsMouse ? 1.0 : 0.75)
                    Behavior on color { ColorAnimation { duration: 150 } }
                    scale: _nm.pressed ? 0.88 : 1.0
                    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                }
                MouseArea { id: _nm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: island.exec("playerctl" + (island.selectedPlayer ? " -p " + island.selectedPlayer : "") + " next") }
            }

            Item { Layout.fillWidth: true }
        }
    }
}
