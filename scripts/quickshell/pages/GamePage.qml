import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import "../themes"

Item {
    id: root
    property var island
    clip: true

    property int currentTab: 0

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
    property var histFps:  Array(40).fill(0)
    property var histPing: Array(40).fill(0)
    property var histGpu:  Array(40).fill(0)
    property var histCpu:  Array(40).fill(0)
    property var histTemp: Array(40).fill(0)
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

    readonly property int fpsCeiling: Math.max(165, island.gameFps)

    readonly property color healthColor: {
        if (island.gameFps > 100 && island.gamePing < 22) return island.green
        if (island.gameFps > 60  && island.gamePing < 45) return island.yellow
        return island.red
    }

    // ── Toggle row ────────────────────────────────────────────────────────
    component ToggleRow: Rectangle {
        id: toggleCard
        property string label:       ""
        property string icon:        ""
        property bool   active:      false
        property color  activeColor: island.mauve
        signal toggled()

        width: parent.width; height: island.s(36); radius: island.s(10)
        color: active
            ? Qt.rgba(activeColor.r, activeColor.g, activeColor.b, 0.12)
            : Qt.rgba(island.surface0.r, island.surface0.g, island.surface0.b, 0.6)
        border.width: 1
        border.color: active
            ? Qt.rgba(activeColor.r, activeColor.g, activeColor.b, 0.35)
            : Qt.rgba(island.surface0.r, island.surface0.g, island.surface0.b, 0.5)
        Behavior on color        { ColorAnimation { duration: 180 } }
        Behavior on border.color { ColorAnimation { duration: 180 } }

        RowLayout {
            anchors.fill: parent; anchors.margins: island.s(10); spacing: island.s(10)
            Text { text: toggleCard.icon; font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(16); color: toggleCard.active ? toggleCard.activeColor : Theme.overlay0 }
            Text { text: toggleCard.label; font.family: Theme.fontUI; font.pixelSize: island.s(13); font.weight: Font.Medium; color: toggleCard.active ? island.text : island.subtext0; Layout.fillWidth: true }
            Rectangle {
                width: island.s(32); height: island.s(18); radius: island.s(9)
                color: toggleCard.active ? toggleCard.activeColor : island.surface1
                Behavior on color { ColorAnimation { duration: 180 } }
                Rectangle {
                    width: island.s(12); height: island.s(12); radius: island.s(6); color: "white"
                    anchors.verticalCenter: parent.verticalCenter
                    x: toggleCard.active ? island.s(16) : island.s(2)
                    Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                }
            }
        }
        MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: toggleCard.toggled() }
    }

    // ── Line graph (with grid lines) ──────────────────────────────────────
    component LineGraph: Item {
        property var   graphVals:   []
        property color graphColor:  island.text
        property real  graphMax:    100
        property var   graphVals2:  []
        property color graphColor2: island.text
        property real  graphMax2:   100

        Canvas {
            anchors.fill: parent
            property var   v1: parent.graphVals
            property var   v2: parent.graphVals2
            property color c1: parent.graphColor
            property color c2: parent.graphColor2
            onV1Changed: requestPaint(); onV2Changed: requestPaint(); onC1Changed: requestPaint()
            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                var W = width, H = height

                // Subtle grid lines
                ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.05)
                ctx.lineWidth = 0.5
                for (var g = 1; g < 4; g++) {
                    ctx.beginPath()
                    ctx.moveTo(0, H * g / 4)
                    ctx.lineTo(W, H * g / 4)
                    ctx.stroke()
                }

                function series(vals, col, mx) {
                    if (!vals || vals.length < 2) return
                    var n = vals.length, pad = H * 0.08
                    ctx.beginPath()
                    for (var i = 0; i < n; i++) {
                        var x = (i / (n - 1)) * W
                        var y = H - pad - Math.max(0, Math.min(1, vals[i] / mx)) * (H - pad * 2)
                        if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y)
                    }
                    ctx.strokeStyle = Qt.rgba(col.r, col.g, col.b, 1.0)
                    ctx.lineWidth = 1.5; ctx.lineJoin = "round"; ctx.stroke()
                    ctx.lineTo(W, H); ctx.lineTo(0, H); ctx.closePath()
                    ctx.fillStyle = Qt.rgba(col.r, col.g, col.b, 0.14); ctx.fill()
                }
                series(parent.graphVals,  parent.graphColor,  parent.graphMax)
                series(parent.graphVals2, parent.graphColor2, parent.graphMax2)
            }
        }
    }

    // ── Mask ──────────────────────────────────────────────────────────────
    Item {
        id: maskShape
        anchors.fill: parent; visible: false; layer.enabled: true
        Rectangle { anchors.fill: parent; radius: island.s(28); color: "white" }
    }

    // ── Background ────────────────────────────────────────────────────────
    Item {
        id: bgLayer
        anchors.fill: parent
        Rectangle {
            anchors.fill: parent
            color: island.glassTheme
                ? Qt.rgba(island.base.r, island.base.g, island.base.b, 0)
                : Qt.rgba(island.base.r, island.base.g, island.base.b, 1)
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
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(island.base.r, island.base.g, island.base.b, 0.62)
        }
        layer.enabled: true
        layer.effect: MultiEffect { maskEnabled: true; maskSource: maskShape; maskThresholdMin: 0.5 }
    }

    // ── Top accent strip ──────────────────────────────────────────────────
    Rectangle {
        anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
        height: island.s(2.5)
        color: root.healthColor; opacity: 0.9
        Behavior on color { ColorAnimation { duration: 450 } }
    }

    // ── Main layout ───────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        anchors.bottomMargin: island.s(68)
        spacing: 0

        // ── Header ────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin:    island.s(16)
            Layout.leftMargin:   island.s(16)
            Layout.rightMargin:  island.s(14)
            Layout.bottomMargin: island.s(8)
            spacing: island.s(10)

            // Health dot with glow ring
            Item {
                width: island.s(14); height: island.s(14)
                Rectangle {
                    anchors.centerIn: parent
                    width: island.s(7); height: island.s(7); radius: island.s(4)
                    color: root.healthColor
                    Behavior on color { ColorAnimation { duration: 400 } }
                    SequentialAnimation on opacity {
                        running: true; loops: Animation.Infinite
                        NumberAnimation { to: 0.25; duration: 700; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1.0;  duration: 700; easing.type: Easing.InOutSine }
                    }
                }
                Rectangle {
                    anchors.centerIn: parent
                    width: island.s(13); height: island.s(13); radius: island.s(7)
                    color: "transparent"; border.width: 1
                    border.color: Qt.rgba(root.healthColor.r, root.healthColor.g, root.healthColor.b, 0.28)
                    Behavior on border.color { ColorAnimation { duration: 400 } }
                }
            }

            Column {
                Layout.fillWidth: true; spacing: island.s(2)
                Text {
                    text: "GAME MODE · LIVE"
                    font.family: "JetBrains Mono"; font.pixelSize: island.s(8); font.weight: Font.Black
                    font.letterSpacing: island.s(1.8); color: root.healthColor
                    Behavior on color { ColorAnimation { duration: 400 } }
                }
                Text {
                    text: island.gameName || "Unknown Game"
                    font.family: Theme.fontUI; font.pixelSize: island.s(17); font.weight: Font.Bold
                    color: island.text; elide: Text.ElideRight; width: parent.width
                }
            }

            Column {
                spacing: island.s(2)
                Text { text: "SESSION"; horizontalAlignment: Text.AlignRight; width: parent.width; font.family: "JetBrains Mono"; font.pixelSize: island.s(7); color: Theme.overlay0; font.letterSpacing: island.s(1.0) }
                Text { text: root.sessionTime; horizontalAlignment: Text.AlignRight; width: parent.width; font.family: "JetBrains Mono"; font.pixelSize: island.s(13); font.weight: Font.Bold; color: Theme.subtext1 }
            }
        }

        // ── Tab content ───────────────────────────────────────────────────
        Item {
            Layout.fillWidth: true; Layout.fillHeight: true

            // ── OVERVIEW ──────────────────────────────────────────────────
            Item {
                anchors.fill: parent; visible: root.currentTab === 0; clip: true

                Flickable {
                    anchors.fill: parent; contentHeight: ovCol.height; contentWidth: width; clip: true

                    Column {
                        id: ovCol
                        width: parent.width
                        leftPadding: island.s(14); rightPadding: island.s(14)
                        topPadding: island.s(4); bottomPadding: island.s(8)
                        spacing: island.s(6)

                        // FPS hero card
                        Rectangle {
                            id: fpsHero
                            width: parent.width - island.s(28); height: island.s(74)
                            radius: island.s(12); clip: true
                            color: Qt.rgba(island.surface0.r, island.surface0.g, island.surface0.b, 0.88)
                            border.width: 1.5
                            border.color: Qt.rgba(root.healthColor.r, root.healthColor.g, root.healthColor.b, 0.40)
                            Behavior on border.color { ColorAnimation { duration: 450 } }

                            // Left accent strip
                            Rectangle {
                                anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                                width: island.s(3); color: root.healthColor; opacity: 0.85
                                Behavior on color { ColorAnimation { duration: 450 } }
                            }
                            // Ambient glow fill
                            Rectangle {
                                anchors.fill: parent; radius: parent.radius
                                color: Qt.rgba(root.healthColor.r, root.healthColor.g, root.healthColor.b, 0.06)
                                Behavior on color { ColorAnimation { duration: 450 } }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: island.s(16); anchors.rightMargin: island.s(12)
                                anchors.topMargin: island.s(10); anchors.bottomMargin: island.s(10)
                                spacing: island.s(12)

                                Column {
                                    spacing: island.s(1)
                                    Text { text: "FPS"; font.family: "JetBrains Mono"; font.pixelSize: island.s(8); font.weight: Font.Black; font.letterSpacing: island.s(1.2); color: Theme.overlay0 }
                                    RowLayout {
                                        spacing: island.s(3)
                                        Text {
                                            text: island.gameFps
                                            font.family: "JetBrains Mono"; font.pixelSize: island.s(30); font.weight: Font.Black
                                            color: root.healthColor
                                            Behavior on color { ColorAnimation { duration: 400 } }
                                        }
                                        Text { text: "fps"; font.family: "JetBrains Mono"; font.pixelSize: island.s(10); color: Theme.overlay0; Layout.alignment: Qt.AlignBottom; Layout.bottomMargin: island.s(4) }
                                    }
                                }

                                Rectangle { width: 1; Layout.fillHeight: true; Layout.topMargin: island.s(4); Layout.bottomMargin: island.s(4); color: Qt.rgba(island.text.r, island.text.g, island.text.b, 0.08) }

                                Column {
                                    spacing: island.s(1)
                                    Text { text: "FRAME"; font.family: "JetBrains Mono"; font.pixelSize: island.s(8); font.weight: Font.Black; font.letterSpacing: island.s(1.0); color: Theme.overlay0 }
                                    RowLayout {
                                        spacing: island.s(2)
                                        Text {
                                            text: (1000 / Math.max(1, island.gameFps)).toFixed(1)
                                            font.family: "JetBrains Mono"; font.pixelSize: island.s(22); font.weight: Font.Black; color: Theme.subtext1
                                        }
                                        Text { text: "ms"; font.family: "JetBrains Mono"; font.pixelSize: island.s(10); color: Theme.overlay0; Layout.alignment: Qt.AlignBottom; Layout.bottomMargin: island.s(3) }
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                // Mini sparkline
                                LineGraph {
                                    width: island.s(60); height: island.s(42)
                                    Layout.alignment: Qt.AlignVCenter
                                    graphVals: root.histFps; graphColor: root.healthColor; graphMax: root.fpsCeiling
                                }
                            }
                        }

                        // PING + GPU row
                        Row {
                            width: parent.width - island.s(28); height: island.s(58); spacing: island.s(6)

                            Rectangle {
                                id: pingCard
                                readonly property color statClr: island.gamePing < 30 ? island.green : island.gamePing < 70 ? island.yellow : island.red
                                width: (parent.width - island.s(6)) / 2; height: parent.height
                                radius: island.s(10); clip: true
                                color: Qt.rgba(island.surface0.r, island.surface0.g, island.surface0.b, 0.78)
                                border.width: 1
                                border.color: Qt.rgba(statClr.r, statClr.g, statClr.b, 0.20)
                                Behavior on border.color { ColorAnimation { duration: 400 } }
                                Rectangle { anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; width: island.s(3); color: pingCard.statClr; opacity: 0.78; Behavior on color { ColorAnimation { duration: 400 } } }
                                Column {
                                    anchors { left: parent.left; right: parent.right; top: parent.top; bottom: parent.bottom; margins: island.s(8); leftMargin: island.s(12) }
                                    spacing: island.s(3)
                                    Text { text: "PING"; font.family: "JetBrains Mono"; font.pixelSize: island.s(8); font.weight: Font.Black; font.letterSpacing: island.s(0.8); color: Theme.overlay0 }
                                    RowLayout {
                                        spacing: island.s(2)
                                        Text { text: island.gamePing; font.family: "JetBrains Mono"; font.pixelSize: island.s(22); font.weight: Font.Black; color: pingCard.statClr; Behavior on color { ColorAnimation { duration: 400 } } }
                                        Text { text: "ms"; font.family: "JetBrains Mono"; font.pixelSize: island.s(9); color: Theme.overlay0; Layout.alignment: Qt.AlignBottom; Layout.bottomMargin: island.s(2) }
                                    }
                                }
                            }

                            Rectangle {
                                id: gpuCard
                                width: (parent.width - island.s(6)) / 2; height: parent.height
                                radius: island.s(10); clip: true
                                color: Qt.rgba(island.surface0.r, island.surface0.g, island.surface0.b, 0.78)
                                border.width: 1; border.color: Qt.rgba(island.blue.r, island.blue.g, island.blue.b, 0.20)
                                Rectangle { anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; width: island.s(3); color: island.blue; opacity: 0.78 }
                                Column {
                                    anchors { left: parent.left; right: parent.right; top: parent.top; bottom: parent.bottom; margins: island.s(8); leftMargin: island.s(12) }
                                    spacing: island.s(3)
                                    Text { text: "GPU"; font.family: "JetBrains Mono"; font.pixelSize: island.s(8); font.weight: Font.Black; font.letterSpacing: island.s(0.8); color: Theme.overlay0 }
                                    RowLayout {
                                        spacing: island.s(2)
                                        Text { text: island.gameGpu; font.family: "JetBrains Mono"; font.pixelSize: island.s(22); font.weight: Font.Black; color: island.blue }
                                        Text { text: "%"; font.family: "JetBrains Mono"; font.pixelSize: island.s(9); color: Theme.overlay0; Layout.alignment: Qt.AlignBottom; Layout.bottomMargin: island.s(2) }
                                    }
                                }
                            }
                        }

                        // CPU + RAM row
                        Row {
                            width: parent.width - island.s(28); height: island.s(58); spacing: island.s(6)

                            Rectangle {
                                id: cpuCard
                                width: (parent.width - island.s(6)) / 2; height: parent.height
                                radius: island.s(10); clip: true
                                color: Qt.rgba(island.surface0.r, island.surface0.g, island.surface0.b, 0.78)
                                border.width: 1; border.color: Qt.rgba(island.mauve.r, island.mauve.g, island.mauve.b, 0.20)
                                Rectangle { anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; width: island.s(3); color: island.mauve; opacity: 0.78 }
                                Column {
                                    anchors { left: parent.left; right: parent.right; top: parent.top; bottom: parent.bottom; margins: island.s(8); leftMargin: island.s(12) }
                                    spacing: island.s(3)
                                    Text { text: "CPU"; font.family: "JetBrains Mono"; font.pixelSize: island.s(8); font.weight: Font.Black; font.letterSpacing: island.s(0.8); color: Theme.overlay0 }
                                    RowLayout {
                                        spacing: island.s(2)
                                        Text { text: island.gameCpu; font.family: "JetBrains Mono"; font.pixelSize: island.s(22); font.weight: Font.Black; color: island.mauve }
                                        Text { text: "%"; font.family: "JetBrains Mono"; font.pixelSize: island.s(9); color: Theme.overlay0; Layout.alignment: Qt.AlignBottom; Layout.bottomMargin: island.s(2) }
                                    }
                                }
                            }

                            Rectangle {
                                id: ramCard
                                width: (parent.width - island.s(6)) / 2; height: parent.height
                                radius: island.s(10); clip: true
                                color: Qt.rgba(island.surface0.r, island.surface0.g, island.surface0.b, 0.78)
                                border.width: 1; border.color: Qt.rgba(island.teal.r, island.teal.g, island.teal.b, 0.20)
                                Rectangle { anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; width: island.s(3); color: island.teal; opacity: 0.78 }
                                Column {
                                    anchors { left: parent.left; right: parent.right; top: parent.top; bottom: parent.bottom; margins: island.s(8); leftMargin: island.s(12) }
                                    spacing: island.s(3)
                                    Text { text: "RAM"; font.family: "JetBrains Mono"; font.pixelSize: island.s(8); font.weight: Font.Black; font.letterSpacing: island.s(0.8); color: Theme.overlay0 }
                                    RowLayout {
                                        spacing: island.s(2)
                                        Text { text: island.gameRam; font.family: "JetBrains Mono"; font.pixelSize: island.s(22); font.weight: Font.Black; color: island.teal }
                                        Text { text: "%"; font.family: "JetBrains Mono"; font.pixelSize: island.s(9); color: Theme.overlay0; Layout.alignment: Qt.AlignBottom; Layout.bottomMargin: island.s(2) }
                                    }
                                }
                            }
                        }

                        // GPU TEMP + VRAM bars
                        Rectangle {
                            width: parent.width - island.s(28)
                            height: barsInner.height + island.s(20)
                            radius: island.s(10)
                            color: Qt.rgba(island.surface0.r, island.surface0.g, island.surface0.b, 0.85)
                            border.width: 1; border.color: Qt.rgba(Theme.crust.r, Theme.crust.g, Theme.crust.b, 1)

                            Column {
                                id: barsInner
                                anchors { left: parent.left; right: parent.right; top: parent.top; margins: island.s(10) }
                                spacing: 0

                                RowLayout {
                                    width: parent.width; height: island.s(28); spacing: island.s(8)
                                    readonly property color bc: island.gameGpuTemp > 85 ? island.peach : island.teal
                                    Text { text: "GPU TEMP"; Layout.preferredWidth: island.s(64); font.family: "JetBrains Mono"; font.pixelSize: island.s(8); font.weight: Font.Black; font.letterSpacing: island.s(0.6); color: Theme.overlay0 }
                                    Rectangle {
                                        Layout.fillWidth: true; height: island.s(4); radius: island.s(2)
                                        color: Qt.rgba(island.surface2.r, island.surface2.g, island.surface2.b, 0.5)
                                        Rectangle { width: parent.width * Math.min(island.gameGpuTemp, 100) / 100; height: parent.height; radius: parent.radius; color: parent.parent.bc; Behavior on width { NumberAnimation { duration: 800; easing.type: Easing.OutCubic } } }
                                    }
                                    Text { text: island.gameGpuTemp + "°"; Layout.preferredWidth: island.s(36); font.family: "JetBrains Mono"; font.pixelSize: island.s(10); font.weight: Font.Bold; color: parent.bc; horizontalAlignment: Text.AlignRight }
                                }
                                Rectangle { width: parent.width; height: 1; color: Qt.rgba(island.text.r, island.text.g, island.text.b, 0.05) }
                                RowLayout {
                                    width: parent.width; height: island.s(28); spacing: island.s(8)
                                    Text { text: "VRAM"; Layout.preferredWidth: island.s(64); font.family: "JetBrains Mono"; font.pixelSize: island.s(8); font.weight: Font.Black; font.letterSpacing: island.s(0.6); color: Theme.overlay0 }
                                    Rectangle {
                                        Layout.fillWidth: true; height: island.s(4); radius: island.s(2)
                                        color: Qt.rgba(island.surface2.r, island.surface2.g, island.surface2.b, 0.5)
                                        Rectangle { width: parent.width * Math.min(island.gameVram, 100) / 100; height: parent.height; radius: parent.radius; color: island.blue; Behavior on width { NumberAnimation { duration: 800; easing.type: Easing.OutCubic } } }
                                    }
                                    Text { text: island.gameVram + "%"; Layout.preferredWidth: island.s(36); font.family: "JetBrains Mono"; font.pixelSize: island.s(10); font.weight: Font.Bold; color: island.blue; horizontalAlignment: Text.AlignRight }
                                }
                            }
                        }
                    }
                }
            }

            // ── GRAPHS ────────────────────────────────────────────────────
            Item {
                anchors.fill: parent; visible: root.currentTab === 1; clip: true

                Flickable {
                    anchors.fill: parent; contentHeight: grCol.height; contentWidth: width; clip: true

                    Column {
                        id: grCol
                        width: parent.width
                        leftPadding: island.s(14); rightPadding: island.s(14)
                        topPadding: island.s(6); bottomPadding: island.s(6)
                        spacing: island.s(8)

                        // FPS card
                        Rectangle {
                            width: parent.width - island.s(28); radius: island.s(10)
                            color: Theme.mantle
                            border.width: 1; border.color: Qt.rgba(island.surface0.r, island.surface0.g, island.surface0.b, 0.8)
                            height: grFps.height + island.s(20); clip: true
                            Rectangle { anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; width: island.s(3); radius: 1; color: root.healthColor; opacity: 0.82; Behavior on color { ColorAnimation { duration: 400 } } }
                            Column {
                                id: grFps
                                anchors { left: parent.left; right: parent.right; top: parent.top; margins: island.s(10) }
                                anchors.leftMargin: island.s(14)
                                spacing: island.s(6)
                                RowLayout {
                                    width: parent.width
                                    Text { text: island.gameFps + " fps"; font.family: "JetBrains Mono"; font.pixelSize: island.s(11); font.weight: Font.Black; color: root.healthColor; Behavior on color { ColorAnimation { duration: 400 } } }
                                    Item { Layout.fillWidth: true }
                                    Text { text: "FPS"; font.family: "JetBrains Mono"; font.pixelSize: island.s(8); font.weight: Font.Black; color: Theme.overlay0; font.letterSpacing: island.s(0.8) }
                                }
                                LineGraph { width: parent.width; height: island.s(46); graphVals: root.histFps; graphColor: root.healthColor; graphMax: root.fpsCeiling }
                            }
                        }

                        // CPU + TEMP card
                        Rectangle {
                            width: parent.width - island.s(28); radius: island.s(10)
                            color: Theme.mantle
                            border.width: 1; border.color: Qt.rgba(island.surface0.r, island.surface0.g, island.surface0.b, 0.8)
                            height: grCpu.height + island.s(20); clip: true
                            Rectangle { anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; width: island.s(3); radius: 1; color: island.mauve; opacity: 0.82 }
                            Column {
                                id: grCpu
                                anchors { left: parent.left; right: parent.right; top: parent.top; margins: island.s(10) }
                                anchors.leftMargin: island.s(14)
                                spacing: island.s(6)
                                RowLayout {
                                    width: parent.width
                                    Text { text: island.gameCpu + "%"; font.family: "JetBrains Mono"; font.pixelSize: island.s(11); font.weight: Font.Black; color: island.mauve }
                                    Text { text: "· " + island.gameGpuTemp + "°C"; font.family: "JetBrains Mono"; font.pixelSize: island.s(11); font.weight: Font.Black; color: island.peach }
                                    Item { Layout.fillWidth: true }
                                    Text { text: "CPU · TEMP"; font.family: "JetBrains Mono"; font.pixelSize: island.s(8); font.weight: Font.Black; color: Theme.overlay0; font.letterSpacing: island.s(0.8) }
                                }
                                LineGraph { width: parent.width; height: island.s(42); graphVals: root.histCpu; graphColor: island.mauve; graphMax: 100; graphVals2: root.histTemp; graphColor2: island.peach; graphMax2: 100 }
                            }
                        }

                        // GPU card
                        Rectangle {
                            width: parent.width - island.s(28); radius: island.s(10)
                            color: Theme.mantle
                            border.width: 1; border.color: Qt.rgba(island.surface0.r, island.surface0.g, island.surface0.b, 0.8)
                            height: grGpu.height + island.s(20); clip: true
                            Rectangle { anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; width: island.s(3); radius: 1; color: island.blue; opacity: 0.82 }
                            Column {
                                id: grGpu
                                anchors { left: parent.left; right: parent.right; top: parent.top; margins: island.s(10) }
                                anchors.leftMargin: island.s(14)
                                spacing: island.s(6)
                                RowLayout {
                                    width: parent.width
                                    Text { text: island.gameGpu + "%"; font.family: "JetBrains Mono"; font.pixelSize: island.s(11); font.weight: Font.Black; color: island.blue }
                                    Item { Layout.fillWidth: true }
                                    Text { text: "GPU"; font.family: "JetBrains Mono"; font.pixelSize: island.s(8); font.weight: Font.Black; color: Theme.overlay0; font.letterSpacing: island.s(0.8) }
                                }
                                LineGraph { width: parent.width; height: island.s(42); graphVals: root.histGpu; graphColor: island.blue; graphMax: 100 }
                            }
                        }

                        // PING card
                        Rectangle {
                            readonly property color pingClr: island.gamePing < 30 ? island.green : island.gamePing < 70 ? island.yellow : island.red
                            width: parent.width - island.s(28); radius: island.s(10)
                            color: Theme.mantle
                            border.width: 1; border.color: Qt.rgba(island.surface0.r, island.surface0.g, island.surface0.b, 0.8)
                            height: grPing.height + island.s(20); clip: true
                            Rectangle { anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; width: island.s(3); radius: 1; color: parent.pingClr; opacity: 0.82; Behavior on color { ColorAnimation { duration: 400 } } }
                            Column {
                                id: grPing
                                anchors { left: parent.left; right: parent.right; top: parent.top; margins: island.s(10) }
                                anchors.leftMargin: island.s(14)
                                spacing: island.s(6)
                                RowLayout {
                                    width: parent.width
                                    Text { text: island.gamePing + " ms"; font.family: "JetBrains Mono"; font.pixelSize: island.s(11); font.weight: Font.Black; color: island.gamePing < 30 ? island.green : island.gamePing < 70 ? island.yellow : island.red }
                                    Item { Layout.fillWidth: true }
                                    Text { text: "PING"; font.family: "JetBrains Mono"; font.pixelSize: island.s(8); font.weight: Font.Black; color: Theme.overlay0; font.letterSpacing: island.s(0.8) }
                                }
                                LineGraph { width: parent.width; height: island.s(38); graphVals: root.histPing; graphMax: 100; graphColor: island.gamePing < 30 ? island.green : island.gamePing < 70 ? island.yellow : island.red }
                            }
                        }
                    }
                }
            }

            // ── SETTINGS ──────────────────────────────────────────────────
            Item {
                anchors.fill: parent; visible: root.currentTab === 2; clip: true

                Column {
                    anchors { fill: parent; margins: island.s(14); topMargin: island.s(10) }
                    spacing: island.s(6)

                    ToggleRow {
                        label: "Do Not Disturb"; icon: island.dndEnabled ? "󰂛" : "󰂚"; active: island.dndEnabled; activeColor: island.mauve
                        onToggled: { island.dndEnabled = !island.dndEnabled; island.exec("mkdir -p ~/.cache && echo '" + (island.dndEnabled ? "1" : "0") + "' > ~/.cache/qs_dnd") }
                    }
                    ToggleRow {
                        label: "Performance mode"; icon: "󰓅"; active: island.gamePerfMode; activeColor: island.green
                        onToggled: { island.gamePerfMode = !island.gamePerfMode; island.exec("powerprofilesctl set " + (island.gamePerfMode ? "performance" : "balanced")) }
                    }
                    ToggleRow {
                        label: "Mute microphone"; icon: island.gameMicMuted ? "󰍭" : "󰍬"; active: island.gameMicMuted; activeColor: island.red
                        onToggled: { island.gameMicMuted = !island.gameMicMuted; island.exec("wpctl set-mute @DEFAULT_SOURCE@ toggle") }
                    }
                    ToggleRow {
                        label: "Always on top"; icon: "󰁞"; active: island.alwaysOnTop; activeColor: island.peach
                        onToggled: { island.alwaysOnTop = !island.alwaysOnTop; island.exec("mkdir -p ~/.cache && echo '" + (island.alwaysOnTop ? "1" : "0") + "' > ~/.cache/qs_island_aot") }
                    }
                }
            }
        }

        // ── Tab bar with sliding pill ──────────────────────────────────────
        Item {
            Layout.fillWidth: true; height: island.s(34)

            Rectangle { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; height: 1; color: Qt.rgba(island.text.r, island.text.g, island.text.b, 0.06) }

            // Sliding pill indicator
            Rectangle {
                y: island.s(5); height: island.s(24)
                width: parent.width / 3 - island.s(20); radius: island.s(6)
                x: (parent.width / 3) * root.currentTab + island.s(10)
                color: Qt.rgba(root.healthColor.r, root.healthColor.g, root.healthColor.b, 0.13)
                border.width: 1
                border.color: Qt.rgba(root.healthColor.r, root.healthColor.g, root.healthColor.b, 0.32)
                Behavior on x            { NumberAnimation   { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on color        { ColorAnimation { duration: 400 } }
                Behavior on border.color { ColorAnimation { duration: 400 } }
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
                            color: root.currentTab === index ? root.healthColor : Theme.overlay0
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.currentTab = index }
                    }
                }
            }
        }
    }
}
