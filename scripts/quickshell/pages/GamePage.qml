import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import "../themes"

Item {
    id: root
    property var island
    clip: true
    property int currentTab: 0

    // ── Open state ────────────────────────────────────────────────────────
    readonly property bool _open: island.expanded && island.currentPage === "game"

    // Entry Y offsets (one per animated element)
    property real _hdrEy:  0
    property real _segEy:  0
    property real _ov0Ey:  0
    property real _ov1Ey:  0
    property real _ov2Ey:  0
    property real _gr0Ey:  0
    property real _gr1Ey:  0
    property real _gr2Ey:  0
    property real _gr3Ey:  0
    property real _ct0Ey:  0
    property real _ct1Ey:  0
    property real _ct2Ey:  0
    property real _ct3Ey:  0
    property real _ct4Ey:  0
    property real _ct5Ey:  0
    property real _ct6Ey:  0

    on_OpenChanged: {
        if (!_open || Theme.reduceMotion) return
        var d = island.s(14)
        _hdrEy = d; hdrAnim.from = d; hdrAnim.restart()
        _segEy = d; tSeg.restart()
        _ov0Ey = island.s(16); tOv0.restart()
        _ov1Ey = island.s(16); tOv1.restart()
        _ov2Ey = island.s(16); tOv2.restart()
    }

    onCurrentTabChanged: {
        if (!_open || Theme.reduceMotion) return
        if (currentTab === 1) {
            var d = island.s(14)
            _gr0Ey = d; gr0Anim.from = d; gr0Anim.restart()
            _gr1Ey = d; tGr1.restart()
            _gr2Ey = d; tGr2.restart()
            _gr3Ey = d; tGr3.restart()
        }
        if (currentTab === 2) {
            var c = island.s(12)
            _ct0Ey = c; ct0Anim.from = c; ct0Anim.restart()
            _ct1Ey = c; tCt1.restart()
            _ct2Ey = c; tCt2.restart()
            _ct3Ey = c; tCt3.restart()
            _ct4Ey = c; tCt4.restart()
            _ct5Ey = c; tCt5.restart()
            _ct6Ey = c; tCt6.restart()
        }
    }

    // ── Stagger timers ────────────────────────────────────────────────────
    Timer { id: tSeg;  interval: 60;  onTriggered: { segAnim.from  = root._segEy;  segAnim.restart()  } }
    Timer { id: tOv0;  interval: 100; onTriggered: { ov0Anim.from  = root._ov0Ey;  ov0Anim.restart()  } }
    Timer { id: tOv1;  interval: 170; onTriggered: { ov1Anim.from  = root._ov1Ey;  ov1Anim.restart()  } }
    Timer { id: tOv2;  interval: 240; onTriggered: { ov2Anim.from  = root._ov2Ey;  ov2Anim.restart()  } }
    Timer { id: tGr1;  interval: 70;  onTriggered: { gr1Anim.from  = root._gr1Ey;  gr1Anim.restart()  } }
    Timer { id: tGr2;  interval: 140; onTriggered: { gr2Anim.from  = root._gr2Ey;  gr2Anim.restart()  } }
    Timer { id: tGr3;  interval: 210; onTriggered: { gr3Anim.from  = root._gr3Ey;  gr3Anim.restart()  } }
    Timer { id: tCt1;  interval: 55;  onTriggered: { ct1Anim.from  = root._ct1Ey;  ct1Anim.restart()  } }
    Timer { id: tCt2;  interval: 105; onTriggered: { ct2Anim.from  = root._ct2Ey;  ct2Anim.restart()  } }
    Timer { id: tCt3;  interval: 155; onTriggered: { ct3Anim.from  = root._ct3Ey;  ct3Anim.restart()  } }
    Timer { id: tCt4;  interval: 205; onTriggered: { ct4Anim.from  = root._ct4Ey;  ct4Anim.restart()  } }
    Timer { id: tCt5;  interval: 255; onTriggered: { ct5Anim.from  = root._ct5Ey;  ct5Anim.restart()  } }
    Timer { id: tCt6;  interval: 320; onTriggered: { ct6Anim.from  = root._ct6Ey;  ct6Anim.restart()  } }

    // ── Entry animations ──────────────────────────────────────────────────
    NumberAnimation { id: hdrAnim; target: root; property: "_hdrEy"; to: 0; duration: 680; easing.type: Easing.OutExpo }
    NumberAnimation { id: segAnim; target: root; property: "_segEy"; to: 0; duration: 680; easing.type: Easing.OutExpo }
    NumberAnimation { id: ov0Anim; target: root; property: "_ov0Ey"; to: 0; duration: 720; easing.type: Easing.OutExpo }
    NumberAnimation { id: ov1Anim; target: root; property: "_ov1Ey"; to: 0; duration: 720; easing.type: Easing.OutExpo }
    NumberAnimation { id: ov2Anim; target: root; property: "_ov2Ey"; to: 0; duration: 720; easing.type: Easing.OutExpo }
    NumberAnimation { id: gr0Anim; target: root; property: "_gr0Ey"; to: 0; duration: 680; easing.type: Easing.OutExpo }
    NumberAnimation { id: gr1Anim; target: root; property: "_gr1Ey"; to: 0; duration: 680; easing.type: Easing.OutExpo }
    NumberAnimation { id: gr2Anim; target: root; property: "_gr2Ey"; to: 0; duration: 680; easing.type: Easing.OutExpo }
    NumberAnimation { id: gr3Anim; target: root; property: "_gr3Ey"; to: 0; duration: 680; easing.type: Easing.OutExpo }
    NumberAnimation { id: ct0Anim; target: root; property: "_ct0Ey"; to: 0; duration: 600; easing.type: Easing.OutExpo }
    NumberAnimation { id: ct1Anim; target: root; property: "_ct1Ey"; to: 0; duration: 600; easing.type: Easing.OutExpo }
    NumberAnimation { id: ct2Anim; target: root; property: "_ct2Ey"; to: 0; duration: 600; easing.type: Easing.OutExpo }
    NumberAnimation { id: ct3Anim; target: root; property: "_ct3Ey"; to: 0; duration: 600; easing.type: Easing.OutExpo }
    NumberAnimation { id: ct4Anim; target: root; property: "_ct4Ey"; to: 0; duration: 600; easing.type: Easing.OutExpo }
    NumberAnimation { id: ct5Anim; target: root; property: "_ct5Ey"; to: 0; duration: 600; easing.type: Easing.OutExpo }
    NumberAnimation { id: ct6Anim; target: root; property: "_ct6Ey"; to: 0; duration: 600; easing.type: Easing.OutExpo }

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

    // ── History arrays ────────────────────────────────────────────────────
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
        id: tc
        property string label:       ""
        property string icon:        ""
        property bool   active:      false
        property color  activeColor: island.mauve
        signal toggled()

        height: island.s(44); radius: island.s(10)
        color: active
            ? Qt.rgba(activeColor.r, activeColor.g, activeColor.b, 0.12)
            : island.surface0
        border.width: 1
        border.color: active
            ? Qt.rgba(activeColor.r, activeColor.g, activeColor.b, 0.35)
            : island.surface1
        Behavior on color        { ColorAnimation { duration: 180 } }
        Behavior on border.color { ColorAnimation { duration: 180 } }

        RowLayout {
            anchors.fill: parent; anchors.margins: island.s(14); spacing: island.s(12)
            Text {
                text: tc.icon; font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(16)
                color: tc.active ? tc.activeColor : Theme.overlay0
                Behavior on color { ColorAnimation { duration: 180 } }
            }
            Text {
                text: tc.label; font.family: Theme.fontUI; font.pixelSize: island.s(13); font.weight: Font.Medium
                color: tc.active ? island.text : island.subtext0; Layout.fillWidth: true
                Behavior on color { ColorAnimation { duration: 180 } }
            }
            Rectangle {
                width: island.s(36); height: island.s(20); radius: island.s(10)
                color: tc.active ? tc.activeColor : island.surface1
                Behavior on color { ColorAnimation { duration: 180 } }
                Rectangle {
                    width: island.s(14); height: island.s(14); radius: island.s(7)
                    color: Qt.rgba(0.97, 0.96, 1.0, 1.0)
                    anchors.verticalCenter: parent.verticalCenter
                    x: tc.active ? island.s(19) : island.s(3)
                    Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                }
            }
        }
        MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: tc.toggled() }
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
                series(parent.graphVals, parent.graphColor, parent.graphMax)
                series(parent.graphVals2, parent.graphColor2, parent.graphMax2)
            }
        }
    }

    // ── Main layout ───────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent; spacing: 0

        // ── Header ────────────────────────────────────────────────────────
        Item {
            id: hdrItem
            Layout.fillWidth: true
            height: island.s(68)
            transform: Translate { y: root._hdrEy }

            RowLayout {
                anchors {
                    left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter
                    leftMargin: island.s(14); rightMargin: island.s(14)
                }
                spacing: island.s(10)

                Item {
                    width: island.s(40); height: island.s(40); Layout.alignment: Qt.AlignVCenter

                    // Mask shape
                    Item {
                        id: gameCoverMask; anchors.fill: parent; visible: false; layer.enabled: true
                        Rectangle { anchors.fill: parent; radius: island.s(14); color: "white" }
                    }

                    // Background surface
                    Rectangle { anchors.fill: parent; radius: island.s(14); color: island.surface1 }

                    // Image clipped via mask
                    Item {
                        anchors.fill: parent; layer.enabled: true
                        layer.effect: MultiEffect {
                            maskEnabled: true; maskSource: gameCoverMask
                            maskThresholdMin: 0.5; maskSpreadAtMin: 1.0
                        }
                        Image {
                            id: thumbImg; source: island.gameCover
                            anchors.fill: parent; fillMode: Image.PreserveAspectCrop
                            asynchronous: true; smooth: true; mipmap: true
                            opacity: status === Image.Ready ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                        }
                        Text {
                            anchors.centerIn: parent; text: "󰊗"
                            font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(18)
                            color: Theme.overlay0; visible: thumbImg.opacity < 0.5
                        }
                    }

                    // Thin silver border overlay
                    Rectangle {
                        anchors.fill: parent; radius: island.s(14)
                        color: "transparent"
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.22)
                    }
                }

                Column {
                    Layout.fillWidth: true; spacing: island.s(3)
                    Row {
                        spacing: island.s(5)
                        Rectangle {
                            width: island.s(6); height: island.s(6); radius: island.s(3)
                            color: root.healthColor; anchors.verticalCenter: parent.verticalCenter
                            Behavior on color { ColorAnimation { duration: 400 } }
                        }
                        Text {
                            text: "LIVE"; font.family: "JetBrains Mono"; font.pixelSize: island.s(8); font.weight: Font.Black
                            font.letterSpacing: island.s(1.4); color: root.healthColor; anchors.verticalCenter: parent.verticalCenter
                            Behavior on color { ColorAnimation { duration: 400 } }
                        }
                    }
                    Text {
                        text: island.gameName || "Unknown Game"
                        font.family: Theme.fontUI; font.pixelSize: island.s(17); font.weight: Font.ExtraBold
                        color: island.text; elide: Text.ElideRight; width: parent.width
                    }
                }

                Rectangle {
                    height: island.s(26); radius: island.s(13)
                    width: timerRow.implicitWidth + island.s(16)
                    color: island.surface0; border.width: 1; border.color: island.surface1
                    Layout.alignment: Qt.AlignVCenter
                    Row {
                        id: timerRow; anchors.centerIn: parent; spacing: island.s(5)
                        Text { text: "󱎫"; font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(10); color: Theme.overlay0; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: root.sessionTime; font.family: "JetBrains Mono"; font.pixelSize: island.s(11); font.weight: Font.Bold; color: Theme.subtext1; anchors.verticalCenter: parent.verticalCenter }
                    }
                }
            }
        }

        // ── Segmented control ─────────────────────────────────────────────
        Item {
            id: segItem
            Layout.fillWidth: true
            Layout.leftMargin: island.s(14); Layout.rightMargin: island.s(14)
            Layout.bottomMargin: island.s(10)
            height: island.s(32)
            transform: Translate { y: root._segEy }

            Rectangle {
                anchors.fill: parent; radius: island.s(10)
                color: island.surface0; border.width: 1; border.color: island.surface1

                Rectangle {
                    id: segPill
                    height: parent.height - island.s(4); radius: island.s(8)
                    width: parent.width / 3 - island.s(4)
                    x: (parent.width / 3) * root.currentTab + island.s(2)
                    anchors.verticalCenter: parent.verticalCenter
                    color: island.surface1
                    border.width: 1; border.color: Qt.rgba(island.text.r, island.text.g, island.text.b, 0.09)
                    Behavior on x { SpringAnimation { spring: 6; damping: 0.82 } }
                }

                Row {
                    anchors.fill: parent
                    Repeater {
                        model: ["Overview", "Graphs", "Controls"]
                        delegate: Item {
                            width: parent.width / 3; height: parent.height
                            Text {
                                anchors.centerIn: parent; text: modelData
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
                anchors.fill: parent; visible: opacity > 0.001; clip: true
                opacity: root.currentTab === 0 ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                Flickable {
                    anchors.fill: parent; contentHeight: ovCol.implicitHeight; contentWidth: width; clip: true

                    Column {
                        id: ovCol; width: parent.width
                        leftPadding: island.s(14); rightPadding: island.s(14)
                        bottomPadding: island.s(14); spacing: island.s(8)

                        // FPS hero
                        Rectangle {
                            id: fpsCard
                            width: parent.width - island.s(28); height: island.s(94)
                            radius: island.s(10); color: island.surface0
                            border.width: 1; border.color: island.surface1
                            transform: Translate { y: root._ov0Ey }

                            RowLayout {
                                anchors.fill: parent; anchors.margins: island.s(16); spacing: island.s(14)
                                Column {
                                    Layout.fillWidth: true; spacing: island.s(8)
                                    Row {
                                        spacing: island.s(5)
                                        Text {
                                            text: island.gameFps
                                            font.family: "JetBrains Mono"; font.pixelSize: island.s(46); font.weight: Font.Black
                                            color: root.healthColor
                                            Behavior on color { ColorAnimation { duration: 400 } }
                                        }
                                        Column {
                                            anchors.bottom: parent.bottom; anchors.bottomMargin: island.s(8); spacing: island.s(1)
                                            Text { text: "fps"; font.family: "JetBrains Mono"; font.pixelSize: island.s(12); color: Theme.overlay0 }
                                            Text { text: "/ " + root.fpsCeiling; font.family: "JetBrains Mono"; font.pixelSize: island.s(9); color: Theme.overlay0 }
                                        }
                                    }
                                    Item {
                                        width: parent.width; height: island.s(4)
                                        Rectangle {
                                            anchors.fill: parent; radius: island.s(2)
                                            color: Qt.rgba(root.healthColor.r, root.healthColor.g, root.healthColor.b, 0.16)
                                        }
                                        Rectangle {
                                            width: Math.max(0, Math.min(1, island.gameFps / root.fpsCeiling)) * parent.width
                                            height: parent.height; radius: island.s(2); color: root.healthColor
                                            Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                                            Behavior on color { ColorAnimation { duration: 400 } }
                                        }
                                    }
                                }
                                Column {
                                    spacing: island.s(2); Layout.alignment: Qt.AlignVCenter
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter; text: "FRAME"
                                        font.family: "JetBrains Mono"; font.pixelSize: island.s(7); font.weight: Font.Black
                                        font.letterSpacing: island.s(0.7); color: Theme.overlay0
                                    }
                                    Row {
                                        spacing: island.s(2)
                                        Text {
                                            text: (1000 / Math.max(1, island.gameFps)).toFixed(1)
                                            font.family: "JetBrains Mono"; font.pixelSize: island.s(20); font.weight: Font.Black; color: Theme.subtext1
                                        }
                                        Text {
                                            text: "ms"; font.family: "JetBrains Mono"; font.pixelSize: island.s(9); color: Theme.overlay0
                                            anchors.bottom: parent.bottom; anchors.bottomMargin: island.s(2)
                                        }
                                    }
                                }
                            }
                        }

                        // PING · GPU · CPU
                        Rectangle {
                            id: statsCard
                            width: parent.width - island.s(28); height: island.s(78)
                            radius: island.s(10); color: island.surface0
                            border.width: 1; border.color: island.surface1
                            transform: Translate { y: root._ov1Ey }

                            Row {
                                anchors.fill: parent
                                Repeater {
                                    model: ListModel {
                                        ListElement { lbl: "PING"; unit: "ms" }
                                        ListElement { lbl: "GPU";  unit: "%" }
                                        ListElement { lbl: "CPU";  unit: "%" }
                                    }
                                    delegate: Item {
                                        width: parent.width / 3; height: parent.height
                                        readonly property real sv: lbl === "PING" ? island.gamePing : lbl === "GPU" ? island.gameGpu : island.gameCpu
                                        readonly property color sc: lbl === "PING"
                                            ? (island.gamePing < 30 ? island.green : island.gamePing < 70 ? island.yellow : island.red)
                                            : lbl === "GPU" ? island.blue : island.mauve
                                        Rectangle {
                                            visible: index > 0; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                                            width: 1; height: island.s(36); color: island.surface2
                                        }
                                        Column {
                                            anchors.centerIn: parent; spacing: island.s(5)
                                            Row {
                                                anchors.horizontalCenter: parent.horizontalCenter; spacing: island.s(2)
                                                Text {
                                                    text: sv; font.family: "JetBrains Mono"; font.pixelSize: island.s(22); font.weight: Font.Black
                                                    color: sc; anchors.baseline: uLbl.baseline
                                                    Behavior on color { ColorAnimation { duration: 400 } }
                                                }
                                                Text {
                                                    id: uLbl; text: unit; font.family: "JetBrains Mono"; font.pixelSize: island.s(9); color: Theme.overlay0
                                                    anchors.bottom: parent.bottom; anchors.bottomMargin: island.s(3)
                                                }
                                            }
                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter; text: lbl
                                                font.family: "JetBrains Mono"; font.pixelSize: island.s(8); font.weight: Font.Black
                                                font.letterSpacing: island.s(0.8); color: Theme.overlay0
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // TEMP · RAM · VRAM
                        Rectangle {
                            id: secCard
                            width: parent.width - island.s(28); height: island.s(52)
                            radius: island.s(10); color: island.surface0
                            border.width: 1; border.color: island.surface1
                            transform: Translate { y: root._ov2Ey }

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
                                        readonly property real sv: slbl === "TEMP" ? island.gameGpuTemp : slbl === "RAM" ? island.gameRam : island.gameVram
                                        readonly property color sc: slbl === "TEMP" ? (island.gameGpuTemp > 85 ? island.peach : island.teal) : slbl === "RAM" ? island.teal : island.blue
                                        Rectangle {
                                            visible: index > 0; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                                            width: 1; height: island.s(24); color: island.surface2
                                        }
                                        Column {
                                            anchors.centerIn: parent; spacing: island.s(3)
                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter; text: slbl
                                                font.family: "JetBrains Mono"; font.pixelSize: island.s(7); font.weight: Font.Black
                                                font.letterSpacing: island.s(0.7); color: Theme.overlay0
                                            }
                                            Row {
                                                anchors.horizontalCenter: parent.horizontalCenter; spacing: island.s(1)
                                                Text {
                                                    text: sv; font.family: "JetBrains Mono"; font.pixelSize: island.s(16); font.weight: Font.Black
                                                    color: sc; Behavior on color { ColorAnimation { duration: 400 } }
                                                }
                                                Text {
                                                    text: sunit; font.family: "JetBrains Mono"; font.pixelSize: island.s(8); color: Theme.overlay0
                                                    anchors.bottom: parent.bottom; anchors.bottomMargin: island.s(2)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Row {
                            spacing: island.s(12)
                            Repeater {
                                model: [
                                    { dot: island.green,  label: ">100fps  <22ms" },
                                    { dot: island.yellow, label: ">60fps  <45ms" },
                                    { dot: island.red,    label: "below" }
                                ]
                                Row {
                                    required property var modelData; spacing: island.s(5)
                                    Rectangle { width: island.s(5); height: island.s(5); radius: island.s(3); color: modelData.dot; anchors.verticalCenter: parent.verticalCenter }
                                    Text { text: modelData.label; font.family: "JetBrains Mono"; font.pixelSize: island.s(8); color: Theme.overlay0; anchors.verticalCenter: parent.verticalCenter }
                                }
                            }
                        }
                    }
                }
            }

            // ── GRAPHS ────────────────────────────────────────────────────
            Item {
                anchors.fill: parent; visible: opacity > 0.001; clip: true
                opacity: root.currentTab === 1 ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                Flickable {
                    anchors.fill: parent; contentHeight: grCol.implicitHeight; contentWidth: width; clip: true

                    Column {
                        id: grCol; width: parent.width
                        leftPadding: island.s(14); rightPadding: island.s(14)
                        topPadding: island.s(4); bottomPadding: island.s(14); spacing: island.s(8)

                        Rectangle {
                            id: gFpsCard
                            width: parent.width - island.s(28); radius: island.s(10)
                            color: island.surface0; border.width: 1; border.color: island.surface1
                            implicitHeight: gFps.implicitHeight + island.s(20); clip: true
                            transform: Translate { y: root._gr0Ey }
                            Column {
                                id: gFps
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
                                    Text { text: "MIN  " + (parent.f.length ? Math.min.apply(null, parent.f) : 0);           font.family: "JetBrains Mono"; font.pixelSize: island.s(8); color: Theme.overlay0 }
                                    Item { Layout.fillWidth: true }
                                    Text { text: "AVG  " + (parent.f.length ? Math.round(parent.f.reduce(function(a,b){return a+b},0)/parent.f.length) : 0); font.family: "JetBrains Mono"; font.pixelSize: island.s(8); font.weight: Font.Bold; color: Theme.subtext0 }
                                    Item { Layout.fillWidth: true }
                                    Text { text: "MAX  " + (parent.f.length ? Math.max.apply(null, parent.f) : 0);           font.family: "JetBrains Mono"; font.pixelSize: island.s(8); color: Theme.overlay0 }
                                }
                            }
                        }

                        Rectangle {
                            id: gCpuCard
                            width: parent.width - island.s(28); radius: island.s(10)
                            color: island.surface0; border.width: 1; border.color: island.surface1
                            implicitHeight: gCpu.implicitHeight + island.s(20); clip: true
                            transform: Translate { y: root._gr1Ey }
                            Column {
                                id: gCpu
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
                                    Text { text: "MIN  " + (parent.f.length ? Math.min.apply(null, parent.f) : 0) + "%";           font.family: "JetBrains Mono"; font.pixelSize: island.s(8); color: Theme.overlay0 }
                                    Item { Layout.fillWidth: true }
                                    Text { text: "AVG  " + (parent.f.length ? Math.round(parent.f.reduce(function(a,b){return a+b},0)/parent.f.length) : 0) + "%"; font.family: "JetBrains Mono"; font.pixelSize: island.s(8); font.weight: Font.Bold; color: Theme.subtext0 }
                                    Item { Layout.fillWidth: true }
                                    Text { text: "MAX  " + (parent.f.length ? Math.max.apply(null, parent.f) : 0) + "%";           font.family: "JetBrains Mono"; font.pixelSize: island.s(8); color: Theme.overlay0 }
                                }
                            }
                        }

                        Rectangle {
                            id: gGpuCard
                            width: parent.width - island.s(28); radius: island.s(10)
                            color: island.surface0; border.width: 1; border.color: island.surface1
                            implicitHeight: gGpu.implicitHeight + island.s(20); clip: true
                            transform: Translate { y: root._gr2Ey }
                            Column {
                                id: gGpu
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
                                    Text { text: "MIN  " + (parent.f.length ? Math.min.apply(null, parent.f) : 0) + "%";           font.family: "JetBrains Mono"; font.pixelSize: island.s(8); color: Theme.overlay0 }
                                    Item { Layout.fillWidth: true }
                                    Text { text: "AVG  " + (parent.f.length ? Math.round(parent.f.reduce(function(a,b){return a+b},0)/parent.f.length) : 0) + "%"; font.family: "JetBrains Mono"; font.pixelSize: island.s(8); font.weight: Font.Bold; color: Theme.subtext0 }
                                    Item { Layout.fillWidth: true }
                                    Text { text: "MAX  " + (parent.f.length ? Math.max.apply(null, parent.f) : 0) + "%";           font.family: "JetBrains Mono"; font.pixelSize: island.s(8); color: Theme.overlay0 }
                                }
                            }
                        }

                        Rectangle {
                            id: gPingCard
                            width: parent.width - island.s(28); radius: island.s(10)
                            color: island.surface0; border.width: 1; border.color: island.surface1
                            implicitHeight: gPing.implicitHeight + island.s(20); clip: true
                            transform: Translate { y: root._gr3Ey }
                            Column {
                                id: gPing
                                readonly property color pingClr: island.gamePing < 30 ? island.green : island.gamePing < 70 ? island.yellow : island.red
                                anchors { left: parent.left; right: parent.right; top: parent.top; margins: island.s(12) }
                                spacing: island.s(6)
                                RowLayout {
                                    width: parent.width
                                    Text { text: island.gamePing + " ms"; font.family: "JetBrains Mono"; font.pixelSize: island.s(12); font.weight: Font.Black; color: gPing.pingClr; Behavior on color { ColorAnimation { duration: 400 } } }
                                    Item { Layout.fillWidth: true }
                                    Text { text: "PING"; font.family: "JetBrains Mono"; font.pixelSize: island.s(8); font.weight: Font.Black; color: Theme.overlay0; font.letterSpacing: island.s(0.8) }
                                }
                                LineGraph { width: parent.width; height: island.s(42); graphVals: root.histPing; graphMax: 100; graphColor: gPing.pingClr }
                                RowLayout {
                                    width: parent.width
                                    readonly property var f: root.histPing.filter(function(v){ return v > 0 })
                                    Text { text: "MIN  " + (parent.f.length ? Math.min.apply(null, parent.f) : 0) + "ms";           font.family: "JetBrains Mono"; font.pixelSize: island.s(8); color: Theme.overlay0 }
                                    Item { Layout.fillWidth: true }
                                    Text { text: "AVG  " + (parent.f.length ? Math.round(parent.f.reduce(function(a,b){return a+b},0)/parent.f.length) : 0) + "ms"; font.family: "JetBrains Mono"; font.pixelSize: island.s(8); font.weight: Font.Bold; color: Theme.subtext0 }
                                    Item { Layout.fillWidth: true }
                                    Text { text: "MAX  " + (parent.f.length ? Math.max.apply(null, parent.f) : 0) + "ms";           font.family: "JetBrains Mono"; font.pixelSize: island.s(8); color: Theme.overlay0 }
                                }
                            }
                        }
                    }
                }
            }

            // ── CONTROLS ──────────────────────────────────────────────────
            Item {
                anchors.fill: parent; visible: opacity > 0.001; clip: true
                opacity: root.currentTab === 2 ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                Flickable {
                    anchors.fill: parent; contentHeight: ctrlCol.implicitHeight; contentWidth: width; clip: true

                    Column {
                        id: ctrlCol; width: parent.width
                        leftPadding: island.s(14); rightPadding: island.s(14)
                        topPadding: island.s(4); bottomPadding: island.s(16); spacing: island.s(6)

                        Text {
                            id: ctLabel0
                            text: "GAMEPLAY"; font.family: "JetBrains Mono"; font.pixelSize: island.s(8); font.weight: Font.Black
                            font.letterSpacing: island.s(1.0); color: Theme.overlay0
                            topPadding: island.s(2); bottomPadding: island.s(4); leftPadding: island.s(2)
                            width: parent.width - island.s(28)
                            transform: Translate { y: root._ct0Ey }
                        }
                        ToggleRow {
                            id: dndRow
                            width: parent.width - island.s(28)
                            label: "Do Not Disturb"; icon: island.dndEnabled ? "󰂛" : "󰂚"
                            active: island.dndEnabled; activeColor: island.mauve
                            transform: Translate { y: root._ct1Ey }
                            onToggled: { island.dndEnabled = !island.dndEnabled; island.exec("mkdir -p ~/.cache && echo '" + (island.dndEnabled ? "1" : "0") + "' > ~/.cache/qs_dnd") }
                        }
                        ToggleRow {
                            id: aotRow
                            width: parent.width - island.s(28)
                            label: "Always on Top"; icon: "󰁞"
                            active: island.alwaysOnTop; activeColor: island.peach
                            transform: Translate { y: root._ct2Ey }
                            onToggled: { island.alwaysOnTop = !island.alwaysOnTop; island.exec("mkdir -p ~/.cache && echo '" + (island.alwaysOnTop ? "1" : "0") + "' > ~/.cache/qs_island_aot") }
                        }

                        Item { width: 1; height: island.s(8) }

                        Text {
                            id: ctLabel1
                            text: "SYSTEM"; font.family: "JetBrains Mono"; font.pixelSize: island.s(8); font.weight: Font.Black
                            font.letterSpacing: island.s(1.0); color: Theme.overlay0
                            topPadding: island.s(2); bottomPadding: island.s(4); leftPadding: island.s(2)
                            width: parent.width - island.s(28)
                            transform: Translate { y: root._ct3Ey }
                        }
                        ToggleRow {
                            id: perfRow
                            width: parent.width - island.s(28)
                            label: "Performance Mode"; icon: "󰓅"
                            active: island.gamePerfMode; activeColor: island.green
                            transform: Translate { y: root._ct4Ey }
                            onToggled: { island.gamePerfMode = !island.gamePerfMode; island.exec("powerprofilesctl set " + (island.gamePerfMode ? "performance" : "balanced")) }
                        }
                        ToggleRow {
                            id: micRow
                            width: parent.width - island.s(28)
                            label: "Mute Microphone"; icon: island.gameMicMuted ? "󰍭" : "󰍬"
                            active: island.gameMicMuted; activeColor: island.red
                            transform: Translate { y: root._ct5Ey }
                            onToggled: { island.gameMicMuted = !island.gameMicMuted; island.exec("wpctl set-mute @DEFAULT_SOURCE@ toggle") }
                        }

                        Item { width: 1; height: island.s(10) }
                        Rectangle { width: parent.width - island.s(28); height: 1; color: island.surface2 }
                        Item { width: 1; height: island.s(10) }

                        Rectangle {
                            id: dismissWrap
                            width: parent.width - island.s(28); height: island.s(52); radius: island.s(10)
                            color: dismissMouse.containsMouse
                                ? Qt.rgba(island.red.r, island.red.g, island.red.b, 0.16)
                                : Qt.rgba(island.red.r, island.red.g, island.red.b, 0.08)
                            border.width: 1
                            border.color: dismissMouse.containsMouse
                                ? Qt.rgba(island.red.r, island.red.g, island.red.b, 0.45)
                                : Qt.rgba(island.red.r, island.red.g, island.red.b, 0.25)
                            transform: Translate { y: root._ct6Ey }
                            Behavior on color        { ColorAnimation { duration: 120 } }
                            Behavior on border.color { ColorAnimation { duration: 120 } }

                            Column {
                                anchors.centerIn: parent; spacing: island.s(2)
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter; text: "Dismiss HUD"
                                    font.family: Theme.fontUI; font.pixelSize: island.s(13); font.weight: Font.Medium; color: island.red
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter; text: "resumes when game is detected"
                                    font.family: Theme.fontUI; font.pixelSize: island.s(10)
                                    color: Qt.rgba(island.red.r, island.red.g, island.red.b, 0.55)
                                }
                            }
                            MouseArea {
                                id: dismissMouse; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                onClicked: island.gameActive = false
                            }
                        }
                    }
                }
            }
        }
    }
}
