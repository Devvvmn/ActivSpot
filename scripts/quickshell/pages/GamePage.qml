import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: root
    property var island
    clip: true

    property int  currentTab: 0
    property bool perfOn:     false
    property bool micMuted:   false

    // ── Session timer ─────────────────────────────────────────────────────
    property string sessionTime: "00:00:00"
    Timer {
        interval: 1000; running: island.gameActive; repeat: true
        onTriggered: {
            var e = Math.max(0, Math.floor(Date.now() / 1000) - island.gameStart)
            var h = Math.floor(e / 3600), m = Math.floor((e % 3600) / 60), s = e % 60
            root.sessionTime = String(h).padStart(2,'0') + ":" + String(m).padStart(2,'0') + ":" + String(s).padStart(2,'0')
        }
    }

    // ── History arrays (40 samples each) ─────────────────────────────────
    property var histFps:  { var a=[]; for(var i=0;i<40;i++) a.push(0); return a; }
    property var histPing: { var a=[]; for(var i=0;i<40;i++) a.push(0); return a; }
    property var histGpu:  { var a=[]; for(var i=0;i<40;i++) a.push(0); return a; }
    property var histCpu:  { var a=[]; for(var i=0;i<40;i++) a.push(0); return a; }
    property var histTemp: { var a=[]; for(var i=0;i<40;i++) a.push(0); return a; }
    Timer {
        interval: 900; running: island.gameActive; repeat: true
        onTriggered: {
            root.histFps  = root.histFps.slice(1).concat([island.gameFps])
            root.histPing = root.histPing.slice(1).concat([island.gamePing])
            root.histGpu  = root.histGpu.slice(1).concat([island.gameGpu])
            root.histCpu  = root.histCpu.slice(1).concat([island.gameCpu])
            root.histTemp = root.histTemp.slice(1).concat([island.gameGpuTemp])
        }
    }

    readonly property color healthColor: {
        if (island.gameFps > 100 && island.gamePing < 22) return island.green
        if (island.gameFps > 60  && island.gamePing < 45) return island.yellow
        return island.red
    }

    // ── Flat stat card component ──────────────────────────────────────────
    component StatCard: Rectangle {
        id: card
        property string statLabel: ""
        property string statUnit:  ""
        property int    statValue: 0
        property color  statColor: "#ffffff"

        radius: island.s(10)
        color: Qt.rgba(0.10, 0.11, 0.14, 0.78)
        border.width: 1
        border.color: Qt.rgba(card.statColor.r, card.statColor.g, card.statColor.b, 0.14)
        Behavior on border.color { ColorAnimation { duration: 400 } }

        Text {
            id: lblText
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: island.s(8)
            text: card.statLabel
            font.family: "JetBrains Mono"
            font.pixelSize: island.s(8)
            font.weight: Font.Black
            font.letterSpacing: island.s(1.0)
            color: Qt.rgba(card.statColor.r, card.statColor.g, card.statColor.b, 0.6)
        }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: island.s(8)
            spacing: island.s(1)
            Text {
                text: card.statValue
                font.family: "JetBrains Mono"
                font.pixelSize: island.s(20)
                font.weight: Font.Black
                color: card.statColor
            }
            Text {
                text: card.statUnit
                font.family: "JetBrains Mono"
                font.pixelSize: island.s(8)
                font.weight: Font.Bold
                color: island.overlay0
                anchors.bottom: parent.bottom
                anchors.bottomMargin: island.s(2)
                visible: text.length > 0
            }
        }
    }

    // ── Line graph component ──────────────────────────────────────────────
    component LineGraph: Item {
        property var   graphVals:  []
        property color graphColor: "#ffffff"
        property real  graphMax:   100
        property var   graphVals2:  []
        property color graphColor2: "#ffffff"
        property real  graphMax2:   100

        Canvas {
            anchors.fill: parent
            property var   v1: parent.graphVals
            property var   v2: parent.graphVals2
            property color c1: parent.graphColor
            property color c2: parent.graphColor2
            onV1Changed: requestPaint()
            onV2Changed: requestPaint()
            onC1Changed: requestPaint()
            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                var W = width, H = height
                function series(vals, col, mx) {
                    if (!vals || vals.length < 2) return
                    var n = vals.length, pad = H * 0.1
                    ctx.beginPath()
                    for (var i = 0; i < n; i++) {
                        var x = (i / (n - 1)) * W
                        var y = H - pad - Math.max(0, Math.min(1, vals[i] / mx)) * (H - pad * 2)
                        if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y)
                    }
                    ctx.strokeStyle = Qt.rgba(col.r, col.g, col.b, 1.0)
                    ctx.lineWidth = 1.5; ctx.lineJoin = "round"; ctx.stroke()
                    ctx.lineTo(W, H); ctx.lineTo(0, H); ctx.closePath()
                    ctx.fillStyle = Qt.rgba(col.r, col.g, col.b, 0.11); ctx.fill()
                }
                series(parent.graphVals,  parent.graphColor,  parent.graphMax)
                series(parent.graphVals2, parent.graphColor2, parent.graphMax2)
            }
        }
    }

    // ── Offscreen mask (rounded corners) ─────────────────────────────────
    Item {
        id: maskShape
        anchors.fill: parent; visible: false; layer.enabled: true
        Rectangle { anchors.fill: parent; radius: island.s(28); color: "white" }
    }

    // ── Background: cover art blur ────────────────────────────────────────
    Item {
        id: bgLayer
        anchors.fill: parent
        Rectangle {
            anchors.fill: parent
            color: island.glassTheme ? Qt.rgba(0.05, 0.05, 0.08, 0) : "#0d0d14"
        }
        Image {
            id: coverImg; source: island.gameCover
            anchors.fill: parent; fillMode: Image.PreserveAspectCrop
            visible: false; asynchronous: true
            opacity: status === Image.Ready ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 600 } }
        }
        MultiEffect {
            source: coverImg; anchors.fill: coverImg
            blurEnabled: true; blurMax: 48; blur: 1.0; opacity: coverImg.opacity
        }
        Rectangle { anchors.fill: parent; color: Qt.rgba(0.04, 0.05, 0.09, 0.58) }
        layer.enabled: true
        layer.effect: MultiEffect { maskEnabled: true; maskSource: maskShape; maskThresholdMin: 0.5 }
    }

    // ── Layout ────────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        anchors.bottomMargin: island.s(68)
        spacing: 0

        // Header
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin:    island.s(14)
            Layout.leftMargin:   island.s(18)
            Layout.rightMargin:  island.s(14)
            Layout.bottomMargin: island.s(6)
            spacing: island.s(10)

            Rectangle {
                width: island.s(6); height: island.s(6); radius: island.s(3)
                color: root.healthColor
                SequentialAnimation on opacity {
                    running: true; loops: Animation.Infinite
                    NumberAnimation { to: 0.2; duration: 650; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 650; easing.type: Easing.InOutSine }
                }
            }

            Column {
                Layout.fillWidth: true
                spacing: island.s(1)
                Text {
                    text: "GAME MODE · LIVE"
                    font.family: "JetBrains Mono"; font.pixelSize: island.s(9); font.weight: Font.Black
                    font.letterSpacing: island.s(1.6); color: root.healthColor
                }
                Text {
                    text: island.gameName || "Unknown Game"
                    font.family: "JetBrains Mono"; font.pixelSize: island.s(15); font.weight: Font.Black
                    color: island.text; elide: Text.ElideRight; width: parent.width
                }
            }

            Column {
                spacing: island.s(1)
                Text {
                    text: "SESSION"; horizontalAlignment: Text.AlignRight; width: parent.width
                    font.family: "JetBrains Mono"; font.pixelSize: island.s(8)
                    color: island.overlay0; font.letterSpacing: island.s(0.8)
                }
                Text {
                    text: root.sessionTime; horizontalAlignment: Text.AlignRight; width: parent.width
                    font.family: "JetBrains Mono"; font.pixelSize: island.s(12); font.weight: Font.Bold
                    color: island.subtext1
                }
            }
        }

        // Tab content
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // ── OVERVIEW ──────────────────────────────────────────────────
            Item {
                anchors.fill: parent
                visible: root.currentTab === 0
                clip: true

                Flickable {
                    anchors.fill: parent
                    contentHeight: ovCol.height; contentWidth: width; clip: true

                    Column {
                        id: ovCol
                        width: parent.width
                        leftPadding: island.s(14); rightPadding: island.s(14)
                        topPadding: island.s(6); bottomPadding: island.s(6)
                        spacing: island.s(8)

                        // Flat stat cards row
                        Row {
                            width: parent.width - island.s(28)
                            height: island.s(58)
                            spacing: island.s(6)

                            Repeater {
                                model: [
                                    { lbl:"FPS",  unt:"",   kind:"fps"  },
                                    { lbl:"PING", unt:"ms", kind:"ping" },
                                    { lbl:"GPU",  unt:"%",  kind:"blue" },
                                    { lbl:"CPU",  unt:"%",  kind:"mauve"},
                                    { lbl:"RAM",  unt:"%",  kind:"teal" },
                                ]
                                delegate: StatCard {
                                    width: (parent.width - island.s(6) * 4) / 5
                                    height: parent.height
                                    statLabel: modelData.lbl
                                    statUnit:  modelData.unt
                                    statValue: {
                                        if (modelData.kind === "fps")   return island.gameFps
                                        if (modelData.kind === "ping")  return island.gamePing
                                        if (modelData.kind === "blue")  return island.gameGpu
                                        if (modelData.kind === "mauve") return island.gameCpu
                                        return island.gameRam
                                    }
                                    statColor: {
                                        if (modelData.kind === "fps")
                                            return statValue > 90 ? island.green : statValue > 45 ? island.yellow : island.red
                                        if (modelData.kind === "ping")
                                            return statValue < 30 ? island.green : statValue < 70 ? island.yellow : island.red
                                        if (modelData.kind === "blue")  return island.blue
                                        if (modelData.kind === "mauve") return island.mauve
                                        return island.teal
                                    }
                                }
                            }
                        }

                        // GPU TEMP + VRAM bars
                        Rectangle {
                            width: parent.width - island.s(28)
                            height: barsInner.height + island.s(20)
                            radius: island.s(10); color: Qt.rgba(0.14,0.15,0.18,0.85)
                            border.width: 1; border.color: "#13141a"
                            Column {
                                id: barsInner
                                anchors { left: parent.left; right: parent.right; top: parent.top; margins: island.s(10) }
                                spacing: 0

                                RowLayout {
                                    width: parent.width; height: island.s(28); spacing: island.s(8)
                                    readonly property color bc: island.gameGpuTemp > 85 ? island.peach : island.teal
                                    Text { text: "GPU TEMP"; Layout.preferredWidth: island.s(64); font.family: "JetBrains Mono"; font.pixelSize: island.s(8); font.weight: Font.Black; font.letterSpacing: island.s(0.6); color: "#6c7086" }
                                    Rectangle { Layout.fillWidth: true; height: island.s(3); radius: island.s(2); color: "#282a2f"
                                        Rectangle { width: parent.width * Math.min(island.gameGpuTemp, 100) / 100; height: parent.height; radius: parent.radius; color: parent.parent.bc; Behavior on width { NumberAnimation { duration: 800; easing.type: Easing.OutCubic } } } }
                                    Text { text: island.gameGpuTemp + "°C"; Layout.preferredWidth: island.s(40); font.family: "JetBrains Mono"; font.pixelSize: island.s(10); font.weight: Font.Bold; color: parent.bc; horizontalAlignment: Text.AlignRight }
                                }
                                Rectangle { width: parent.width; height: 1; color: Qt.rgba(1,1,1,0.04) }
                                RowLayout {
                                    width: parent.width; height: island.s(28); spacing: island.s(8)
                                    Text { text: "VRAM"; Layout.preferredWidth: island.s(64); font.family: "JetBrains Mono"; font.pixelSize: island.s(8); font.weight: Font.Black; font.letterSpacing: island.s(0.6); color: "#6c7086" }
                                    Rectangle { Layout.fillWidth: true; height: island.s(3); radius: island.s(2); color: "#282a2f"
                                        Rectangle { width: parent.width * Math.min(island.gameVram, 100) / 100; height: parent.height; radius: parent.radius; color: island.blue; Behavior on width { NumberAnimation { duration: 800; easing.type: Easing.OutCubic } } } }
                                    Text { text: island.gameVram + "%"; Layout.preferredWidth: island.s(40); font.family: "JetBrains Mono"; font.pixelSize: island.s(10); font.weight: Font.Bold; color: island.blue; horizontalAlignment: Text.AlignRight }
                                }
                            }
                        }
                    }
                }
            }

            // ── GRAPHS ────────────────────────────────────────────────────
            Item {
                anchors.fill: parent
                visible: root.currentTab === 1
                clip: true

                Flickable {
                    anchors.fill: parent
                    contentHeight: grCol.height; contentWidth: width; clip: true

                    Column {
                        id: grCol
                        width: parent.width
                        leftPadding: island.s(14); rightPadding: island.s(14)
                        topPadding: island.s(6); bottomPadding: island.s(6)
                        spacing: island.s(8)

                        // FPS card
                        Rectangle {
                            width: parent.width - island.s(28); radius: island.s(10)
                            color: "#1a1b20"; border.width: 1; border.color: "#23242a"
                            height: grFps.height + island.s(20)
                            Column {
                                id: grFps
                                anchors { left: parent.left; right: parent.right; top: parent.top; margins: island.s(10) }
                                spacing: island.s(6)
                                RowLayout {
                                    width: parent.width
                                    Text { text: island.gameFps + " fps"; font.family: "JetBrains Mono"; font.pixelSize: island.s(11); font.weight: Font.Black; color: root.healthColor }
                                    Item { Layout.fillWidth: true }
                                    Text { text: "FPS"; font.family: "JetBrains Mono"; font.pixelSize: island.s(8); font.weight: Font.Black; color: "#6c7086"; font.letterSpacing: island.s(0.8) }
                                }
                                LineGraph { width: parent.width; height: island.s(46); graphVals: root.histFps; graphColor: root.healthColor; graphMax: 165 }
                            }
                        }

                        // CPU + TEMP card
                        Rectangle {
                            width: parent.width - island.s(28); radius: island.s(10)
                            color: "#1a1b20"; border.width: 1; border.color: "#23242a"
                            height: grCpu.height + island.s(20)
                            Column {
                                id: grCpu
                                anchors { left: parent.left; right: parent.right; top: parent.top; margins: island.s(10) }
                                spacing: island.s(6)
                                RowLayout {
                                    width: parent.width
                                    Text { text: island.gameCpu + "%"; font.family: "JetBrains Mono"; font.pixelSize: island.s(11); font.weight: Font.Black; color: island.mauve }
                                    Text { text: "· " + island.gameGpuTemp + "°C"; font.family: "JetBrains Mono"; font.pixelSize: island.s(11); font.weight: Font.Black; color: island.peach }
                                    Item { Layout.fillWidth: true }
                                    Text { text: "CPU · TEMP"; font.family: "JetBrains Mono"; font.pixelSize: island.s(8); font.weight: Font.Black; color: "#6c7086"; font.letterSpacing: island.s(0.8) }
                                }
                                LineGraph {
                                    width: parent.width; height: island.s(42)
                                    graphVals: root.histCpu; graphColor: island.mauve; graphMax: 100
                                    graphVals2: root.histTemp; graphColor2: island.peach; graphMax2: 100
                                }
                            }
                        }

                        // GPU card
                        Rectangle {
                            width: parent.width - island.s(28); radius: island.s(10)
                            color: "#1a1b20"; border.width: 1; border.color: "#23242a"
                            height: grGpu.height + island.s(20)
                            Column {
                                id: grGpu
                                anchors { left: parent.left; right: parent.right; top: parent.top; margins: island.s(10) }
                                spacing: island.s(6)
                                RowLayout {
                                    width: parent.width
                                    Text { text: island.gameGpu + "%"; font.family: "JetBrains Mono"; font.pixelSize: island.s(11); font.weight: Font.Black; color: island.blue }
                                    Item { Layout.fillWidth: true }
                                    Text { text: "GPU"; font.family: "JetBrains Mono"; font.pixelSize: island.s(8); font.weight: Font.Black; color: "#6c7086"; font.letterSpacing: island.s(0.8) }
                                }
                                LineGraph { width: parent.width; height: island.s(42); graphVals: root.histGpu; graphColor: island.blue; graphMax: 100 }
                            }
                        }

                        // PING card
                        Rectangle {
                            width: parent.width - island.s(28); radius: island.s(10)
                            color: "#1a1b20"; border.width: 1; border.color: "#23242a"
                            height: grPing.height + island.s(20)
                            Column {
                                id: grPing
                                anchors { left: parent.left; right: parent.right; top: parent.top; margins: island.s(10) }
                                spacing: island.s(6)
                                RowLayout {
                                    width: parent.width
                                    Text { text: island.gamePing + " ms"; font.family: "JetBrains Mono"; font.pixelSize: island.s(11); font.weight: Font.Black
                                        color: island.gamePing < 30 ? island.green : island.gamePing < 70 ? island.yellow : island.red }
                                    Item { Layout.fillWidth: true }
                                    Text { text: "PING"; font.family: "JetBrains Mono"; font.pixelSize: island.s(8); font.weight: Font.Black; color: "#6c7086"; font.letterSpacing: island.s(0.8) }
                                }
                                LineGraph {
                                    width: parent.width; height: island.s(38)
                                    graphVals: root.histPing; graphMax: 100
                                    graphColor: island.gamePing < 30 ? island.green : island.gamePing < 70 ? island.yellow : island.red
                                }
                            }
                        }
                    }
                }
            }

            // ── SETTINGS ──────────────────────────────────────────────────
            Item {
                anchors.fill: parent
                visible: root.currentTab === 2
                clip: true

                Column {
                    anchors { fill: parent; margins: island.s(14); topMargin: island.s(10) }
                    spacing: island.s(6)

                    // DND
                    Rectangle {
                        width: parent.width; height: island.s(36); radius: island.s(10)
                        color: island.dndEnabled ? Qt.rgba(island.mauve.r, island.mauve.g, island.mauve.b, 0.12) : "#1e2025"
                        border.width: 1; border.color: island.dndEnabled ? Qt.rgba(island.mauve.r, island.mauve.g, island.mauve.b, 0.35) : "#282a2f"
                        Behavior on color { ColorAnimation { duration: 180 } }
                        Behavior on border.color { ColorAnimation { duration: 180 } }
                        RowLayout { anchors.fill: parent; anchors.margins: island.s(10); spacing: island.s(10)
                            Text { text: island.dndEnabled ? "󰂛" : "󰂚"; font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(16); color: island.dndEnabled ? island.mauve : "#6c7086" }
                            Text { text: "Do Not Disturb"; font.family: "JetBrains Mono"; font.pixelSize: island.s(12); font.weight: Font.Bold; color: island.dndEnabled ? "#e2e2e9" : "#a6adc8"; Layout.fillWidth: true }
                            Rectangle { width: island.s(32); height: island.s(18); radius: island.s(9); color: island.dndEnabled ? island.mauve : "#33353a"; Behavior on color { ColorAnimation { duration: 180 } }
                                Rectangle { width: island.s(12); height: island.s(12); radius: island.s(6); color: "white"; anchors.verticalCenter: parent.verticalCenter; x: island.dndEnabled ? island.s(16) : island.s(2); Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } } } }
                        }
                        MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: { island.dndEnabled = !island.dndEnabled; island.exec("mkdir -p ~/.cache && echo '" + (island.dndEnabled ? "1" : "0") + "' > ~/.cache/qs_dnd") } }
                    }

                    // Performance mode
                    Rectangle {
                        width: parent.width; height: island.s(36); radius: island.s(10)
                        color: root.perfOn ? Qt.rgba(island.green.r, island.green.g, island.green.b, 0.12) : "#1e2025"
                        border.width: 1; border.color: root.perfOn ? Qt.rgba(island.green.r, island.green.g, island.green.b, 0.35) : "#282a2f"
                        Behavior on color { ColorAnimation { duration: 180 } }
                        Behavior on border.color { ColorAnimation { duration: 180 } }
                        RowLayout { anchors.fill: parent; anchors.margins: island.s(10); spacing: island.s(10)
                            Text { text: "󰓅"; font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(16); color: root.perfOn ? island.green : "#6c7086" }
                            Text { text: "Performance mode"; font.family: "JetBrains Mono"; font.pixelSize: island.s(12); font.weight: Font.Bold; color: root.perfOn ? "#e2e2e9" : "#a6adc8"; Layout.fillWidth: true }
                            Rectangle { width: island.s(32); height: island.s(18); radius: island.s(9); color: root.perfOn ? island.green : "#33353a"; Behavior on color { ColorAnimation { duration: 180 } }
                                Rectangle { width: island.s(12); height: island.s(12); radius: island.s(6); color: "white"; anchors.verticalCenter: parent.verticalCenter; x: root.perfOn ? island.s(16) : island.s(2); Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } } } }
                        }
                        MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: { root.perfOn = !root.perfOn; island.exec("powerprofilesctl set " + (root.perfOn ? "performance" : "balanced")) } }
                    }

                    // Mic mute
                    Rectangle {
                        width: parent.width; height: island.s(36); radius: island.s(10)
                        color: root.micMuted ? Qt.rgba(island.red.r, island.red.g, island.red.b, 0.12) : "#1e2025"
                        border.width: 1; border.color: root.micMuted ? Qt.rgba(island.red.r, island.red.g, island.red.b, 0.35) : "#282a2f"
                        Behavior on color { ColorAnimation { duration: 180 } }
                        Behavior on border.color { ColorAnimation { duration: 180 } }
                        RowLayout { anchors.fill: parent; anchors.margins: island.s(10); spacing: island.s(10)
                            Text { text: root.micMuted ? "󰍭" : "󰍬"; font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(16); color: root.micMuted ? island.red : "#6c7086" }
                            Text { text: "Mute microphone"; font.family: "JetBrains Mono"; font.pixelSize: island.s(12); font.weight: Font.Bold; color: root.micMuted ? "#e2e2e9" : "#a6adc8"; Layout.fillWidth: true }
                            Rectangle { width: island.s(32); height: island.s(18); radius: island.s(9); color: root.micMuted ? island.red : "#33353a"; Behavior on color { ColorAnimation { duration: 180 } }
                                Rectangle { width: island.s(12); height: island.s(12); radius: island.s(6); color: "white"; anchors.verticalCenter: parent.verticalCenter; x: root.micMuted ? island.s(16) : island.s(2); Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } } } }
                        }
                        MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: { root.micMuted = !root.micMuted; island.exec("wpctl set-mute @DEFAULT_SOURCE@ toggle") } }
                    }

                    // Always-on-top: keeps the island layer above fullscreen surfaces.
                    Rectangle {
                        width: parent.width; height: island.s(36); radius: island.s(10)
                        color: island.alwaysOnTop ? Qt.rgba(island.peach.r, island.peach.g, island.peach.b, 0.12) : "#1e2025"
                        border.width: 1; border.color: island.alwaysOnTop ? Qt.rgba(island.peach.r, island.peach.g, island.peach.b, 0.35) : "#282a2f"
                        Behavior on color { ColorAnimation { duration: 180 } }
                        Behavior on border.color { ColorAnimation { duration: 180 } }
                        RowLayout { anchors.fill: parent; anchors.margins: island.s(10); spacing: island.s(10)
                            Text { text: "󰁞"; font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(16); color: island.alwaysOnTop ? island.peach : "#6c7086" }
                            Text { text: "Always on top"; font.family: "JetBrains Mono"; font.pixelSize: island.s(12); font.weight: Font.Bold; color: island.alwaysOnTop ? "#e2e2e9" : "#a6adc8"; Layout.fillWidth: true }
                            Rectangle { width: island.s(32); height: island.s(18); radius: island.s(9); color: island.alwaysOnTop ? island.peach : "#33353a"; Behavior on color { ColorAnimation { duration: 180 } }
                                Rectangle { width: island.s(12); height: island.s(12); radius: island.s(6); color: "white"; anchors.verticalCenter: parent.verticalCenter; x: island.alwaysOnTop ? island.s(16) : island.s(2); Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } } } }
                        }
                        MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: { island.alwaysOnTop = !island.alwaysOnTop; island.exec("mkdir -p ~/.cache && echo '" + (island.alwaysOnTop ? "1" : "0") + "' > ~/.cache/qs_island_aot") } }
                    }
                }
            }
        }

        // ── Tab bar ───────────────────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            height: island.s(32)

            Rectangle {
                anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                height: 1; color: Qt.rgba(1, 1, 1, 0.06)
            }

            Row {
                anchors.fill: parent
                Repeater {
                    model: ["OVERVIEW", "GRAPHS", "SETTINGS"]
                    delegate: Item {
                        width: parent.width / 3; height: parent.height
                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            font.family: "JetBrains Mono"; font.pixelSize: island.s(8); font.weight: Font.Black
                            font.letterSpacing: island.s(1.0)
                            color: root.currentTab === index ? root.healthColor : "#6c7086"
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                        Rectangle {
                            anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
                            width: island.s(28); height: island.s(1.5); radius: 1
                            color: root.currentTab === index ? root.healthColor : "transparent"
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.currentTab = index }
                    }
                }
            }
        }
    }
}
