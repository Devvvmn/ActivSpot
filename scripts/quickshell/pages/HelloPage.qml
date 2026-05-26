import QtQuick
import QtQuick.Effects
import "../themes"

Item {
    id: root
    property var island

    // ── Features list ────────────────────────────────────────────────────────
    readonly property var features: [
        { id: "intro",   icon: "",    title: "hello.",          sub: "Meet ActivSpot",                                      accent: "mauve"  },
        { id: "clock",   icon: "󰸘",  title: "Clock & Weather", sub: "Flip-digit time with\nlive animated weather scenes",  accent: "blue"   },
        { id: "music",   icon: "󰝚",  title: "Music",           sub: "Full player · EQ\n& Cava visualizer",                accent: "green"  },
        { id: "notifs",  icon: "󰂚",  title: "Notifications",   sub: "Inline alerts,\nzero interruption",                  accent: "yellow" },
        { id: "timer",   icon: "󰔛",  title: "Timer",           sub: "Countdown & stopwatch\nalways at hand",              accent: "peach"  },
        { id: "stash",   icon: "󰉋",  title: "File Stash",      sub: "Drop anything,\nfind it instantly",                  accent: "teal"   },
        { id: "vol",     icon: "󰕾",  title: "Volume Drag",     sub: "Elastic drag gesture\nto set volume",                accent: "pink"   },
        { id: "bubbles", icon: "󱥰",  title: "Minibubbles",     sub: "Floating status pills\nalways in sight",             accent: "mauve"  },
        { id: "bar",     icon: "󰡄",  title: "Top Bar",         sub: "Fully customizable\napplets row",                   accent: "blue"   },
        { id: "discord", icon: "󰙯",  title: "Discord",         sub: "Call timer & mute status\nright in the island",      accent: "blue"   },
        { id: "themes",  icon: "󰏘",  title: "6 Themes",        sub: "mocha · nord · apple\ncarbon · midnight · matugen", accent: "red"    },
        { id: "outro",   icon: "",    title: "it's all yours.", sub: "Tap anywhere to dismiss",                            accent: "mauve"  },
    ]

    readonly property int totalFeatures: features.length - 2

    // ── State ────────────────────────────────────────────────────────────────
    property int  step:   0
    property bool paused: false

    function accentColor(name) {
        switch (name) {
            case "blue":   return island.blue
            case "green":  return island.green
            case "yellow": return island.yellow
            case "peach":  return island.peach
            case "teal":   return island.teal
            case "pink":   return island.pink
            case "red":    return island.red
            default:       return island.mauve
        }
    }

    function advance() {
        if (step >= features.length - 1) {
            island.expanded = false
            return
        }
        step++
        paused = false
        autoAdvance.restart()
    }

    function goBack() {
        if (step <= 0) return
        step--
        paused = false
        autoAdvance.restart()
    }

    // ── Reset + start when page opens ────────────────────────────────────────
    Connections {
        target: island
        function onCurrentPageChanged() {
            if (island.currentPage === "hello" && island.expanded) {
                root.step   = 0
                root.paused = false
                autoAdvance.restart()
            } else {
                autoAdvance.stop()
            }
        }
        function onExpandedChanged() {
            if (island.expanded && island.currentPage === "hello") {
                root.step   = 0
                root.paused = false
                autoAdvance.restart()
            } else if (!island.expanded) {
                autoAdvance.stop()
                root.step = 0
            }
        }
    }

    // ── Auto-advance: 3.5 s per slide ────────────────────────────────────────
    Timer {
        id: autoAdvance
        interval: 3500
        repeat:   false
        running:  false
        onTriggered: root.advance()
    }

    // ── Tap: left-third = back, right-two-thirds = pause / advance ───────────
    MouseArea {
        anchors.fill: parent
        z: 20
        onClicked: function(mouse) {
            if (mouse.x < parent.width * 0.28) {
                root.goBack()
            } else if (root.paused) {
                root.paused = false
                root.advance()
            } else {
                root.paused = true
                autoAdvance.stop()
            }
        }
    }

    // ── Progress dots ────────────────────────────────────────────────────────
    Row {
        anchors.top:              parent.top
        anchors.topMargin:        island.s(14)
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: island.s(5)
        z: 30

        Repeater {
            model: root.features.length
            delegate: Rectangle {
                property bool isActive: index === root.step
                width:  isActive ? island.s(18) : island.s(5)
                height: island.s(5)
                radius: island.s(3)
                color:  isActive
                    ? root.accentColor(root.features[root.step].accent)
                    : Qt.rgba(island.text.r, island.text.g, island.text.b, 0.18)
                anchors.verticalCenter: parent.verticalCenter
                Behavior on width { NumberAnimation { duration: 280; easing.type: Easing.OutExpo } }
                Behavior on color { ColorAnimation  { duration: 250 } }
            }
        }
    }

    // ── Pause indicator ──────────────────────────────────────────────────────
    Text {
        anchors.bottom:       parent.bottom
        anchors.bottomMargin: island.s(14)
        anchors.right:        parent.right
        anchors.rightMargin:  island.s(20)
        text:    "⏸"
        font.pixelSize: island.s(11)
        color:   Qt.rgba(island.text.r, island.text.g, island.text.b, 0.35)
        opacity: root.paused ? 1.0 : 0.0
        visible: opacity > 0.001
        Behavior on opacity { NumberAnimation { duration: 180 } }
        z: 30
    }

    // ── Slides ───────────────────────────────────────────────────────────────
    Item {
        anchors.fill:         parent
        anchors.topMargin:    island.s(36)
        anchors.bottomMargin: island.s(16)

        Repeater {
            model: root.features.length
            delegate: Item {
                id: slide
                anchors.fill: parent

                property var  feat:      root.features[index]
                property bool isCurrent: index === root.step

                opacity: isCurrent ? 1.0 : 0.0
                visible: opacity > 0.001
                Behavior on opacity {
                    NumberAnimation { duration: 260; easing.type: Easing.InOutCubic }
                }
                transform: Translate {
                    y: slide.isCurrent ? 0 : island.s(14)
                    Behavior on y {
                        NumberAnimation { duration: 400; easing.type: Easing.OutExpo }
                    }
                }

                // ── Content ──────────────────────────────────────────────────
                Column {
                    anchors.centerIn: parent
                    width:   parent.width - island.s(60)
                    spacing: island.s(14)

                    // Icon — feature slides only
                    Item {
                        width:   parent.width
                        height:  island.s(70)
                        visible: slide.feat.icon !== ""

                        // Glow layer
                        Text {
                            anchors.centerIn: parent
                            text:             slide.feat.icon
                            font.family:      "Iosevka Nerd Font"
                            font.pixelSize:   island.s(52)
                            color:            root.accentColor(slide.feat.accent)
                            opacity:          0.45
                            scale:            1.55
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                blurEnabled: true
                                blur:        1.0
                                blurMax:     40
                            }
                        }
                        // Sharp icon
                        Text {
                            anchors.centerIn: parent
                            text:             slide.feat.icon
                            font.family:      "Iosevka Nerd Font"
                            font.pixelSize:   island.s(52)
                            color:            root.accentColor(slide.feat.accent)
                        }
                    }

                    // Title
                    Text {
                        width:               parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text:                slide.feat.title
                        font.family:  (slide.feat.id === "intro" || slide.feat.id === "outro") ? Theme.fontDisplay : Theme.fontUI
                        font.pixelSize: (slide.feat.id === "intro" || slide.feat.id === "outro") ? island.s(54) : island.s(26)
                        font.weight:  (slide.feat.id === "intro" || slide.feat.id === "outro") ? Font.Thin : Font.Bold
                        font.italic:  slide.feat.id === "intro" || slide.feat.id === "outro"
                        color: (slide.feat.id === "intro" || slide.feat.id === "outro")
                            ? root.accentColor(slide.feat.accent)
                            : island.text

                        // Breathing pulse for intro / outro titles
                        SequentialAnimation on opacity {
                            running: (slide.feat.id === "intro" || slide.feat.id === "outro")
                                     && slide.isCurrent && !Theme.reduceMotion
                            loops:   Animation.Infinite
                            NumberAnimation { from: 0.55; to: 1.0;  duration: 1900; easing.type: Easing.InOutSine }
                            NumberAnimation { from: 1.0;  to: 0.55; duration: 1900; easing.type: Easing.InOutSine }
                        }
                    }

                    // Description / subtitle
                    Text {
                        width:               parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text:                slide.feat.sub
                        font.family:         Theme.fontUI
                        font.pixelSize:      island.s(14)
                        font.weight:         Font.Light
                        color:               Qt.rgba(island.text.r, island.text.g, island.text.b, 0.58)
                        wrapMode:            Text.WordWrap
                        lineHeight:          1.45
                    }

                    // Step counter — feature slides only
                    Text {
                        width:               parent.width
                        horizontalAlignment: Text.AlignHCenter
                        visible:             slide.feat.id !== "intro" && slide.feat.id !== "outro"
                        text:                index + " / " + root.totalFeatures
                        font.family:         Theme.fontMono
                        font.pixelSize:      island.s(10)
                        color:               Qt.rgba(island.text.r, island.text.g, island.text.b, 0.28)
                    }

                    // "tap to begin" hint — intro only
                    Text {
                        width:               parent.width
                        horizontalAlignment: Text.AlignHCenter
                        visible:             slide.feat.id === "intro"
                        text:                "tap to begin  →"
                        font.family:         Theme.fontUI
                        font.pixelSize:      island.s(12)
                        color:               Qt.rgba(island.text.r, island.text.g, island.text.b, 0.4)

                        SequentialAnimation on opacity {
                            running: slide.isCurrent && !Theme.reduceMotion
                            loops:   Animation.Infinite
                            NumberAnimation { from: 0.2; to: 0.9;  duration: 1100; easing.type: Easing.InOutSine }
                            NumberAnimation { from: 0.9; to: 0.2;  duration: 1100; easing.type: Easing.InOutSine }
                        }
                    }
                }
            }
        }
    }
}
