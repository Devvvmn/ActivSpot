import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects

Item {
    id: root
    property var island
    clip: true

    // ── Album-art driven background morph ──────────────────────────────
    // Single time parameter `t` (0→1, infinite loop). All blob/art positions
    // are pure functions of t, cw, ch — no stateful from/to to desync, so
    // resizing the panel never causes a jump.
    // Rounded clipping is done via MultiEffect.maskSource so children with
    // their own layer effects (blur) still get masked to the panel radius.

    // Offscreen mask: white rounded rect → defines the visible shape
    Item {
        id: maskShape
        anchors.fill: parent
        visible: false
        layer.enabled: true
        Rectangle {
            anchors.fill: parent
            radius: island.s(28)
            color: "white"
        }
    }

    Item {
        id: bgLayer
        anchors.fill: parent

        readonly property real cw: width
        readonly property real ch: height

        // Continuous time parameter — monotonically increasing, never wraps.
        // Wrapping `t` from 1→0 caused cos(t·tau·freq) to jump because the
        // frequency multipliers aren't integers. Letting t grow forever lets
        // cosine handle periodicity naturally — perfectly seamless motion.
        property real t: 0
        readonly property real tau: 2 * Math.PI

        FrameAnimation {
            // Only tick while music page is actually visible — saves CPU/GPU
            // when collapsed or on another page. (Item.visible doesn't cascade
            // from Loader, so we check the island state directly.)
            running: island.expanded && island.currentPage === "music"
            // 24s per "unit"; cycle of a freq=1 wave = 24s
            onTriggered: bgLayer.t += frameTime / 24.0
        }

        // Solid base in case art is missing or transparent.
        // In glass mode keep it transparent so the island's glass shows through —
        // album art / blobs still render on top when present.
        Rectangle {
            anchors.fill: parent
            color: island.glassTheme
                ? Qt.rgba(island.base.r, island.base.g, island.base.b, 0)
                : Qt.rgba(island.base.r, island.base.g, island.base.b, 1)
            Behavior on color { ColorAnimation { duration: 520; easing.type: Easing.InOutCubic } }
        }

        Image {
            id: bgArt
            source: island.musicData.artUrl || ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            opacity: island.glassTheme ? 0.32 : 0.65
            Behavior on opacity { NumberAnimation { duration: 520; easing.type: Easing.InOutCubic } }
            visible: source != ""
            width: bgLayer.cw * 1.7
            height: bgLayer.ch * 1.7
            // Drift via cosine on shared t — no internal state to desync
            x: (bgLayer.cw - width) / 2 + Math.cos(bgLayer.t * bgLayer.tau)       * island.s(60)
            y: (bgLayer.ch - height) / 2 + Math.sin(bgLayer.t * bgLayer.tau * 0.7) * island.s(30)
            scale: 1.06 + Math.sin(bgLayer.t * bgLayer.tau * 0.55) * 0.06
            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: true; blurMax: 96; blur: 1.0
                saturation: 0.35; brightness: -0.02
            }
        }

        // Three drifting waves — independent phases & frequencies for organic motion.
        Rectangle {
            id: blobA
            width: bgLayer.cw * 1.10; height: bgLayer.ch * 0.95
            radius: width / 2
            color: island.mauve
            opacity: island.glassTheme ? 0.16 : 0.32
            Behavior on opacity { NumberAnimation { duration: 520; easing.type: Easing.InOutCubic } }
            x: bgLayer.cw * 0.50 - width / 2 + Math.cos(bgLayer.t * bgLayer.tau * 0.85)        * bgLayer.cw * 0.32
            y: bgLayer.ch * 0.50 - height / 2 + Math.sin(bgLayer.t * bgLayer.tau * 0.65 + 0.4) * bgLayer.ch * 0.42
            layer.enabled: true
            layer.effect: MultiEffect { blurEnabled: true; blurMax: 128; blur: 1.0 }
        }
        Rectangle {
            id: blobB
            width: bgLayer.cw * 0.95; height: bgLayer.ch * 1.05
            radius: width / 2
            color: island.blue
            opacity: island.glassTheme ? 0.14 : 0.28
            Behavior on opacity { NumberAnimation { duration: 520; easing.type: Easing.InOutCubic } }
            x: bgLayer.cw * 0.50 - width / 2 + Math.cos(bgLayer.t * bgLayer.tau * 1.10 + 2.1) * bgLayer.cw * 0.36
            y: bgLayer.ch * 0.50 - height / 2 + Math.sin(bgLayer.t * bgLayer.tau * 0.95 + 1.3) * bgLayer.ch * 0.35
            layer.enabled: true
            layer.effect: MultiEffect { blurEnabled: true; blurMax: 128; blur: 1.0 }
        }
        Rectangle {
            id: blobC
            width: bgLayer.cw * 0.80; height: bgLayer.ch * 0.85
            radius: width / 2
            color: island.peach
            opacity: island.glassTheme ? 0.10 : 0.20
            Behavior on opacity { NumberAnimation { duration: 520; easing.type: Easing.InOutCubic } }
            x: bgLayer.cw * 0.50 - width / 2 + Math.cos(bgLayer.t * bgLayer.tau * 0.55 + 4.2) * bgLayer.cw * 0.30
            y: bgLayer.ch * 0.50 - height / 2 + Math.sin(bgLayer.t * bgLayer.tau * 0.80 + 3.0) * bgLayer.ch * 0.40
            layer.enabled: true
            layer.effect: MultiEffect { blurEnabled: true; blurMax: 128; blur: 1.0 }
        }

        // Light readability scrim
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: Qt.rgba(island.base.r, island.base.g, island.base.b, island.glassTheme ? 0.10 : 0.30) }
                GradientStop { position: 1.0; color: Qt.rgba(island.base.r, island.base.g, island.base.b, island.glassTheme ? 0.25 : 0.55) }
            }
        }

        // Rounded mask — clips the entire layer (including children's blur effects)
        // to the panel shape. Plain `clip: true` only does scissor (rectangular).
        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: maskShape
            maskThresholdMin: 0.5
        }
    }

    Item {
        anchors.fill: parent
        anchors.margins: island.s(20)
        anchors.bottomMargin: island.s(68)

        ColumnLayout {
            anchors.fill: parent
            spacing: island.s(14)

            // ── Cover art + track info ──────────────────────────
            // Plain Item with anchors — guarantees cover and right column share
            // the exact same vertical band. Layouts kept giving the right column
            // an inflated natural height that decoupled them.
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: island.s(100)

                Rectangle {
                    id: cover
                    width: island.s(100); height: island.s(100)
                    anchors.left: parent.left; anchors.top: parent.top
                    radius: island.s(14); color: island.surface0; clip: true; layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true; shadowColor: "#000000"
                        shadowOpacity: 0.45; shadowBlur: 0.55; shadowVerticalOffset: 4
                    }
                    Image {
                        anchors.fill: parent; anchors.margins: 1
                        source: island.musicData.artUrl || ""
                        fillMode: Image.PreserveAspectCrop; asynchronous: true
                    }
                }

                Item {
                    anchors.left: cover.right; anchors.leftMargin: island.s(16)
                    anchors.right: parent.right
                    anchors.top: parent.top; anchors.bottom: parent.bottom

                    Text {
                        id: titleText
                        anchors.left: parent.left; anchors.right: parent.right
                        anchors.top: parent.top
                        text: island.musicData.title || "Unknown"
                        font.family: "JetBrains Mono"; font.pixelSize: island.s(18); font.weight: Font.Black
                        color: island.text; elide: Text.ElideRight
                    }
                    Text {
                        id: artistText
                        anchors.left: parent.left; anchors.right: parent.right
                        anchors.top: titleText.bottom; anchors.topMargin: island.s(2)
                        text: island.musicData.artist || "—"
                        font.family: "JetBrains Mono"; font.pixelSize: island.s(12)
                        color: island.subtext0; elide: Text.ElideRight
                    }

                    Item {
                        id: posRow
                        anchors.left: parent.left; anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: island.s(14)

                        Text {
                            anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                            text: island.musicData.positionStr || "00:00"
                            font.family: "JetBrains Mono"; font.pixelSize: island.s(10); color: island.subtext0
                        }
                        Text {
                            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                            text: island.musicData.lengthStr || "00:00"
                            font.family: "JetBrains Mono"; font.pixelSize: island.s(10); color: island.subtext0
                        }
                    }

                    Slider {
                        id: prog
                        anchors.left: parent.left; anchors.right: parent.right
                        anchors.bottom: posRow.top; anchors.bottomMargin: island.s(4)
                        height: island.s(16)
                        from: 0; to: 100; value: island.musicData.percent || 0
                        onMoved: {
                            island.userIsSeeking = true
                            island.exec(`~/.config/hypr/scripts/quickshell/music/player_control.sh seek ${value} ${island.musicData.length} "${island.musicData.playerName}"`)
                        }
                        onPressedChanged: if (!pressed) island.userIsSeeking = false

                        background: Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width; height: island.s(4); radius: island.s(2)
                            color: Qt.rgba(island.text.r, island.text.g, island.text.b, 0.18)
                            Rectangle {
                                width: prog.visualPosition * parent.width; height: parent.height; radius: island.s(2)
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: island.mauve }
                                    GradientStop { position: 1.0; color: island.blue }
                                }
                            }
                        }
                        handle: Rectangle {
                            x: prog.visualPosition * (prog.width - island.s(12))
                            y: (prog.height - island.s(12)) / 2
                            width: island.s(12); height: island.s(12); radius: island.s(6)
                            color: island.text; border.width: 2; border.color: island.mauve
                        }
                    }
                }
            }

            // ── Playback controls ───────────────────────────────
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: island.s(28)

                Rectangle {
                    Layout.preferredWidth: island.s(40); Layout.preferredHeight: island.s(40); radius: island.s(20)
                    color: prevMouse.containsMouse ? island.surface1 : Qt.rgba(island.surface0.r, island.surface0.g, island.surface0.b, 0.7)
                    Behavior on color { ColorAnimation { duration: 180 } }
                    Text { anchors.centerIn: parent; text: "󰒮"; font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(20); color: island.text }
                    MouseArea { id: prevMouse; anchors.fill: parent; hoverEnabled: true; onClicked: island.exec("playerctl previous") }
                }

                Rectangle {
                    Layout.preferredWidth: island.s(56); Layout.preferredHeight: island.s(56); radius: island.s(28)
                    color: island.mauve
                    scale: playMouse.containsMouse ? 1.06 : 1.0
                    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
                    layer.enabled: true
                    layer.effect: MultiEffect { shadowEnabled: true; shadowColor: island.mauve; shadowOpacity: 0.30; shadowBlur: 0.65 }
                    Text { anchors.centerIn: parent; text: island.musicData.status === "Playing" ? "󰏤" : "󰐊"; font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(24); color: island.base }
                    MouseArea { id: playMouse; anchors.fill: parent; hoverEnabled: true; onClicked: island.exec("playerctl play-pause") }
                }

                Rectangle {
                    Layout.preferredWidth: island.s(40); Layout.preferredHeight: island.s(40); radius: island.s(20)
                    color: nextMouse.containsMouse ? island.surface1 : Qt.rgba(island.surface0.r, island.surface0.g, island.surface0.b, 0.7)
                    Behavior on color { ColorAnimation { duration: 180 } }
                    Text { anchors.centerIn: parent; text: "󰒭"; font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(20); color: island.text }
                    MouseArea { id: nextMouse; anchors.fill: parent; hoverEnabled: true; onClicked: island.exec("playerctl next") }
                }
            }

            // ── EQ header + preset badge ────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "EQUALIZER"
                    font.family: "JetBrains Mono"; font.pixelSize: island.s(11); font.weight: Font.Black; font.letterSpacing: 2
                    color: island.mauve; Layout.fillWidth: true
                }
                Rectangle {
                    Layout.preferredHeight: island.s(20)
                    Layout.preferredWidth: presetLabel.implicitWidth + island.s(16)
                    radius: island.s(10)
                    color: Qt.rgba(island.mauve.r, island.mauve.g, island.mauve.b, 0.15)
                    border.width: 1; border.color: Qt.rgba(island.mauve.r, island.mauve.g, island.mauve.b, 0.4)
                    Text {
                        id: presetLabel; anchors.centerIn: parent
                        text: island.eqData.preset || "Flat"
                        font.family: "JetBrains Mono"; font.pixelSize: island.s(10); font.weight: Font.Bold
                        color: island.mauve
                    }
                }
            }

            // ── EQ band sliders ─────────────────────────────────
            RowLayout {
                Layout.fillWidth: true; Layout.preferredHeight: island.s(96)
                spacing: island.s(6)
                Repeater {
                    model: 10
                    delegate: ColumnLayout {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        spacing: island.s(3)

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: { let v = island.eqData["b" + (index + 1)] || 0; return v > 0 ? "+" + v : "" + v }
                            font.family: "JetBrains Mono"; font.pixelSize: island.s(8)
                            color: Math.abs(island.eqData["b" + (index + 1)] || 0) > 0 ? island.mauve : island.subtext0
                        }
                        Item {
                            Layout.fillWidth: true; Layout.fillHeight: true
                            Slider {
                                id: eqSlider; anchors.fill: parent; orientation: Qt.Vertical
                                from: -12; to: 12; stepSize: 1
                                value: island.eqData["b" + (index + 1)] || 0
                                onMoved: island.exec(`~/.config/hypr/scripts/quickshell/music/equalizer.sh set_band ${index + 1} ${value}`)
                                onPressedChanged: if (!pressed) island.exec(`~/.config/hypr/scripts/quickshell/music/equalizer.sh apply`)

                                background: Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: island.s(5); height: parent.height; radius: island.s(2)
                                    color: island.surface0
                                    Rectangle {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: island.s(10); height: 1
                                        color: Qt.rgba(island.text.r, island.text.g, island.text.b, 0.15)
                                    }
                                    Rectangle {
                                        property real valNorm: (eqSlider.value - eqSlider.from) / (eqSlider.to - eqSlider.from)
                                        property real centerY: parent.height / 2
                                        property real fillTop:    Math.min(centerY, parent.height * (1 - valNorm))
                                        property real fillBottom: Math.max(centerY, parent.height * (1 - valNorm))
                                        x: (parent.width - width) / 2; y: fillTop
                                        width: parent.width; height: fillBottom - fillTop; radius: island.s(2)
                                        gradient: Gradient {
                                            orientation: Gradient.Vertical
                                            GradientStop { position: 0.0; color: island.mauve }
                                            GradientStop { position: 1.0; color: island.blue }
                                        }
                                        opacity: Math.abs(eqSlider.value) > 0 ? 0.9 : 0.4
                                        Behavior on opacity { NumberAnimation { duration: 200 } }
                                    }
                                }
                                handle: Rectangle {
                                    x: (parent.width - island.s(13)) / 2
                                    y: eqSlider.visualPosition * (parent.height - island.s(13))
                                    width: island.s(13); height: island.s(13); radius: island.s(6)
                                    color: island.text; border.width: 2; border.color: island.mauve
                                }
                            }
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: ["32","64","125","250","500","1K","2K","4K","8K","16K"][index]
                            font.family: "JetBrains Mono"; font.pixelSize: island.s(8)
                            color: island.subtext0
                        }
                    }
                }
            }

            // ── EQ preset chips ─────────────────────────────────
            RowLayout {
                Layout.fillWidth: true; spacing: island.s(6)
                Repeater {
                    model: ["Flat", "Bass", "Treble", "Vocal", "Pop", "Rock"]
                    delegate: Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: island.s(26); radius: island.s(13)
                        property bool isActive:  island.eqData.preset === modelData
                        property bool isHovered: chipMouse.containsMouse
                        color: isActive ? island.mauve
                             : (isHovered ? island.surface1
                             : Qt.rgba(island.surface0.r, island.surface0.g, island.surface0.b, 0.6))
                        Behavior on color { ColorAnimation { duration: 180 } }
                        border.width: 1
                        border.color: isActive
                            ? Qt.rgba(island.mauve.r, island.mauve.g, island.mauve.b, 0.8)
                            : Qt.rgba(island.text.r, island.text.g, island.text.b, 0.08)
                        Text {
                            anchors.centerIn: parent; text: modelData
                            font.family: "JetBrains Mono"; font.pixelSize: island.s(10); font.weight: Font.Bold
                            color: parent.isActive ? island.base : island.text
                        }
                        MouseArea {
                            id: chipMouse; anchors.fill: parent; hoverEnabled: true
                            onClicked: island.exec(`~/.config/hypr/scripts/quickshell/music/equalizer.sh preset ${modelData}`)
                        }
                    }
                }
            }
        }
    }
}
