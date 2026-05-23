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

    // ── History arrays (40 samples) ───────────────────────────────────────
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

    // ── Toggle Row ────────────────────────────────────────────────────────
    component ToggleRow: Rectangle {
        id: toggleCard
        property string label:       ""
        property string icon:        ""
        property bool   active:      false
        property color  activeColor: island.mauve
        signal toggled()

        width: parent.width; height: island.s(44); radius: island.s(12)
        color: active
            ? Qt.rgba(activeColor.r, activeColor.g, activeColor.b, 0.10)
            : Qt.rgba(island.surface0.r, island.surface0.g, island.surface0.b, 0.50)
        border.width: 1
        border.color: active
            ? Qt.rgba(activeColor.r, activeColor.g, activeColor.b, 0.28)
            : Qt.rgba(island.surface1.r, island.surface1.g, island.surface1.b, 0.5)
        Behavior on color        { ColorAnimation { duration: 180 } }
        Behavior on border.color { ColorAnimation { duration: 180 } }

        RowLayout {
            anchors.fill: parent; anchors.margins: island.s(14); spacing: island.s(12)
            Text { text: toggleCard.icon; font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(16); color: toggleCard.active ? toggleCard.activeColor : Theme.overlay0 }
            Text { text: toggleCard.label; font.family: Theme.fontUI; font.pixelSize: island.s(13); font.weight: Font.Medium; color: toggleCard.active ? island.text : island.subtext0; Layout.fillWidth: true }
            Rectangle {
                width: island.s(36); height: island.s(20); radius: island.s(10)
                color: toggleCard.active ? toggleCard.activeColor : island.surface1
                Behavior on color { ColorAnimation { duration: 180 } }
                Rectangle {
                    width: island.s(14); height: island.s(14); radius: island.s(7); color: "white"
                    anchors.verticalCenter: parent.verticalCenter
                    x: toggleCard.active ? island.s(19) : island.s(3)
                    Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                }
            }
        }
        MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: toggleCard.toggled() }
    }

    // ── Line graph ────────────────────────────────────────────────────────
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

                ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.04)
                ctx.lineWidth = 0.5
                for (var g = 1; g < 4; g++) {
                    ctx.beginPath(); ctx.moveTo(0, H * g / 4); ctx.lineTo(W, H * g / 4); ctx.stroke()
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
                    ctx.fillStyle = Qt.rgba(col.r, col.g, col.b, 0.11); ctx.fill()
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

    // ── Background — stronger blur, cover art breathes through ────────────
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
            blurEnabled: true; blurMax: 64; blur: 1.0; opacity: coverImg.opacity
        }
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(island.base.r, island.base.g, island.base.b, 0.38)
        }
        layer.enabled: true
        layer.effect: MultiEffect { maskEnabled: true; maskSource: maskShape; maskThresholdMin: 0.5 }
    }

    // ── Main layout ───────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Header ────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin:    island.s(16)
            Layout.leftMargin:   island.s(16)
            Layout.rightMargin:  island.s(16)
            Layout.bottomMargin: island.s(10)
            spacing: island.s(8)

            Column {
                Layout.fillWidth: true; spacing: island.s(3)

                Row {
                    spacing: island.s(5)
                    Rectangle {
                        width: island.s(6); height: island.s(6); radius: island.s(3)
                        color: root.healthColor; anchors.verticalCenter: parent.verticalCenter
                        Behavior on color { ColorAnimation { duration: 400 } }
                        SequentialAnimation on opacity {
                            running: true; loops: Animation.Infinite
                            NumberAnimation { to: 0.25; duration: 700; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1.0;  duration: 700; easing.type: Easing.InOutSine }
                        }
                    }
                    Text {
                        text: "LIVE"
                        font.family: "JetBrains Mono"; font.pixelSize: island.s(8); font.weight: Font.Black
                        font.letterSpacing: island.s(1.4); color: root.healthColor
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on color { ColorAnimation { duration: 400 } }
                    }
                }

                Text {
                    text: island.gameName || "Unknown Game"
                    font.family: Theme.fontUI; font.pixelSize: island.s(18); font.weight: Font.ExtraBold
                    color: island.text; elide: Text.ElideRight; width: parent.width
                }
            }

            // Session timer pill
            Rectangle {
                height: island.s(26); radius: island.s(13)
                width: timerRow.implicitWidth + island.s(16)
                color: Qt.rgba(island.surface0.r, island.surface0.g, island.surface0.b, 0.65)
                border.width: 1
                border.color: Qt.rgba(island.text.r, island.text.g, island.text.b, 0.07)
                Layout.alignment: Qt.AlignVCenter

                Row {
                    id: timerRow
                    anchors.centerIn: parent; spacing: island.s(5)
                    Text { text: "󱎫"; font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(10); color: Theme.overlay0; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: root.sessionTime; font.family: "JetBrains Mono"; font.pixelSize: island.s(11); font.weight: Font.Bold; color: Theme.subtext1; anchors.verticalCenter: parent.verticalCenter }
                }
            }
        }

        // ── Segmented control (UISegmentedControl) ────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.leftMargin:   island.s(16)
            Layout.rightMargin:  island.s(16)
            Layout.bottomMargin: island.s(12)
            height: island.s(32)

            Rectangle {
                anchors.fill: parent; radius: island.s(10)
                color: Qt.rgba(island.surface0.r, island.surface0.g, island.surface0.b, 0.60)
                border.width: 1
                border.color: Qt.rgba(island.text.r, island.text.g, island.text.b, 0.06)

                Rectangle {
                    id: segPill
                    height: parent.height - island.s(4); radius: island.s(8)
                    width: parent.width / 3 - island.s(4)
                    x: (parent.width / 3) * root.currentTab + island.s(2)
                    anchors.verticalCenter: parent.verticalCenter
                    color: Qt.rgba(island.text.r, island.text.g, island.text.b, 0.11)
                    border.width: 1
                    border.color: Qt.rgba(island.text.r, island.text.g, island.text.b, 0.09)
                    Behavior on x { SpringAnimation { spring: 6; damping: 0.82 } }
                }

                Row {
                    anchors.fill: parent
                    Repeater {
                        model: ["Overview", "Graphs", "Controls"]
                        delegate: Item {
                            width: parent.width / 3; height: parent.height
                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                font.family: Theme.fontUI; font.pixelSize: island.s(11); font.weight: Font.Medium
                                color: root.currentTab === index ? island.text : Theme.overlay0
                                Behavior on color { ColorAnimation { duration: 160 } }
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.currentTab = index }
                        }
                    }
                }
            }
        }

        // ── Tab content ───────────────────────────────────────────────────
        Item {
            Layout.fillWidth: true; Layout.fillHeight: true

            // ── OVERVIEW ──────────────────────────────────────────────────
            Item {
                anchors.fill: parent; visible: root.currentTab === 0; clip: true
                opacity: root.currentTab === 0 ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                Flickable {
                    anchors.fill: parent; contentHeight: ovCol.implicitHeight; contentWidth: width; clip: true

                    Column {
                        id: ovCol
                        width: parent.width
                        leftPadding: island.s(16); rightPadding: island.s(16)
                        topPadding: island.s(2); bottomPadding: island.s(16)
                        spacing: island.s(16)

                        // ── FPS ring hero
                        Item {
                            width: parent.width - island.s(32)
                            height: island.s(150)

                            // Ring canvas
                            Canvas {
                                id: fpsCanvas
                                anchors.centerIn: parent
                                width: island.s(134); height: island.s(134)
                                property real fpsVal: island.gameFps
                                property real fpsMax: root.fpsCeiling
                                property color rc: root.healthColor
                                onFpsValChanged: requestPaint()
                                onRcChanged: requestPaint()
                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.clearRect(0, 0, width, height)
                                    var cx = width / 2, cy = height / 2
                                    var sw = island.s(9)
                                    var r  = Math.min(width, height) / 2 - sw / 2 - island.s(2)
                                    var startRad = 135 * Math.PI / 180
                                    var endRad   = (135 + 270) * Math.PI / 180
                                    var ratio    = Math.min(1.0, Math.max(0, fpsVal / fpsMax))
                                    var fillRad  = startRad + ratio * 270 * Math.PI / 180

                                    // Track
                                    ctx.beginPath()
                                    ctx.arc(cx, cy, r, startRad, endRad, false)
                                    ctx.strokeStyle = Qt.rgba(rc.r, rc.g, rc.b, 0.14)
                                    ctx.lineWidth = sw; ctx.lineCap = "round"; ctx.stroke()

                                    // Fill
                                    if (fpsVal > 0) {
                                        ctx.beginPath()
                                        ctx.arc(cx, cy, r, startRad, fillRad, false)
                                        ctx.strokeStyle = Qt.rgba(rc.r, rc.g, rc.b, 1.0)
                                        ctx.lineWidth = sw; ctx.lineCap = "round"; ctx.stroke()
                                    }
                                }
                            }

                            // Center text
                            Column {
                                anchors.centerIn: fpsCanvas
                                spacing: island.s(1)
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: island.gameFps
                                    font.family: "JetBrains Mono"; font.pixelSize: island.s(36); font.weight: Font.Black
                                    color: root.healthColor
                                    Behavior on color { ColorAnimation { duration: 400 } }
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "fps"
                                    font.family: "JetBrains Mono"; font.pixelSize: island.s(11)
                                    color: Theme.overlay0
                                }
                            }

                            // Frame time — bottom-right of ring area
                            Column {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: island.s(2)
                                Text {
                                    text: "FRAME"
                                    font.family: "JetBrains Mono"; font.pixelSize: island.s(7); font.weight: Font.Black
                                    font.letterSpacing: island.s(0.7); color: Theme.overlay0
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                                Row {
                                    spacing: island.s(2)
                                    Text {
                                        text: (1000 / Math.max(1, island.gameFps)).toFixed(1)
                                        font.family: "JetBrains Mono"; font.pixelSize: island.s(20); font.weight: Font.Black
                                        color: Theme.subtext1
                                    }
                                    Text {
                                        text: "ms"; font.family: "JetBrains Mono"; font.pixelSize: island.s(9)
                                        color: Theme.overlay0; anchors.bottom: parent.bottom; anchors.bottomMargin: island.s(2)
                                    }
                                }
                            }
                        }

                        // ── 3 mini rings: PING | GPU | CPU ─────────────────
                        Row {
                            width: parent.width - island.s(32)
                            height: island.s(100)
                            spacing: 0

                            Repeater {
                                id: miniRingsRepeater
                                model: ListModel {
                                    ListElement { lbl: "PING"; unit: "ms" }
                                    ListElement { lbl: "GPU";  unit: "%" }
                                    ListElement { lbl: "CPU";  unit: "%" }
                                }

                                delegate: Item {
                                    width: parent.width / 3; height: parent.height

                                    readonly property real statValue: {
                                        if (lbl === "PING") return island.gamePing
                                        if (lbl === "GPU")  return island.gameGpu
                                        return island.gameCpu
                                    }
                                    readonly property color statColor: {
                                        if (lbl === "PING") return island.gamePing < 30 ? island.green : island.gamePing < 70 ? island.yellow : island.red
                                        if (lbl === "GPU")  return island.blue
                                        return island.mauve
                                    }

                                    Column {
                                        anchors.centerIn: parent
                                        spacing: island.s(8)

                                        Item {
                                            width: island.s(64); height: island.s(64)
                                            anchors.horizontalCenter: parent.horizontalCenter

                                            Canvas {
                                                anchors.fill: parent
                                                property real v: statValue
                                                property color rc: statColor
                                                onVChanged: requestPaint()
                                                onRcChanged: requestPaint()
                                                onPaint: {
                                                    var ctx = getContext("2d")
                                                    ctx.clearRect(0, 0, width, height)
                                                    var cx = width / 2, cy = height / 2
                                                    var sw = island.s(5)
                                                    var r  = Math.min(width, height) / 2 - sw / 2 - island.s(1)
                                                    var startRad = 135 * Math.PI / 180
                                                    var endRad   = (135 + 270) * Math.PI / 180
                                                    var fillRad  = startRad + Math.min(1, Math.max(0, v / 100)) * 270 * Math.PI / 180

                                                    ctx.beginPath()
                                                    ctx.arc(cx, cy, r, startRad, endRad, false)
                                                    ctx.strokeStyle = Qt.rgba(rc.r, rc.g, rc.b, 0.14)
                                                    ctx.lineWidth = sw; ctx.lineCap = "round"; ctx.stroke()

                                                    if (v > 0) {
                                                        ctx.beginPath()
                                                        ctx.arc(cx, cy, r, startRad, fillRad, false)
                                                        ctx.strokeStyle = Qt.rgba(rc.r, rc.g, rc.b, 1.0)
                                                        ctx.lineWidth = sw; ctx.lineCap = "round"; ctx.stroke()
                                                    }
                                                }
                                            }

                                            Row {
                                                anchors.centerIn: parent; spacing: island.s(1)
                                                Text {
                                                    text: statValue
                                                    font.family: "JetBrains Mono"; font.pixelSize: island.s(15); font.weight: Font.Black
                                                    color: statColor; anchors.baseline: unitTxt.baseline
                                                    Behavior on color { ColorAnimation { duration: 400 } }
                                                }
                                                Text {
                                                    id: unitTxt; text: unit
                                                    font.family: "JetBrains Mono"; font.pixelSize: island.s(8)
                                                    color: Theme.overlay0
                                                    anchors.bottom: parent.bottom; anchors.bottomMargin: island.s(1)
                                                }
                                            }
                                        }

                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: lbl
                                            font.family: "JetBrains Mono"; font.pixelSize: island.s(8); font.weight: Font.Black
                                            font.letterSpacing: island.s(0.8); color: Theme.overlay0
                                        }
                                    }
                                }
                            }
                        }

                        // ── Secondary bar: TEMP | RAM | VRAM ───────────────
                        Rectangle {
                            width: parent.width - island.s(32); height: island.s(52)
                            radius: island.s(12)
                            color: Qt.rgba(island.surface0.r, island.surface0.g, island.surface0.b, 0.55)
                            border.width: 1
                            border.color: Qt.rgba(island.text.r, island.text.g, island.text.b, 0.06)

                            Row {
                                anchors.fill: parent

                                Repeater {
                                    model: ListModel {
                                        ListElement { slbl: "TEMP"; sunit: "°C" }
                                        ListElement { slbl: "RAM";  sunit: "%" }
                                        ListElement { slbl: "VRAM"; sunit: "%" }
                                    }
                                    delegate: Item {
                                        width: parent.width / 3; height: parent.height

                                        readonly property real sValue: {
                                            if (slbl === "TEMP") return island.gameGpuTemp
                                            if (slbl === "RAM")  return island.gameRam
                                            return island.gameVram
                                        }
                                        readonly property color sColor: {
                                            if (slbl === "TEMP") return island.gameGpuTemp > 85 ? island.peach : island.teal
                                            if (slbl === "RAM")  return island.teal
                                            return island.blue
                                        }

                                        Column {
                                            anchors.centerIn: parent; spacing: island.s(4)

                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: slbl
                                                font.family: "JetBrains Mono"; font.pixelSize: island.s(7); font.weight: Font.Black
                                                font.letterSpacing: island.s(0.7); color: Theme.overlay0
                                            }

                                            Row {
                                                anchors.horizontalCenter: parent.horizontalCenter; spacing: island.s(1)
                                                Text {
                                                    text: sValue
                                                    font.family: "JetBrains Mono"; font.pixelSize: island.s(16); font.weight: Font.Black
                                                    color: sColor
                                                    Behavior on color { ColorAnimation { duration: 400 } }
                                                }
                                                Text {
                                                    text: sunit; font.family: "JetBrains Mono"; font.pixelSize: island.s(8)
                                                    color: Theme.overlay0; anchors.bottom: parent.bottom; anchors.bottomMargin: island.s(2)
                                                }
                                            }
                                        }

                                        // Vertical divider (not on last item)
                                        Rectangle {
                                            visible: index < 2
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 1; height: island.s(26)
                                            color: Qt.rgba(island.text.r, island.text.g, island.text.b, 0.07)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── GRAPHS ────────────────────────────────────────────────────
            Item {
                anchors.fill: parent; visible: root.currentTab === 1; clip: true
                opacity: root.currentTab === 1 ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                Flickable {
                    anchors.fill: parent; contentHeight: grCol.implicitHeight; contentWidth: width; clip: true

                    Column {
                        id: grCol
                        width: parent.width
                        leftPadding: island.s(14); rightPadding: island.s(14)
                        topPadding: island.s(4); bottomPadding: island.s(16)
                        spacing: island.s(8)

                        // FPS graph card
                        Rectangle {
                            width: parent.width - island.s(28); radius: island.s(12)
                            color: Qt.rgba(island.surface0.r, island.surface0.g, island.surface0.b, 0.55)
                            border.width: 1; border.color: Qt.rgba(island.surface1.r, island.surface1.g, island.surface1.b, 0.8)
                            implicitHeight: grFps.implicitHeight + island.s(20); clip: true

                            Column {
                                id: grFps
                                anchors { left: parent.left; right: parent.right; top: parent.top; margins: island.s(12) }
                                spacing: island.s(6)

                                RowLayout {
                                    width: parent.width
                                    Text { text: island.gameFps + " fps"; font.family: "JetBrains Mono"; font.pixelSize: island.s(12); font.weight: Font.Black; color: root.healthColor; Behavior on color { ColorAnimation { duration: 400 } } }
                                    Item { Layout.fillWidth: true }
                                    Text { text: "FPS"; font.family: "JetBrains Mono"; font.pixelSize: island.s(8); font.weight: Font.Black; color: Theme.overlay0; font.letterSpacing: island.s(0.8) }
                                }
                                LineGraph { width: parent.width; height: island.s(50); graphVals: root.histFps; graphColor: root.healthColor; graphMax: root.fpsCeiling }
                                RowLayout {
                                    width: parent.width
                                    readonly property var f: root.histFps.filter(function(v){ return v > 0 })
                                    readonly property int mn: f.length ? Math.min.apply(null, f) : 0
                                    readonly property int mx: f.length ? Math.max.apply(null, f) : 0
                                    readonly property int av: f.length ? Math.round(f.reduce(function(a,b){return a+b},0)/f.length) : 0
                                    Text { text: "MIN  " + parent.mn; font.family: "JetBrains Mono"; font.pixelSize: island.s(8); color: Theme.overlay0 }
                                    Item { Layout.fillWidth: true }
                                    Text { text: "AVG  " + parent.av; font.family: "JetBrains Mono"; font.pixelSize: island.s(8); color: Theme.subtext0; font.weight: Font.Bold }
                                    Item { Layout.fillWidth: true }
                                    Text { text: "MAX  " + parent.mx; font.family: "JetBrains Mono"; font.pixelSize: island.s(8); color: Theme.overlay0 }
                                }
                            }
                        }

                        // CPU + TEMP graph card
                        Rectangle {
                            width: parent.width - island.s(28); radius: island.s(12)
                            color: Qt.rgba(island.surface0.r, island.surface0.g, island.surface0.b, 0.55)
                            border.width: 1; border.color: Qt.rgba(island.surface1.r, island.surface1.g, island.surface1.b, 0.8)
                            implicitHeight: grCpu.implicitHeight + island.s(20); clip: true

                            Column {
                                id: grCpu
                                anchors { left: parent.left; right: parent.right; top: parent.top; margins: island.s(12) }
                                spacing: island.s(6)

                                RowLayout {
                                    width: parent.width
                                    Row {
                                        spacing: island.s(10)
                                        Row {
                                            spacing: island.s(4)
                                            Rectangle { width: island.s(5); height: island.s(5); radius: island.s(3); color: island.mauve; anchors.verticalCenter: parent.verticalCenter }
                                            Text { text: island.gameCpu + "%"; font.family: "JetBrains Mono"; font.pixelSize: island.s(11); font.weight: Font.Black; color: island.mauve }
                                        }
                                        Row {
                                            spacing: island.s(4)
                                            Rectangle { width: island.s(5); height: island.s(5); radius: island.s(3); color: island.peach; anchors.verticalCenter: parent.verticalCenter }
                                            Text { text: island.gameGpuTemp + "°C"; font.family: "JetBrains Mono"; font.pixelSize: island.s(11); font.weight: Font.Black; color: island.peach }
                                        }
                                    }
                                    Item { Layout.fillWidth: true }
                                    Text { text: "CPU · TEMP"; font.family: "JetBrains Mono"; font.pixelSize: island.s(8); font.weight: Font.Black; color: Theme.overlay0; font.letterSpacing: island.s(0.8) }
                                }
                                LineGraph { width: parent.width; height: island.s(46); graphVals: root.histCpu; graphColor: island.mauve; graphMax: 100; graphVals2: root.histTemp; graphColor2: island.peach; graphMax2: 100 }
                                RowLayout {
                                    width: parent.width
                                    readonly property var f: root.histCpu.filter(function(v){ return v > 0 })
                                    readonly property int mn: f.length ? Math.min.apply(null, f) : 0
                                    readonly property int mx: f.length ? Math.max.apply(null, f) : 0
                                    readonly property int av: f.length ? Math.round(f.reduce(function(a,b){return a+b},0)/f.length) : 0
                                    Text { text: "MIN  " + parent.mn + "%"; font.family: "JetBrains Mono"; font.pixelSize: island.s(8); color: Theme.overlay0 }
                                    Item { Layout.fillWidth: true }
                                    Text { text: "AVG  " + parent.av + "%"; font.family: "JetBrains Mono"; font.pixelSize: island.s(8); color: Theme.subtext0; font.weight: Font.Bold }
                                    Item { Layout.fillWidth: true }
                                    Text { text: "MAX  " + parent.mx + "%"; font.family: "JetBrains Mono"; font.pixelSize: island.s(8); color: Theme.overlay0 }
                                }
                            }
                        }

                        // GPU graph card
                        Rectangle {
                            width: parent.width - island.s(28); radius: island.s(12)
                            color: Qt.rgba(island.surface0.r, island.surface0.g, island.surface0.b, 0.55)
                            border.width: 1; border.color: Qt.rgba(island.surface1.r, island.surface1.g, island.surface1.b, 0.8)
                            implicitHeight: grGpu.implicitHeight + island.s(20); clip: true

                            Column {
                                id: grGpu
                                anchors { left: parent.left; right: parent.right; top: parent.top; margins: island.s(12) }
                                spacing: island.s(6)

                                RowLayout {
                                    width: parent.width
                                    Text { text: island.gameGpu + "%"; font.family: "JetBrains Mono"; font.pixelSize: island.s(12); font.weight: Font.Black; color: island.blue }
                                    Item { Layout.fillWidth: true }
                                    Text { text: "GPU"; font.family: "JetBrains Mono"; font.pixelSize: island.s(8); font.weight: Font.Black; color: Theme.overlay0; font.letterSpacing: island.s(0.8) }
                                }
                                LineGraph { width: parent.width; height: island.s(46); graphVals: root.histGpu; graphColor: island.blue; graphMax: 100 }
                                RowLayout {
                                    width: parent.width
                                    readonly property var f: root.histGpu.filter(function(v){ return v > 0 })
                                    readonly property int mn: f.length ? Math.min.apply(null, f) : 0
                                    readonly property int mx: f.length ? Math.max.apply(null, f) : 0
                                    readonly property int av: f.length ? Math.round(f.reduce(function(a,b){return a+b},0)/f.length) : 0
                                    Text { text: "MIN  " + parent.mn + "%"; font.family: "JetBrains Mono"; font.pixelSize: island.s(8); color: Theme.overlay0 }
                                    Item { Layout.fillWidth: true }
                                    Text { text: "AVG  " + parent.av + "%"; font.family: "JetBrains Mono"; font.pixelSize: island.s(8); color: Theme.subtext0; font.weight: Font.Bold }
                                    Item { Layout.fillWidth: true }
                                    Text { text: "MAX  " + parent.mx + "%"; font.family: "JetBrains Mono"; font.pixelSize: island.s(8); color: Theme.overlay0 }
                                }
                            }
                        }

                        // PING graph card
                        Rectangle {
                            readonly property color pingClr: island.gamePing < 30 ? island.green : island.gamePing < 70 ? island.yellow : island.red
                            width: parent.width - island.s(28); radius: island.s(12)
                            color: Qt.rgba(island.surface0.r, island.surface0.g, island.surface0.b, 0.55)
                            border.width: 1; border.color: Qt.rgba(island.surface1.r, island.surface1.g, island.surface1.b, 0.8)
                            implicitHeight: grPing.implicitHeight + island.s(20); clip: true

                            Column {
                                id: grPing
                                anchors { left: parent.left; right: parent.right; top: parent.top; margins: island.s(12) }
                                spacing: island.s(6)

                                RowLayout {
                                    width: parent.width
                                    Text { text: island.gamePing + " ms"; font.family: "JetBrains Mono"; font.pixelSize: island.s(12); font.weight: Font.Black; color: island.gamePing < 30 ? island.green : island.gamePing < 70 ? island.yellow : island.red }
                                    Item { Layout.fillWidth: true }
                                    Text { text: "PING"; font.family: "JetBrains Mono"; font.pixelSize: island.s(8); font.weight: Font.Black; color: Theme.overlay0; font.letterSpacing: island.s(0.8) }
                                }
                                LineGraph { width: parent.width; height: island.s(42); graphVals: root.histPing; graphMax: 100; graphColor: island.gamePing < 30 ? island.green : island.gamePing < 70 ? island.yellow : island.red }
                                RowLayout {
                                    width: parent.width
                                    readonly property var f: root.histPing.filter(function(v){ return v > 0 })
                                    readonly property int mn: f.length ? Math.min.apply(null, f) : 0
                                    readonly property int mx: f.length ? Math.max.apply(null, f) : 0
                                    readonly property int av: f.length ? Math.round(f.reduce(function(a,b){return a+b},0)/f.length) : 0
                                    Text { text: "MIN  " + parent.mn + "ms"; font.family: "JetBrains Mono"; font.pixelSize: island.s(8); color: Theme.overlay0 }
                                    Item { Layout.fillWidth: true }
                                    Text { text: "AVG  " + parent.av + "ms"; font.family: "JetBrains Mono"; font.pixelSize: island.s(8); color: Theme.subtext0; font.weight: Font.Bold }
                                    Item { Layout.fillWidth: true }
                                    Text { text: "MAX  " + parent.mx + "ms"; font.family: "JetBrains Mono"; font.pixelSize: island.s(8); color: Theme.overlay0 }
                                }
                            }
                        }
                    }
                }
            }

            // ── CONTROLS ──────────────────────────────────────────────────
            Item {
                anchors.fill: parent; visible: root.currentTab === 2; clip: true
                opacity: root.currentTab === 2 ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                Flickable {
                    anchors.fill: parent; contentHeight: ctrlCol.implicitHeight; contentWidth: width; clip: true

                    Column {
                        id: ctrlCol
                        width: parent.width
                        leftPadding: island.s(16); rightPadding: island.s(16)
                        topPadding: island.s(4); bottomPadding: island.s(16)
                        spacing: island.s(6)

                        // Section: GAMEPLAY
                        Text {
                            text: "GAMEPLAY"
                            font.family: "JetBrains Mono"; font.pixelSize: island.s(8); font.weight: Font.Black
                            font.letterSpacing: island.s(1.0); color: Theme.overlay0
                            topPadding: island.s(2); bottomPadding: island.s(4)
                            leftPadding: island.s(2)
                            width: parent.width - island.s(32)
                        }
                        ToggleRow {
                            label: "Do Not Disturb"; icon: island.dndEnabled ? "󰂛" : "󰂚"; active: island.dndEnabled; activeColor: island.mauve
                            onToggled: { island.dndEnabled = !island.dndEnabled; island.exec("mkdir -p ~/.cache && echo '" + (island.dndEnabled ? "1" : "0") + "' > ~/.cache/qs_dnd") }
                        }
                        ToggleRow {
                            label: "Always on Top"; icon: "󰁞"; active: island.alwaysOnTop; activeColor: island.peach
                            onToggled: { island.alwaysOnTop = !island.alwaysOnTop; island.exec("mkdir -p ~/.cache && echo '" + (island.alwaysOnTop ? "1" : "0") + "' > ~/.cache/qs_island_aot") }
                        }

                        Item { width: 1; height: island.s(8) }

                        // Section: SYSTEM
                        Text {
                            text: "SYSTEM"
                            font.family: "JetBrains Mono"; font.pixelSize: island.s(8); font.weight: Font.Black
                            font.letterSpacing: island.s(1.0); color: Theme.overlay0
                            topPadding: island.s(2); bottomPadding: island.s(4)
                            leftPadding: island.s(2)
                            width: parent.width - island.s(32)
                        }
                        ToggleRow {
                            label: "Performance Mode"; icon: "󰓅"; active: island.gamePerfMode; activeColor: island.green
                            onToggled: { island.gamePerfMode = !island.gamePerfMode; island.exec("powerprofilesctl set " + (island.gamePerfMode ? "performance" : "balanced")) }
                        }
                        ToggleRow {
                            label: "Mute Microphone"; icon: island.gameMicMuted ? "󰍭" : "󰍬"; active: island.gameMicMuted; activeColor: island.red
                            onToggled: { island.gameMicMuted = !island.gameMicMuted; island.exec("wpctl set-mute @DEFAULT_SOURCE@ toggle") }
                        }

                        // Divider
                        Item { width: 1; height: island.s(10) }
                        Rectangle {
                            width: parent.width - island.s(32); height: 1
                            color: Qt.rgba(island.text.r, island.text.g, island.text.b, 0.07)
                        }
                        Item { width: 1; height: island.s(10) }

                        // End Session — destructive
                        Rectangle {
                            id: endSessionBtn
                            width: parent.width - island.s(32); height: island.s(44); radius: island.s(12)
                            color: Qt.rgba(island.red.r, island.red.g, island.red.b, 0.08)
                            border.width: 1
                            border.color: Qt.rgba(island.red.r, island.red.g, island.red.b, 0.26)
                            Behavior on color { ColorAnimation { duration: 120 } }

                            Text {
                                anchors.centerIn: parent
                                text: "End Session"
                                font.family: Theme.fontUI; font.pixelSize: island.s(14); font.weight: Font.Medium
                                color: island.red
                            }

                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                onPressed:  endSessionBtn.color = Qt.rgba(island.red.r, island.red.g, island.red.b, 0.18)
                                onReleased: endSessionBtn.color = Qt.rgba(island.red.r, island.red.g, island.red.b, 0.08)
                                onClicked:  island.gameActive = false
                            }
                        }
                    }
                }
            }
        }
    }
}
