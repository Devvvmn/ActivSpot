import QtQuick
import QtQuick.Layouts
import Quickshell
import "../"
import "../themes"

Item {
    id: root

    Scaler { id: scaler; currentWidth: Screen.width }
    function s(v) { return scaler.s(v) }

    // ── Features ──────────────────────────────────────────────────────────────
    readonly property var features: [
        { id: "intro",   icon: "",    title: "hello.",          sub: "Meet ActivSpot",                                      accent: Theme.mauve  },
        { id: "clock",   icon: "󰸘",  title: "Clock & Weather", sub: "Flip-digit time with\nlive animated weather scenes",  accent: Theme.blue   },
        { id: "music",   icon: "󰝚",  title: "Music",           sub: "Full player · EQ\n& Cava visualizer",                accent: Theme.green  },
        { id: "notifs",  icon: "󰂚",  title: "Notifications",   sub: "Inline alerts,\nzero interruption",                  accent: Theme.yellow },
        { id: "timer",   icon: "󰔛",  title: "Timer",           sub: "Countdown & stopwatch\nalways at hand",              accent: Theme.peach  },
        { id: "stash",   icon: "󰉋",  title: "File Stash",      sub: "Drop anything,\nfind it instantly",                  accent: Theme.teal   },
        { id: "vol",     icon: "󰕾",  title: "Volume Drag",     sub: "Elastic drag gesture\nto set volume",                accent: Theme.pink   },
        { id: "bubbles", icon: "󱥰",  title: "Minibubbles",     sub: "Floating status pills\nalways in sight",             accent: Theme.mauve  },
        { id: "bar",     icon: "󰡄",  title: "Top Bar",         sub: "Fully customizable\napplets row",                   accent: Theme.blue   },
        { id: "discord", icon: "󰙯",  title: "Discord",         sub: "Call timer & mute status\nright in the island",      accent: Theme.blue   },
        { id: "themes",  icon: "󰏘",  title: "6 Themes",        sub: "mocha · nord · apple\ncarbon · midnight · matugen", accent: Theme.red    },
        { id: "outro",   icon: "",    title: "it's all yours.", sub: "Tap anywhere to dismiss",                            accent: Theme.mauve  },
    ]

    readonly property int totalFeatures: features.length - 2
    property int  step:   0
    property bool paused: false

    function closePopup() {
        Quickshell.execDetached(["bash", "-c", "echo 'close' > /tmp/qs_widget_state"])
    }

    function advance() {
        if (step >= features.length - 1) { closePopup(); return }
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

    Component.onCompleted: {
        step = 0
        paused = false
        autoAdvance.restart()
    }

    Timer {
        id: autoAdvance
        interval: 3500
        repeat:   false
        running:  false
        onTriggered: root.advance()
    }

    // ── Dimmed full-screen backdrop — click to close ──────────────────────────
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.55)

        MouseArea {
            anchors.fill: parent
            onClicked: root.closePopup()
        }
    }

    // ── Card ──────────────────────────────────────────────────────────────────
    Rectangle {
        id: card
        anchors.centerIn: parent
        width:  s(680)
        height: s(460)
        radius: s(28)
        color:  Qt.rgba(Theme.base.r, Theme.base.g, Theme.base.b, 0.97)
        border.width: 1
        border.color: Qt.rgba(Theme.surface1.r, Theme.surface1.g, Theme.surface1.b, 0.5)

        // Capture clicks — prevent backdrop close when clicking inside card
        MouseArea {
            anchors.fill: parent
            onClicked: function(mouse) {
                if (mouse.x < card.width * 0.28) {
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

        // ── Progress dots ────────────────────────────────────────────────────
        Row {
            anchors.top:              parent.top
            anchors.topMargin:        s(20)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: s(6)

            Repeater {
                model: root.features.length
                delegate: Rectangle {
                    property bool isActive: index === root.step
                    width:  isActive ? s(20) : s(5)
                    height: s(5)
                    radius: s(3)
                    color:  isActive
                        ? root.features[root.step].accent
                        : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.18)
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on width { NumberAnimation { duration: 280; easing.type: Easing.OutExpo } }
                    Behavior on color { ColorAnimation  { duration: 250 } }
                }
            }
        }

        // ── Pause indicator ──────────────────────────────────────────────────
        Text {
            anchors.bottom:       parent.bottom
            anchors.bottomMargin: s(16)
            anchors.right:        parent.right
            anchors.rightMargin:  s(24)
            text:    "⏸"
            font.pixelSize: s(13)
            color:   Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.4)
            opacity: root.paused ? 1.0 : 0.0
            visible: opacity > 0.001
            Behavior on opacity { NumberAnimation { duration: 180 } }
        }

        // ── Slides ───────────────────────────────────────────────────────────
        Item {
            anchors.fill:         parent
            anchors.topMargin:    s(44)
            anchors.bottomMargin: s(20)
            clip: true

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
                        y: slide.isCurrent ? 0 : s(16)
                        Behavior on y {
                            NumberAnimation { duration: 400; easing.type: Easing.OutExpo }
                        }
                    }

                    Column {
                        anchors.centerIn: parent
                        width:   card.width - s(80)
                        spacing: s(16)

                        // Icon — feature slides only
                        Item {
                            width:   parent.width
                            height:  s(80)
                            visible: slide.feat.icon !== ""

                            // Soft glow (oversized, low opacity)
                            Text {
                                anchors.centerIn: parent
                                text:           slide.feat.icon
                                font.family:    "Iosevka Nerd Font"
                                font.pixelSize: s(80)
                                color:          slide.feat.accent
                                opacity:        0.18
                            }
                            // Sharp icon
                            Text {
                                anchors.centerIn: parent
                                text:           slide.feat.icon
                                font.family:    "Iosevka Nerd Font"
                                font.pixelSize: s(56)
                                color:          slide.feat.accent
                            }
                        }

                        // Title
                        Text {
                            width:               parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text:                slide.feat.title
                            font.family:  (slide.feat.id === "intro" || slide.feat.id === "outro") ? Theme.fontDisplay : Theme.fontUI
                            font.pixelSize: (slide.feat.id === "intro" || slide.feat.id === "outro") ? s(58) : s(28)
                            font.weight:  (slide.feat.id === "intro" || slide.feat.id === "outro") ? Font.Thin : Font.Bold
                            font.italic:  slide.feat.id === "intro" || slide.feat.id === "outro"
                            color: (slide.feat.id === "intro" || slide.feat.id === "outro")
                                ? slide.feat.accent : Theme.text

                            SequentialAnimation on opacity {
                                running: (slide.feat.id === "intro" || slide.feat.id === "outro")
                                         && slide.isCurrent && !Theme.reduceMotion
                                loops:   Animation.Infinite
                                NumberAnimation { from: 0.55; to: 1.0;  duration: 1900; easing.type: Easing.InOutSine }
                                NumberAnimation { from: 1.0;  to: 0.55; duration: 1900; easing.type: Easing.InOutSine }
                            }
                        }

                        // Description
                        Text {
                            width:               parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text:                slide.feat.sub
                            font.family:         Theme.fontUI
                            font.pixelSize:      s(15)
                            font.weight:         Font.Light
                            color:               Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.58)
                            wrapMode:            Text.WordWrap
                            lineHeight:          1.45
                        }

                        // Step counter
                        Text {
                            width:               parent.width
                            horizontalAlignment: Text.AlignHCenter
                            visible:             slide.feat.id !== "intro" && slide.feat.id !== "outro"
                            text:                index + " / " + root.totalFeatures
                            font.family:         Theme.fontMono
                            font.pixelSize:      s(11)
                            color:               Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.28)
                        }

                        // Tap hint — intro only
                        Text {
                            width:               parent.width
                            horizontalAlignment: Text.AlignHCenter
                            visible:             slide.feat.id === "intro"
                            text:                "tap to begin  →"
                            font.family:         Theme.fontUI
                            font.pixelSize:      s(13)
                            color:               Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.4)

                            SequentialAnimation on opacity {
                                running: slide.isCurrent && !Theme.reduceMotion
                                loops:   Animation.Infinite
                                NumberAnimation { from: 0.2; to: 0.85; duration: 1100; easing.type: Easing.InOutSine }
                                NumberAnimation { from: 0.85; to: 0.2; duration: 1100; easing.type: Easing.InOutSine }
                            }
                        }
                    }
                }
            }
        }
    }
}
