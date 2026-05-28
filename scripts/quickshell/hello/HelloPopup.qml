import QtQuick
import QtQuick.Layouts
import Quickshell
import QtQuick.Effects
import "../"
import "../themes"

// HelloPopup — Apple-grade onboarding for ActivSpot.
// 12 slides (intro + 10 feature previews + outro).  Each feature slide hosts
// a small live preview of the actual feature, animated.  Pure ActivSpot tokens
// — no glass, solid Theme.base card, mauve→blue accent gradient, JetBrains Mono.

Item {
    id: root

    Scaler { id: scaler; currentWidth: Screen.width }
    function s(v) { return scaler.s(v) }


    // ── Feature catalog ───────────────────────────────────────────────────────
    readonly property var features: [
        { id: "intro",   kind: "hero", title: "hello.",          sub: "A new shape for your desktop.",                                accent: Theme.mauve  },
        { id: "clock",   kind: "feat", title: "Clock & Weather", sub: "Flip-digit time. Live, animated weather right where you look.", accent: Theme.blue   },
        { id: "music",   kind: "feat", title: "Music",           sub: "A full player, equalizer and Cava visualizer — built in.",     accent: Theme.green  },
        { id: "notifs",  kind: "feat", title: "Notifications",   sub: "Inline alerts. No modals. No interruption.",                   accent: Theme.yellow },
        { id: "timer",   kind: "feat", title: "Focus Timer",     sub: "Pomodoro, countdown and stopwatch — always one glance away.",  accent: Theme.peach  },
        { id: "stash",   kind: "feat", title: "File Stash",      sub: "Drop anything onto the island. Find it instantly.",            accent: Theme.teal   },
        { id: "vol",     kind: "feat", title: "Volume Drag",     sub: "An elastic gesture to set volume — the pill stretches.",       accent: Theme.pink   },
        { id: "bubbles", kind: "feat", title: "Minibubbles",     sub: "Floating status pills, always in sight beside the island.",    accent: Theme.mauve  },
        { id: "bar",     kind: "feat", title: "Top Bar",         sub: "A customizable applet row across the top of your screen.",     accent: Theme.blue   },
        { id: "discord", kind: "feat", title: "Discord",         sub: "Call timer and mute status, right in the island.",             accent: Theme.blue   },
        { id: "themes",  kind: "feat", title: "Six Themes",      sub: "mocha · nord · apple · carbon · midnight · matugen",           accent: Theme.red    },
        { id: "outro",   kind: "hero", title: "it's all yours.", sub: "Press SUPER + H anytime to reopen this guide.",              accent: Theme.mauve  },
    ]

    property int  step:   0
    property bool paused: false

    function closePopup() {
        Quickshell.execDetached(["bash", "-c", "echo 'close' > /tmp/qs_widget_state"])
    }
    function advance() {
        if (step >= features.length - 1) { closePopup(); return }
        step++; paused = false; autoAdvance.restart()
    }
    function goBack() { if (step > 0) { step--; paused = false; autoAdvance.restart() } }
    function jump(i) { if (i !== step) { step = i; paused = false; autoAdvance.restart() } }

    Component.onCompleted: { step = 0; paused = false; autoAdvance.restart() }

    Timer {
        id: autoAdvance
        interval: 5200
        repeat:   false
        running:  false
        onTriggered: {
            if (root.features[root.step].kind === "hero") return
            if (root.step >= root.features.length - 1) return
            root.advance()
        }
    }

    // Restart auto-advance whenever step changes onto a feature slide.
    onStepChanged: {
        autoAdvance.stop()
        if (features[step].kind === "feat" && !paused) autoAdvance.restart()
    }

    // ── Dimmed backdrop ───────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.5)
        MouseArea { anchors.fill: parent; onClicked: root.closePopup() }
    }

    // ── Card ──────────────────────────────────────────────────────────────────
    Rectangle {
        id: card
        anchors.centerIn: parent
        width:  s(940)
        height: s(680)
        radius: s(30)
        color:  Theme.base
        border.width: 1
        border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.07)

        // Card top hairline accent
        Rectangle {
            anchors.top:   parent.top
            anchors.left:  parent.left
            anchors.right: parent.right
            anchors.leftMargin:  s(30)
            anchors.rightMargin: s(30)
            height: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.5; color: Qt.rgba(Theme.mauve.r, Theme.mauve.g, Theme.mauve.b, 0.4) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        // Card-internal click swallowed so backdrop doesn't dismiss
        MouseArea { anchors.fill: parent; onClicked: {} }

        // ── Skip button (top-right) ───────────────────────────────────────────
        Rectangle {
            id: skipBtn
            anchors.top:   parent.top
            anchors.right: parent.right
            anchors.topMargin:   s(22)
            anchors.rightMargin: s(24)
            width:  skipText.width + s(28)
            height: s(28)
            radius: s(14)
            color:  skipMA.containsMouse ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.03) : "transparent"
            border.width: 1
            border.color: skipMA.containsMouse
                ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.18)
                : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.07)
            visible: root.step < root.features.length - 1
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity   { NumberAnimation { duration: 280 } }
            Behavior on color     { ColorAnimation  { duration: 180 } }
            Behavior on border.color { ColorAnimation { duration: 180 } }

            Text {
                id: skipText
                anchors.centerIn: parent
                text: "SKIP"
                font.family:    Theme.fontMono
                font.pixelSize: s(10)
                font.weight:    Font.Medium
                font.letterSpacing: s(2)
                color: skipMA.containsMouse
                    ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.9)
                    : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.5)
                Behavior on color { ColorAnimation { duration: 180 } }
            }
            MouseArea {
                id: skipMA
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.closePopup()
            }
        }

        // ── Stage (slides) ────────────────────────────────────────────────────
        Item {
            id: stage
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: foot.top
            anchors.topMargin: s(56)
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
                    Behavior on opacity { NumberAnimation { duration: 420; easing.type: Easing.InOutCubic } }

                    transform: [
                        Translate {
                            y: slide.isCurrent ? 0 : s(20)
                            Behavior on y { NumberAnimation { duration: 620; easing.type: Easing.OutExpo } }
                        },
                        Scale {
                            origin.x: slide.width / 2
                            origin.y: slide.height / 2
                            xScale: slide.isCurrent ? 1.0 : 0.985
                            yScale: slide.isCurrent ? 1.0 : 0.985
                            Behavior on xScale { NumberAnimation { duration: 620; easing.type: Easing.OutExpo } }
                            Behavior on yScale { NumberAnimation { duration: 620; easing.type: Easing.OutExpo } }
                        }
                    ]

                    // Hero layout
                    Column {
                        id: heroCol
                        anchors.centerIn: parent
                        spacing: 0
                        visible: slide.feat.kind === "hero"

                        property real revealProgress: 0
                        NumberAnimation {
                            id: revealAnim
                            target: heroCol; property: "revealProgress"
                            from: 0; to: 1; duration: 1600; easing.type: Easing.InOutSine
                        }
                        onVisibleChanged: if (visible) { revealProgress = 0; revealAnim.restart() }
                        Component.onCompleted: if (visible) { revealProgress = 0; revealAnim.restart() }

                        layer.enabled: true
                        layer.effect: MultiEffect {
                            maskEnabled: true
                            maskSource: revealMask
                        }

                        Item {
                            id: revealMask
                            anchors.fill: parent; visible: false
                            layer.enabled: true
                            Rectangle {
                                anchors.fill: parent
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: heroCol.revealProgress - 0.1; color: "white" }
                                    GradientStop { position: heroCol.revealProgress; color: "transparent" }
                                }
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: slide.feat.id === "intro" ? "WELCOME" : "ALL SET"
                            font.family:    Theme.fontMono
                            font.pixelSize: s(10)
                            font.weight:    Font.Bold
                            font.letterSpacing: s(3.6)
                            color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.4)
                            transform: Translate {
                                y: slide.isCurrent ? 0 : s(8)
                                Behavior on y { NumberAnimation { duration: 720; easing.type: Easing.OutExpo; } }
                            }
                            bottomPadding: s(22)
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: slide.feat.title
                            font.family:    Theme.fontMono
                            font.pixelSize: s(80)
                            font.weight:    Font.Light
                            font.italic:    true
                            font.letterSpacing: s(-3)
                            color: slide.feat.accent
                            bottomPadding: s(26)
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: slide.feat.sub
                            font.family:    Theme.fontMono
                            font.pixelSize: s(17)
                            color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.55)
                            transform: Translate {
                                y: slide.isCurrent ? 0 : s(8)
                                Behavior on y { NumberAnimation { duration: 720; easing.type: Easing.OutExpo } }
                            }
                        }
                    }

                    // Feature layout
                    Column {
                        anchors.centerIn: parent
                        spacing: s(40)
                        visible: slide.feat.kind === "feat"

                        // Preview frame — loads a Component per feature id.
                        Item {
                            id: previewFrame
                            width:  Math.max(previewLoader.implicitWidth, s(380))
                            height: previewLoader.implicitHeight
                            anchors.horizontalCenter: parent.horizontalCenter
                            transform: Scale {
                                origin.x: previewFrame.width / 2
                                origin.y: previewFrame.height / 2
                                xScale: slide.isCurrent ? 1.0 : 0.96
                                yScale: slide.isCurrent ? 1.0 : 0.96
                                Behavior on xScale { NumberAnimation { duration: 720; easing.type: Easing.OutExpo } }
                                Behavior on yScale { NumberAnimation { duration: 720; easing.type: Easing.OutExpo } }
                            }

                            Loader {
                                id: previewLoader
                                anchors.centerIn: parent
                                active: slide.isCurrent
                                sourceComponent: {
                                    switch (slide.feat.id) {
                                        case "clock":   return clockPreview
                                        case "music":   return musicPreview
                                        case "notifs":  return notifsPreview
                                        case "timer":   return timerPreview
                                        case "stash":   return stashPreview
                                        case "vol":     return volumePreview
                                        case "bubbles": return bubblesPreview
                                        case "bar":     return barPreview
                                        case "discord": return discordPreview
                                        case "themes":  return themesPreview
                                    }
                                    return null
                                }
                            }
                        }

                        // Feature title + sub
                        Column {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: s(12)

                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: s(10)
                                Text {
                                    text: "—"
                                    font.family:    Theme.fontMono
                                    font.pixelSize: s(32)
                                    font.weight:    Font.Bold
                                    color: slide.feat.accent
                                    opacity: 0.7
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: slide.feat.title
                                    font.family:    Theme.fontMono
                                    font.pixelSize: s(32)
                                    font.weight:    Font.Bold
                                    font.letterSpacing: s(-0.6)
                                    color: Theme.text
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: slide.feat.sub
                                font.family:    Theme.fontMono
                                font.pixelSize: s(14)
                                color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.55)
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                                width: Math.min(s(600), card.width - s(120))
                            }
                        }
                    }
                }
            }
        }

        // ── Footer (back · dots · cta) ────────────────────────────────────────
        Item {
            id: foot
            anchors.bottom: parent.bottom
            anchors.left:   parent.left
            anchors.right:  parent.right
            height: s(80)

            // Hairline above footer
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: s(30)
                anchors.rightMargin: s(30)
                height: 1
                color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.05)
            }

            // Back
            Item {
                id: backBtn
                anchors.left: parent.left
                anchors.leftMargin: s(24)
                anchors.verticalCenter: parent.verticalCenter
                width: s(108); height: s(36)
                opacity: root.step === 0 ? 0.0 : 1.0
                Behavior on opacity { NumberAnimation { duration: 220 } }

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: backMA.containsMouse ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.04) : "transparent"
                    Behavior on color { ColorAnimation { duration: 180 } }
                }
                Row {
                    anchors.centerIn: parent
                    spacing: s(6)
                    Text {
                        text: "\u{F0141}"  // arrow_left nerd font
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: s(16)
                        color: backMA.containsMouse
                            ? Theme.text
                            : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.5)
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on color { ColorAnimation { duration: 180 } }
                    }
                    Text {
                        text: "Back"
                        font.family:    Theme.fontMono
                        font.pixelSize: s(12)
                        font.weight:    Font.Medium
                        color: backMA.containsMouse
                            ? Theme.text
                            : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.5)
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on color { ColorAnimation { duration: 180 } }
                    }
                }
                MouseArea {
                    id: backMA
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: root.step > 0
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: root.goBack()
                }
            }

            // Progress dots (centered)
            Row {
                anchors.centerIn: parent
                spacing: s(6)
                Repeater {
                    model: root.features.length
                    delegate: Rectangle {
                        property bool isActive: index === root.step
                        width:  isActive ? s(22) : s(6)
                        height: s(6)
                        radius: s(3)
                        color:  isActive
                            ? root.features[root.step].accent
                            : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.18)
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
                        Behavior on color { ColorAnimation  { duration: 220 } }
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: s(-4)
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.jump(index)
                        }
                    }
                }
            }

            // CTA pill (gradient mauve→blue, with shine)
            Rectangle {
                id: ctaBtn
                anchors.right: parent.right
                anchors.rightMargin: s(24)
                anchors.verticalCenter: parent.verticalCenter
                width:  s(168); height: s(40)
                radius: height / 2
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: root.features[root.step].accent }
                    GradientStop { position: 1.0; color: Theme.blue }
                }
                transform: Translate {
                    y: ctaMA.containsMouse ? -1 : 0
                    Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutExpo } }
                }
                scale: ctaMA.pressed ? 0.98 : 1.0
                Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutExpo } }

                layer.enabled: true
                layer.effect: MultiEffect { 
                    maskEnabled: true
                    maskSource: ctaBtn
                    maskThresholdMin: 0.5
                }
                // Shine sweep
                Item {
                    anchors.fill: parent
                    
                    Rectangle {
                        id: shine
                        height: parent.height
                        width:  parent.width * 0.6
                        opacity: 0.35
                        rotation: 10
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 0.5; color: "#ffffff" }
                            GradientStop { position: 1.0; color: "transparent" }
                        }
                        x: -width
                        NumberAnimation on x {
                            from: -shine.width
                            to:   ctaBtn.width + shine.width
                            duration: 1400
                            loops: Animation.Infinite
                            easing.type: Easing.InOutCubic
                        }
                    }
                    
                }

                Row {
                    anchors.centerIn: parent
                    spacing: s(6)
                    Text {
                        text: root.step === 0
                            ? "Get Started"
                            : (root.step === root.features.length - 1 ? "Done" : "Continue")
                        font.family:    Theme.fontMono
                        font.pixelSize: s(13)
                        font.weight:    Font.Bold
                        color: "#1a1228"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: root.step === root.features.length - 1 ? "\u{F012C}" : "\u{F0142}"  // check / arrow_right
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: s(16)
                        color: "#1a1228"
                        anchors.verticalCenter: parent.verticalCenter
                    }

                }

                MouseArea {
                    id: ctaMA
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.step === root.features.length - 1) root.closePopup()
                        else root.advance()
                    }
                }
            }
        }
    }

    // ── Feature preview Components ────────────────────────────────────────────

    // 1. Clock & Weather
    Component {
        id: clockPreview
        Column {
            id: clockRoot
            spacing: s(22)
            property string nowText: "11:17:42"

            Timer {
                interval: 1000; repeat: true; running: true
                onTriggered: {
                    var d = new Date()
                    var hh = (d.getHours()   < 10 ? "0" : "") + d.getHours()
                    var mm = (d.getMinutes() < 10 ? "0" : "") + d.getMinutes()
                    var ss = (d.getSeconds() < 10 ? "0" : "") + d.getSeconds()
                    clockRoot.nowText = hh + ":" + mm + ":" + ss
                }
            }

            // Collapsed pill
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: s(290); height: s(38); radius: height / 2
                color: Theme.surface0
                border.width: 1; border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08)
                Row {
                    anchors.centerIn: parent
                    spacing: s(10)
                    Text { text: clockRoot.nowText.substring(0,5); color: Theme.text;
                           font.family: Theme.fontMono; font.pixelSize: s(13); font.weight: Font.Black }
                    Text { text: "Tue, Apr 07"; color: Qt.rgba(Theme.subtext0.r, Theme.subtext0.g, Theme.subtext0.b, 1); font.family: Theme.fontMono; font.pixelSize: s(10) }
                    Rectangle { width: 1; height: s(14); color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.1) }
                    Text { text: "☁"; font.pixelSize: s(16); color: Theme.mauve }
                    Text { text: "4.9°C"; color: Theme.peach; font.family: Theme.fontMono; font.pixelSize: s(12); font.weight: Font.Black }
                }
            }

            // Expanded card
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: s(320); height: s(180); radius: s(22); color: Theme.surface0
                Column {
                    anchors.centerIn: parent
                    spacing: s(6)
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: clockRoot.nowText
                        font.family:    Theme.fontMono
                        font.pixelSize: s(48)
                        font.weight:    Font.Black
                        font.letterSpacing: s(-2)
                        color: Theme.text
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Tuesday, April 07"
                        font.family: Theme.fontMono; font.pixelSize: s(12)
                        color: Theme.subtext0
                    }
                    Rectangle { width: s(260); height: 1; color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.06); anchors.horizontalCenter: parent.horizontalCenter }
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: s(14)
                        Text { text: "☁"; font.pixelSize: s(30); color: Theme.mauve; anchors.verticalCenter: parent.verticalCenter }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            Text { text: "4.9°C"; color: Theme.peach; font.family: Theme.fontMono; font.pixelSize: s(22); font.weight: Font.Black }
                            Text { text: "CLEAR SKY"; color: Theme.subtext0; font.family: Theme.fontMono; font.pixelSize: s(10); font.letterSpacing: s(0.8) }
                        }
                    }
                }
            }
        }
    }

    // 2. Music
    Component {
        id: musicPreview
        Rectangle {
            id: musicRoot
            width: s(380); height: s(160); radius: s(22); color: Theme.surface0
            property real progress: 36

            Timer { interval: 250; repeat: true; running: true
                    onTriggered: musicRoot.progress = (musicRoot.progress + 0.6) % 100 }

            Column {
                anchors.fill: parent; anchors.margins: s(20); spacing: s(14)

                Row {
                    spacing: s(14); width: parent.width
                    Rectangle {
                        width: s(72); height: s(72); radius: s(12)
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: Theme.mauve }
                            GradientStop { position: 1.0; color: Theme.blue }
                        }
                    }
                    Column {
                        width: parent.width - s(86); spacing: s(4)
                        Text { text: "I Don't Care"; font.family: Theme.fontMono; font.pixelSize: s(15); font.weight: Font.Black; color: Theme.text }
                        Text { text: "VIOLENT VIRA"; font.family: Theme.fontMono; font.pixelSize: s(11); font.letterSpacing: s(0.9); color: Theme.subtext0 }
                        Rectangle {
                            width: parent.width; height: s(4); radius: s(2)
                            color: Theme.surface0
                            Rectangle {
                                width: parent.width * (musicRoot.progress / 100); height: parent.height; radius: parent.radius
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: Theme.mauve }
                                    GradientStop { position: 1.0; color: Theme.blue }
                                }
                            }
                        }
                    }
                }

                Row {
                    spacing: s(18); width: parent.width
                    Item { width: parent.width - s(160); height: s(44) }  // spacer

                    Rectangle { width: s(36); height: s(36); radius: s(18); color: Qt.rgba(Theme.surface0.r, Theme.surface0.g, Theme.surface0.b, 0.7); anchors.verticalCenter: parent.verticalCenter
                                Text { anchors.centerIn: parent; text: "◀◀"; color: Theme.text; font.pixelSize: s(11) } }

                    Rectangle {
                        width: s(44); height: s(44); radius: s(22); color: Theme.mauve
                        anchors.verticalCenter: parent.verticalCenter
                        Text { anchors.centerIn: parent; text: "⏸"; color: Theme.base; font.pixelSize: s(16) }
                        SequentialAnimation on color {
                            loops: Animation.Infinite
                            ColorAnimation { from: Theme.mauve; to: Qt.lighter(Theme.mauve, 1.15); duration: 900 }
                            ColorAnimation { from: Qt.lighter(Theme.mauve, 1.15); to: Theme.mauve; duration: 900 }
                        }
                    }

                    Rectangle { width: s(36); height: s(36); radius: s(18); color: Qt.rgba(Theme.surface0.r, Theme.surface0.g, Theme.surface0.b, 0.7); anchors.verticalCenter: parent.verticalCenter
                                Text { anchors.centerIn: parent; text: "▶▶"; color: Theme.text; font.pixelSize: s(11) } }
                }
            }
        }
    }

    // 3. Notifications
    Component {
        id: notifsPreview
        Column {
            spacing: s(8)
            Repeater {
                model: [
                    { app: "Discord", title: "Message in #general",      body: "dxvmxn: hey are you free?",  accent: Theme.mauve,  initial: "D" },
                    { app: "System",  title: "Package update available", body: "hyprland 0.45.0",            accent: Theme.blue,   initial: "S" },
                    { app: "Build",   title: "Compilation succeeded",    body: "quickshell · 4.2s",          accent: Theme.green,  initial: "B" }
                ]
                delegate: Rectangle {
                    id: notifItem
                    required property var modelData
                    required property int index

                    width: s(380); height: s(54); radius: s(14)
                    color: Theme.surface0
                    border.width: 1
                    border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.06)

                    property real entryX: s(32)
                    SequentialAnimation {
                        running: true
                        PauseAnimation { duration: 200 + index * 100 }
                        NumberAnimation {
                            target: notifItem; property: "entryX"
                            from: s(32); to: 0; duration: 720
                            easing.type: Easing.OutExpo
                        }
                    }
                    transform: Translate { x: entryX }

                    Row {
                        anchors.fill: parent; anchors.margins: s(10); spacing: s(10)
                        Rectangle {
                            width: s(3); height: parent.height - s(12); radius: s(2)
                            color: notifItem.modelData.accent
                            opacity: 0.85
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Rectangle {
                            width: s(32); height: s(32); radius: s(9)
                            color: Qt.rgba(parent.parent.modelData.accent.r, parent.parent.modelData.accent.g, parent.parent.modelData.accent.b, 0.12)
                            anchors.verticalCenter: parent.verticalCenter
                            Text {
                                anchors.centerIn: parent
                                text: parent.parent.parent.modelData.initial
                                color: parent.parent.parent.modelData.accent
                                font.family: Theme.fontMono; font.pixelSize: s(14); font.weight: Font.Black
                            }
                        }
                        Column {
                            width: parent.width - s(80)
                            spacing: s(2)
                            anchors.verticalCenter: parent.verticalCenter
                            Text {
                                text: parent.parent.parent.modelData.app + " · " + parent.parent.parent.modelData.title
                                color: Theme.text
                                font.family: Theme.fontMono; font.pixelSize: s(11); font.weight: Font.Bold
                                elide: Text.ElideRight; width: parent.width
                            }
                            Text {
                                text: parent.parent.parent.modelData.body
                                color: Theme.subtext0
                                font.family: Theme.fontMono; font.pixelSize: s(10)
                                elide: Text.ElideRight; width: parent.width
                            }
                        }
                    }
                }
            }
        }
    }

    // 4. Focus Timer
    Component {
        id: timerPreview
        Item {
            id: timerItem
            width:  s(220); height: s(220)
            property real progress: 1.0

            Timer { interval: 200; repeat: true; running: true
                    onTriggered: timerItem.progress = Math.max(0, timerItem.progress - (1 / (25 * 60 * 5))) }

            onProgressChanged: timerCanvas.requestPaint()

            Canvas {
                id: timerCanvas
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.reset()
                    var cx = width / 2, cy = height / 2, r = s(78)
                    // bg disc
                    ctx.fillStyle = Theme.surface0
                    ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI*2); ctx.fill()
                    // track
                    ctx.strokeStyle = Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.05)
                    ctx.lineWidth = s(10)
                    ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI*2); ctx.stroke()
                    // progress
                    var grad = ctx.createLinearGradient(0, 0, width, height)
                    grad.addColorStop(0, Theme.peach)
                    grad.addColorStop(1, Theme.mauve)
                    ctx.strokeStyle = grad
                    ctx.lineWidth = s(10); ctx.lineCap = "round"
                    ctx.beginPath(); ctx.arc(cx, cy, r, -Math.PI/2, -Math.PI/2 + 2*Math.PI * timerItem.progress); ctx.stroke()
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: s(4)
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: {
                        var totalSecs = Math.floor(timerItem.progress * 25 * 60)
                        var m = Math.floor(totalSecs / 60), ss = totalSecs % 60
                        return (m < 10 ? "0" : "") + m + ":" + (ss < 10 ? "0" : "") + ss
                    }
                    color: Theme.text
                    font.family: Theme.fontMono; font.pixelSize: root.s(38); font.weight: Font.Black; font.letterSpacing: root.s(-1)
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "FOCUS"; color: Theme.peach
                    font.family: Theme.fontMono; font.pixelSize: root.s(10); font.letterSpacing: root.s(1.8)
                }
            }
        }
    }

    // 5. File Stash
    Component {
        id: stashPreview
        Row {
            spacing: s(12)
            Repeater {
                model: [
                    { kind: "IMG", color: Theme.mauve, label: "logo.svg" },
                    { kind: "DOC", color: Theme.blue,  label: "README"   },
                    { kind: "ZIP", color: Theme.peach, label: "build.zip"},
                    { kind: "IMG", color: Theme.teal,  label: "wall.jpg" }
                ]
                delegate: Rectangle {
                    id: stashItem
                    required property var modelData
                    required property int index
                    width: s(88); height: s(110); radius: s(14); color: Theme.surface1
                    border.width: 1; border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.07)

                    property real entryY: s(32)
                    SequentialAnimation {
                        running: true
                        PauseAnimation { duration: 200 + index * 100 }
                        NumberAnimation {
                            target: stashItem; property: "entryY"
                            from: s(32); to: 0; duration: 720
                            easing.type: Easing.OutExpo
                        }
                    }
                    transform: Translate { y: entryY }

                    Column {
                        anchors.fill: parent; anchors.margins: s(10); spacing: s(8)
                        Rectangle {
                            width: parent.width; height: parent.height - s(24); radius: s(8)
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: stashItem.modelData.color }
                                GradientStop { position: 1.0; color: Qt.rgba(stashItem.modelData.color.r,
                                 stashItem.modelData.color.g,
                                 stashItem.modelData.color.b, 0.25) }
                            }
                            Text {
                                anchors.centerIn: parent
                                text: parent.parent.parent.modelData.kind
                                color: Theme.base; font.family: Theme.fontMono; font.pixelSize: root.s(11); font.weight: Font.Black
                            }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: parent.parent.modelData.label
                            color: Theme.subtext0; font.family: Theme.fontMono; font.pixelSize: root.s(9)
                        }
                    }
                }
            }
        }
    }

    // 6. Volume Drag
    Component {
        id: volumePreview
        Column {
            id: volRoot
            spacing: s(18)
            property real v: 0.6
            property real t: 0
            Timer { interval: 50; repeat: true; running: true
                    onTriggered: { volRoot.t += 0.04; volRoot.v = 0.6 + 0.22 * Math.sin(volRoot.t) } }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: s(320) + (parent.v - 0.5) * s(40); height: s(42); radius: height / 2
                color: Theme.surface0
                border.width: 1; border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08)
                Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutExpo } }

                Row {
                    anchors.fill: parent; anchors.leftMargin: s(16); anchors.rightMargin: s(16); spacing: s(12)
                    Text { text: volRoot.v > 0.05 ? "" : ""; color: Theme.pink; font.pixelSize: s(17); anchors.verticalCenter: parent.verticalCenter }
                    Rectangle {
                        width: parent.width - s(80); height: s(6); radius: s(3)
                        color: Theme.surface0
                        anchors.verticalCenter: parent.verticalCenter
                        Rectangle {
                            width: parent.width * volRoot.v; height: parent.height; radius: parent.radius
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: Theme.mauve }
                                GradientStop { position: 1.0; color: Theme.pink }
                            }
                            Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutExpo } }
                        }
                    }
                    Text {
                        text: Math.round(volRoot.v * 100) + "%"; color: Theme.text
                        font.family: Theme.fontMono; font.pixelSize: s(12); font.weight: Font.Black
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "DRAG TO ADJUST"
                color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.4)
                font.family: Theme.fontMono; font.pixelSize: s(10); font.letterSpacing: s(1.8)
            }
        }
    }

    // 7. Minibubbles
    Component {
        id: bubblesPreview
        Item {
            id: bubblesRoot
            width: s(540); height: s(140)

            // Center island pill
            Rectangle {
                id: islandPill
                x: bubblesRoot.width / 2 - width / 2
                width: s(210); height: s(38); radius: height / 2
                color: Theme.surface0
                border.width: 1; border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08)
                SequentialAnimation on y {
                    loops: Animation.Infinite
                    NumberAnimation { from: bubblesRoot.height / 2 - islandPill.height / 2;     to: bubblesRoot.height / 2 - islandPill.height / 2 - 2; duration: 1800; easing.type: Easing.InOutSine }
                    NumberAnimation { from: bubblesRoot.height / 2 - islandPill.height / 2 - 2; to: bubblesRoot.height / 2 - islandPill.height / 2;     duration: 1800; easing.type: Easing.InOutSine }
                }
                Row {
                    anchors.centerIn: parent; spacing: s(10)
                    Text { text: "11:17"; color: Theme.text; font.family: Theme.fontMono; font.pixelSize: s(13); font.weight: Font.Black }
                    Text { text: "Tue, Apr 07"; color: Theme.subtext0; font.family: Theme.fontMono; font.pixelSize: s(10) }
                    Text { text: "☁"; color: Theme.mauve; font.pixelSize: s(14) }
                    Text { text: "5°"; color: Theme.peach; font.family: Theme.fontMono; font.pixelSize: s(11); font.weight: Font.Black }
                }
            }

            // Bubbles
            Repeater {
                model: [
                    { label: "BAT",  sub: "82%", dot: Theme.green, side: -1, slot: 1 },
                    { label: "WIFI", sub: "5G",  dot: Theme.blue,  side: -1, slot: 0 },
                    { label: "BT",   sub: "",    dot: Theme.mauve, side:  1, slot: 0 },
                    { label: "VOL",  sub: "62%", dot: Theme.pink,  side:  1, slot: 1 }
                ]
                delegate: Rectangle {
                    id: bubbleItem
                    required property var modelData
                    required property int index
                    height: s(28); radius: height / 2
                    color: Theme.surface0
                    border.width: 1; border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08)
                    width: bubbleRow.width + s(22)
                    x: bubblesRoot.width / 2 + modelData.side * (root.s(105) + (modelData.slot + 1) * root.s(96)) - width / 2

                    SequentialAnimation on y {
                        loops: Animation.Infinite
                        NumberAnimation { from: bubblesRoot.height / 2 - bubbleItem.height / 2;     duration: 1600 + index * 100; easing.type: Easing.InOutSine; to: bubblesRoot.height / 2 - bubbleItem.height / 2 - 3 }
                        NumberAnimation { from: bubblesRoot.height / 2 - bubbleItem.height / 2 - 3; duration: 1600 + index * 100; easing.type: Easing.InOutSine; to: bubblesRoot.height / 2 - bubbleItem.height / 2 }
                    }

                    Row {
                        id: bubbleRow
                        anchors.centerIn: parent
                        spacing: s(6)
                        Rectangle { width: s(6); height: s(6); radius: s(3); color: modelData.dot; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: modelData.label; color: Theme.text; font.family: Theme.fontMono; font.pixelSize: s(10); font.weight: Font.Black; font.letterSpacing: s(0.6); anchors.verticalCenter: parent.verticalCenter }
                        Text { text: modelData.sub; color: Theme.subtext0; font.family: Theme.fontMono; font.pixelSize: s(9); anchors.verticalCenter: parent.verticalCenter; visible: text.length > 0 }
                    }
                }
            }
        }
    }

    // 8. Top Bar
    Component {
        id: barPreview
        Rectangle {
            width: s(520); height: s(50); radius: s(14); color: Theme.surface0
            Row {
                anchors.fill: parent; anchors.leftMargin: s(14); anchors.rightMargin: s(14); spacing: s(12)

                // workspaces
                Rectangle { height: s(30); radius: height/2; color: Qt.rgba(Theme.surface0.r, Theme.surface0.g, Theme.surface0.b, 0.55); border.width: 1; border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.05); width: s(78); anchors.verticalCenter: parent.verticalCenter
                    Row { anchors.centerIn: parent; spacing: s(4)
                        Repeater { model: 4
                            delegate: Rectangle { width: index === 1 ? s(16) : s(6); height: s(6); radius: s(3); color: index === 1 ? Theme.mauve : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.25); anchors.verticalCenter: parent.verticalCenter } }
                    }
                }
                // keyboard
                Rectangle { height: s(30); radius: height/2; color: Qt.rgba(Theme.surface0.r, Theme.surface0.g, Theme.surface0.b, 0.55); border.width: 1; border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.05); width: s(40); anchors.verticalCenter: parent.verticalCenter
                    Text { anchors.centerIn: parent; text: "EN"; color: Theme.subtext0; font.family: Theme.fontMono; font.pixelSize: s(10); font.weight: Font.Black } }

                Item { width: parent.width - s(360); height: 1 }

                // wifi
                Rectangle { height: s(30); radius: height/2; color: Qt.rgba(Theme.surface0.r, Theme.surface0.g, Theme.surface0.b, 0.55); border.width: 1; border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.05); width: s(56); anchors.verticalCenter: parent.verticalCenter
                    Row { anchors.centerIn: parent; spacing: s(6)
                        Text { text: "◢"; color: Theme.blue; font.pixelSize: s(11); anchors.verticalCenter: parent.verticalCenter }
                        Text { text: "5G"; color: Theme.text; font.family: Theme.fontMono; font.pixelSize: s(10); font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter } } }
                // battery
                Rectangle { height: s(30); radius: height/2; color: Qt.rgba(Theme.surface0.r, Theme.surface0.g, Theme.surface0.b, 0.55); border.width: 1; border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.05); width: s(62); anchors.verticalCenter: parent.verticalCenter
                    Row { anchors.centerIn: parent; spacing: s(6)
                        Rectangle { width: s(22); height: s(10); radius: s(2); border.width: 1; border.color: Theme.subtext0; color: "transparent"; anchors.verticalCenter: parent.verticalCenter
                            Rectangle { anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; anchors.margins: 1; width: (parent.width - 2) * 0.82; color: Theme.green; radius: 1 } }
                        Text { text: "82"; color: Theme.text; font.family: Theme.fontMono; font.pixelSize: s(10); font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter } } }
                // tray
                Rectangle { height: s(30); radius: height/2; color: Qt.rgba(Theme.surface0.r, Theme.surface0.g, Theme.surface0.b, 0.55); border.width: 1; border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.05); width: s(34); anchors.verticalCenter: parent.verticalCenter
                    Text { anchors.centerIn: parent; text: "⋯"; color: Theme.subtext0; font.pixelSize: s(14) } }
            }
        }
    }

    // 9. Discord
    Component {
        id: discordPreview
        Rectangle {
            width: s(360); height: s(46); radius: height/2; color: Theme.surface0
            border.width: 1; border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08)
            property int secs: 0
            Timer { interval: 1000; repeat: true; running: true; onTriggered: parent.secs += 1 }

            Row {
                anchors.fill: parent; anchors.leftMargin: s(16); anchors.rightMargin: s(16); spacing: s(12)
                Rectangle {
                    width: s(26); height: s(26); radius: s(8)
                    color: Qt.rgba(Theme.blue.r, Theme.blue.g, Theme.blue.b, 0.18)
                    anchors.verticalCenter: parent.verticalCenter
                    Text { anchors.centerIn: parent; text: "D"; color: Theme.blue; font.family: Theme.fontMono; font.pixelSize: s(13); font.weight: Font.Black }
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: s(1)
                    Text { text: "#general · voice"; color: Theme.blue; font.family: Theme.fontMono; font.pixelSize: s(11); font.weight: Font.Bold }
                    Text {
                        text: {
                            var sec = parent.parent.parent.secs
                            var m = Math.floor(sec / 60), ss = sec % 60
                            return (m < 10 ? "0" : "") + m + ":" + (ss < 10 ? "0" : "") + ss
                        }
                        color: Theme.text; font.family: Theme.fontMono; font.pixelSize: s(12); font.weight: Font.Black
                    }
                }
                Item { width: parent.width - s(220); height: 1; anchors.verticalCenter: parent.verticalCenter }
                Rectangle {
                    width: s(8); height: s(8); radius: s(4); color: Theme.green
                    anchors.verticalCenter: parent.verticalCenter
                    SequentialAnimation on scale {
                        loops: Animation.Infinite
                        NumberAnimation { from: 1.0; to: 1.4; duration: 550; easing.type: Easing.InOutSine }
                        NumberAnimation { from: 1.4; to: 1.0; duration: 550; easing.type: Easing.InOutSine }
                    }
                }
                Rectangle { width: s(30); height: s(30); radius: s(15); color: Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.18); anchors.verticalCenter: parent.verticalCenter
                    Text { anchors.centerIn: parent; text: "🎙"; font.pixelSize: s(12) } }
                Rectangle { width: s(30); height: s(30); radius: s(15); color: Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.18); anchors.verticalCenter: parent.verticalCenter
                    Text { anchors.centerIn: parent; text: "✕"; color: Theme.red; font.pixelSize: s(12) } }
            }
        }
    }

    // 10. Themes
    Component {
        id: themesPreview
        Grid {
            columns: 3
            rowSpacing: s(10); columnSpacing: s(10)
            Repeater {
                model: [
                    { name: "mocha",    bg: Theme.surface0,     a: Theme.mauve,   b: Theme.blue,   c: Theme.peach },
                    { name: "nord",     bg: "#2e3440",          a: "#88c0d0",     b: "#81a1c1",    c: "#a3be8c"   },
                    { name: "apple",    bg: "#f5f5f7",          a: "#007aff",     b: "#34c759",    c: "#ff3b30"   },
                    { name: "carbon",   bg: "#111111",          a: "#d4d4d8",     b: "#60a5fa",    c: "#f0abfc"   },
                    { name: "midnight", bg: "#08080f",          a: "#7c7cf5",     b: "#4fc3f7",    c: "#e879f9"   },
                    { name: "matugen",  bg: "#1a1426",          a: "#d4b1f9",     b: "#f5b8e0",    c: "#ffd4a8"   }
                ]
                delegate: Rectangle {
                    id: themeItem
                    required property var modelData
                    required property int index
                    width: s(120); height: s(62); radius: s(14)
                    color: modelData.bg
                    border.width: 1; border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.06)

                    property real entryY: s(24)
                    SequentialAnimation {
                        running: true
                        PauseAnimation { duration: 200 + index * 80 }
                        NumberAnimation {
                            target: themeItem; property: "entryY"
                            from: s(24); to: 0; duration: 720
                            easing.type: Easing.OutExpo
                        }
                    }
                    transform: Translate { y: entryY }

                    Column {
                        anchors.fill: parent; anchors.margins: s(12); spacing: s(8)
                        Row {
                            width: parent.width; spacing: s(4)
                            Rectangle { width: (parent.width - s(8)) / 3; height: s(18); radius: s(5); color: parent.parent.parent.modelData.a }
                            Rectangle { width: (parent.width - s(8)) / 3; height: s(18); radius: s(5); color: parent.parent.parent.modelData.b }
                            Rectangle { width: (parent.width - s(8)) / 3; height: s(18); radius: s(5); color: parent.parent.parent.modelData.c }
                        }
                        Text { text: parent.parent.modelData.name; color: parent.parent.modelData.name === "apple" ? "#1d1d1f" : Theme.text; font.family: Theme.fontMono; font.pixelSize: s(10); font.weight: Font.Bold; font.letterSpacing: s(0.5) }
                    }
                }
            }
        }
    }

    // ── Keyboard ──────────────────────────────────────────────────────────────
    focus: true
    Keys.onPressed: function(e) {
        if (e.key === Qt.Key_Right || e.key === Qt.Key_Return || e.key === Qt.Key_Space) { root.advance(); e.accepted = true }
        else if (e.key === Qt.Key_Left) { root.goBack(); e.accepted = true }
        else if (e.key === Qt.Key_Escape) { root.closePopup(); e.accepted = true }
    }
}
