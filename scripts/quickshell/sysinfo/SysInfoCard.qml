// SystemCard.qml — SPECIMEN / Carbon Series
// Skin-parametrized: all visual constants live in `skin` QtObject.
// To add a new skin, swap out the skin object or load its values from JSON.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../"
import "../themes"

Item {
    id: root

    Scaler { id: scaler; currentWidth: Screen.width }
    function s(v) { return scaler.s(v) }

    function close() {
        Quickshell.execDetached(["sh", "-c", "echo 'close' > /tmp/qs_widget_state"])
    }

    // ── Skin — swap this object to change the entire card look ───────────────
    QtObject {
        id: skin

        // Identity
        readonly property string name:       "Carbon"
        readonly property string edition:    "© CARBON FOUNDRY · MMXXVI"
        readonly property string rarity:     "RARE · 03/100"
        readonly property string logoSource: Qt.resolvedUrl("arch.svg")
        readonly property string fontFamily: "JetBrains Mono"

        // Base palette
        readonly property color text:    "#f5f5f5"
        readonly property color muted:   "#888888"
        readonly property color subtle:  "#555555"
        readonly property color accent:  "#e8e8e8"   // silver
        readonly property color line:    Qt.rgba(1, 1, 1, 0.06)
        readonly property color lineHi:  Qt.rgba(1, 1, 1, 0.12)

        // Card body gradient
        readonly property color bodyTop:    "#1f1f1f"
        readonly property color bodyBottom: "#0b0b0b"

        // Badge (MEM%) gradient
        readonly property color badgeTop:    "#2e2e2e"
        readonly property color badgeBottom: "#141414"

        // Logo window gradient
        readonly property color logoWinTop:    "#1a1a1a"
        readonly property color logoWinBottom: "#060606"

        // Disk bar gradient (left → right)
        readonly property color diskBarStart: "#d8d8d8"
        readonly property color diskBarEnd:   "#f5f5f5"

        // Holo background tints (Canvas rgba strings)
        readonly property string holoTop:         "rgba(232,232,232,0.07)"
        readonly property string holoBottomLeft:  "rgba(96,165,250,0.08)"
        readonly property string holoBottomRight: "rgba(134,239,172,0.05)"

        // Glow behind logo
        readonly property string logoGlow: "rgba(232,232,232,0.16)"

        // Grid texture line opacity
        readonly property real gridOpacity: 0.03

        // Foil sheen intensities
        readonly property real foilCenter: 0.16
        readonly property real foilEdge:   0.04

        // Parallax tilt strength (degrees)
        readonly property real tiltStrengthX: 6
        readonly property real tiltStrengthY: 7
    }

    // ── System data ───────────────────────────────────────────────────────────
    property string sysUser:       "user"
    property string sysHostname:   "host"
    property string sysDistro:     "Linux"
    property string sysArch:       "x86_64"
    property string sysKernel:     "–"
    property string sysWM:         "Hyprland"
    property string sysShell:      "zsh"
    property string sysCpu:        "–"
    property string sysCpuCores:   "–"
    property string sysGpu:        "–"
    property string sysRam:        "– / –"
    property int    sysRamPct:     0
    property string sysDisk:       "– / –"
    property int    sysDiskPct:    0
    property string sysUptime:     "–"
    property string sysPackages:   "–"
    property string sysResolution: "–"
    property string sysRefresh:    ""

    Process {
        id: dataPoller
        command: ["bash", "-c",
            "whoami; " +
            "cat /etc/hostname; " +
            "grep -m1 'PRETTY_NAME' /etc/os-release | cut -d'\"' -f2; " +
            "uname -m; " +
            "uname -r; " +
            "echo \"${SHELL##*/}\"; " +
            "grep -m1 'model name' /proc/cpuinfo | sed 's/.*: //' | sed 's/ *@ .*//' | sed 's/([^)]*)//' | xargs | cut -c1-26; " +
            "echo \"$(nproc)C / $(nproc --all)T\"; " +
            "lspci 2>/dev/null | grep -iE 'vga|3d' | head -1 | sed 's/.*: //' | sed 's/Advanced Micro Devices, Inc\\. \\[AMD\\/ATI\\] //' | sed 's/NVIDIA Corporation //' | sed 's/Intel Corporation //' | sed 's/ (.*//' | sed 's/ \\[.*\\]//' | xargs | cut -c1-26 || echo '–'; " +
            "free -h --si | awk '/Mem:/{print $3\" / \"$2}'; " +
            "free | awk '/Mem:/{print int($3/$2*100)}'; " +
            "df -h / | awk 'NR==2{print $3\" / \"$2}'; " +
            "df / | awk 'NR==2{print int($3/($3+$4)*100)}'; " +
            "awk '{h=int($1/3600); m=int(($1%3600)/60); print h\"h \"m\"m\"}' /proc/uptime; " +
            "(pacman -Qq 2>/dev/null | wc -l) || (dpkg -l 2>/dev/null | grep -c '^ii') || echo '–'; " +
            "hyprctl monitors 2>/dev/null | awk '/x.*@/{match($0,/([0-9]+x[0-9]+)/,a); print a[1]; exit}' || echo '–'; " +
            "hyprctl monitors 2>/dev/null | awk '/x.*@/{match($0,/@([0-9]+)/,a); print a[1]\"Hz\"; exit}' || echo ''"
        ]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let l = this.text.trim().split("\n");
                if (l.length < 6) return;
                root.sysUser       = l[0]  || "user";
                root.sysHostname   = l[1]  || "host";
                root.sysDistro     = l[2]  || "Linux";
                root.sysArch       = l[3]  || "x86_64";
                root.sysKernel     = l[4]  || "–";
                root.sysShell      = l[5]  || "zsh";
                root.sysCpu        = l[6]  || "–";
                root.sysCpuCores   = l[7]  || "–";
                root.sysGpu        = l[8]  || "–";
                root.sysRam        = l[9]  || "– / –";
                root.sysRamPct     = parseInt(l[10])  || 0;
                root.sysDisk       = l[11] || "– / –";
                root.sysDiskPct    = parseInt(l[12]) || 0;
                root.sysUptime     = l[13] || "–";
                root.sysPackages   = (l[14] || "–").trim();
                root.sysResolution = l[15] || "–";
                root.sysRefresh    = l[16] || "";
            }
        }
    }
    Timer { interval: 30000; running: true; repeat: true; triggeredOnStart: true; onTriggered: dataPoller.running = true }

    // ── Tilt & shimmer ────────────────────────────────────────────────────────
    property real tiltX:    0
    property real tiltY:    0
    property real shimNX:   0.5
    property real shimNY:   0.5
    property real hoverPct: 0
    Behavior on tiltX    { NumberAnimation { duration: 220; easing.type: Easing.OutQuad } }
    Behavior on tiltY    { NumberAnimation { duration: 220; easing.type: Easing.OutQuad } }
    Behavior on shimNX   { NumberAnimation { duration: 80 } }
    Behavior on shimNY   { NumberAnimation { duration: 80 } }
    Behavior on hoverPct { NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }

    // ── Intro ─────────────────────────────────────────────────────────────────
    property real showAnim: 0
    NumberAnimation on showAnim { from: 0; to: 1; duration: 380; easing.type: Easing.OutQuart; running: true }
    property real rowsAnim: 0
    SequentialAnimation {
        running: true
        PauseAnimation { duration: 180 }
        NumberAnimation { target: root; property: "rowsAnim"; from: 0; to: 1; duration: 450; easing.type: Easing.OutExpo }
    }

    // ── Click-outside-to-close ────────────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: function(mouse) {
            if (mouse.x < card.x || mouse.x > card.x + card.width ||
                mouse.y < card.y || mouse.y > card.y + card.height)
                root.close();
        }
        onPositionChanged: function(mouse) {
            let inCard = mouse.x >= card.x && mouse.x <= card.x+card.width &&
                         mouse.y >= card.y && mouse.y <= card.y+card.height;
            if (inCard) {
                let dx = (mouse.x - card.x - card.width/2)  / (card.width/2);
                let dy = (mouse.y - card.y - card.height/2) / (card.height/2);
                root.tiltY    =  dx * skin.tiltStrengthY;
                root.tiltX    = -dy * skin.tiltStrengthX;
                root.shimNX   = (mouse.x - card.x) / card.width;
                root.shimNY   = (mouse.y - card.y) / card.height;
                root.hoverPct = 1;
            } else {
                root.tiltX = 0; root.tiltY = 0;
                root.shimNX = 0.5; root.shimNY = 0.5;
                root.hoverPct = 0;
            }
        }
        onExited: { root.tiltX=0; root.tiltY=0; root.shimNX=0.5; root.shimNY=0.5; root.hoverPct=0 }
    }

    // ── Card ──────────────────────────────────────────────────────────────────
    Item {
        id: card
        width:  root.s(360)
        height: root.s(560)
        anchors.centerIn: parent

        opacity: root.showAnim
        scale: 0.94 + 0.06*root.showAnim + 0.020*root.hoverPct
        transformOrigin: Item.Center
        layer.enabled: true

        transform: [
            Rotation {
                origin.x: card.width/2; origin.y: card.height/2
                axis { x: 1; y: 0; z: 0 }
                angle: root.tiltX
            },
            Rotation {
                origin.x: card.width/2; origin.y: card.height/2
                axis { x: 0; y: 1; z: 0 }
                angle: root.tiltY
            }
        ]

        // ── Card body ─────────────────────────────────────────────────────────
        Rectangle {
            id: cardBody
            anchors.fill: parent
            radius: root.s(20)
            clip: true
            gradient: Gradient {
                GradientStop { position: 0.0; color: skin.bodyTop }
                GradientStop { position: 1.0; color: skin.bodyBottom }
            }

            // Holo background — 3 soft radial tints
            Canvas {
                anchors.fill: parent
                property string h0: skin.holoTop
                property string h1: skin.holoBottomLeft
                property string h2: skin.holoBottomRight
                onPaint: {
                    let ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    function radial(cx, cy, r, color) {
                        let g = ctx.createRadialGradient(cx, cy, 0, cx, cy, r);
                        g.addColorStop(0, color);
                        g.addColorStop(1, "rgba(0,0,0,0)");
                        ctx.fillStyle = g;
                        ctx.fillRect(0, 0, width, height);
                    }
                    ctx.globalCompositeOperation = "screen";
                    radial(width * 0.5, height * 0.0, width * 0.7, h0);
                    radial(width * 0.0, height * 1.0, width * 0.7, h1);
                    radial(width * 1.0, height * 1.0, width * 0.7, h2);
                }
            }

            // Foil sheen — follows cursor
            Canvas {
                anchors.fill: parent
                property real nx: root.shimNX
                property real ny: root.shimNY
                property real op: root.hoverPct
                onNxChanged: requestPaint()
                onNyChanged: requestPaint()
                onPaint: {
                    let ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    if (op <= 0.001) return;
                    let cx = nx * width;
                    let cy = ny * height;
                    let g = ctx.createRadialGradient(cx, cy, 0, cx, cy, width * 0.85);
                    g.addColorStop(0,    "rgba(255,255,255," + (skin.foilCenter * op) + ")");
                    g.addColorStop(0.45, "rgba(255,255,255," + (skin.foilEdge   * op) + ")");
                    g.addColorStop(1,    "rgba(255,255,255,0)");
                    ctx.fillStyle = g;
                    ctx.fillRect(0, 0, width, height);
                }
            }

            // ── Content column ────────────────────────────────────────────────
            Column {
                id: content
                anchors.fill: parent
                anchors.margins: root.s(20)
                spacing: 0

                // ── Title bar: name + cost badge ──────────────────────────────
                Row {
                    width: parent.width
                    spacing: root.s(10)

                    Column {
                        spacing: root.s(6)
                        width: parent.width - costBadge.width - parent.spacing
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            text: root.sysUser
                            font.family: skin.fontFamily
                            font.pixelSize: root.s(24)
                            font.weight: Font.Black
                            font.letterSpacing: root.s(-0.5)
                            color: skin.accent
                        }
                        Text {
                            text: "NODE OPERATOR · " + root.sysHostname.toUpperCase()
                            font.family: skin.fontFamily
                            font.pixelSize: root.s(9)
                            font.letterSpacing: root.s(2)
                            font.weight: Font.DemiBold
                            color: skin.muted
                        }
                    }

                    Rectangle {
                        id: costBadge
                        width: root.s(46); height: root.s(46)
                        radius: width / 2
                        border.color: skin.accent
                        border.width: root.s(1.5)
                        anchors.verticalCenter: parent.verticalCenter
                        gradient: Gradient {
                            orientation: Gradient.Vertical
                            GradientStop { position: 0.0; color: skin.badgeTop }
                            GradientStop { position: 1.0; color: skin.badgeBottom }
                        }
                        Column {
                            anchors.centerIn: parent
                            spacing: root.s(1)
                            Text {
                                text: root.sysRamPct
                                font.family: skin.fontFamily
                                font.pixelSize: root.s(14)
                                font.weight: Font.Black
                                color: skin.accent
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            Text {
                                text: "MEM%"
                                font.family: skin.fontFamily
                                font.pixelSize: root.s(7)
                                font.letterSpacing: root.s(1)
                                color: skin.muted
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }
                }

                Item { width: 1; height: root.s(14) }

                // ── Portrait window with logo + ornamental corners ────────────
                Rectangle {
                    width: parent.width
                    height: root.s(208)
                    radius: root.s(6)
                    color: "transparent"
                    border.color: Qt.rgba(1, 1, 1, 0.10)
                    border.width: root.s(1)

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: root.s(2)
                        radius: root.s(4)
                        clip: true
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: skin.logoWinTop }
                            GradientStop { position: 1.0; color: skin.logoWinBottom }
                        }

                        // Grid texture
                        Canvas {
                            anchors.fill: parent
                            property real gridOp: skin.gridOpacity
                            onPaint: {
                                let ctx = getContext("2d");
                                ctx.clearRect(0, 0, width, height);
                                ctx.strokeStyle = "rgba(255,255,255," + gridOp + ")";
                                ctx.lineWidth = 1;
                                let step = 16;
                                for (let x = 0; x <= width;  x += step) { ctx.beginPath(); ctx.moveTo(x,0); ctx.lineTo(x,height); ctx.stroke(); }
                                for (let y = 0; y <= height; y += step) { ctx.beginPath(); ctx.moveTo(0,y); ctx.lineTo(width,y);  ctx.stroke(); }
                            }
                        }

                        // Central glow behind logo
                        Canvas {
                            anchors.fill: parent
                            property string glow: skin.logoGlow
                            onPaint: {
                                let ctx = getContext("2d");
                                ctx.clearRect(0, 0, width, height);
                                let g = ctx.createRadialGradient(width/2, height/2, 0, width/2, height/2, width*0.45);
                                g.addColorStop(0, glow);
                                g.addColorStop(1, "rgba(0,0,0,0)");
                                ctx.fillStyle = g;
                                ctx.fillRect(0, 0, width, height);
                            }
                        }

                        // Logo
                        Image {
                            anchors.centerIn: parent
                            width: root.s(130); height: root.s(130)
                            source: skin.logoSource
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            mipmap: true
                        }

                        // Corner ornaments
                        Repeater {
                            model: 4
                            Rectangle {
                                width: root.s(8); height: root.s(8)
                                color: "transparent"
                                border.color: Qt.rgba(skin.accent.r, skin.accent.g, skin.accent.b, 0.5)
                                border.width: root.s(1)
                                radius: root.s(1)
                                anchors.top:    (index < 2) ? parent.top : undefined
                                anchors.bottom: (index >= 2) ? parent.bottom : undefined
                                anchors.left:   (index % 2 === 0) ? parent.left : undefined
                                anchors.right:  (index % 2 === 1) ? parent.right : undefined
                                anchors.margins: root.s(6)
                            }
                        }
                    }
                }

                Item { width: 1; height: root.s(12) }

                // ── Type line ─────────────────────────────────────────────────
                Row {
                    width: parent.width
                    spacing: root.s(8)
                    height: root.s(22)

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        height: root.s(20)
                        width: typeBadgeText.implicitWidth + root.s(16)
                        radius: root.s(3)
                        color: "transparent"
                        border.color: Qt.rgba(skin.accent.r, skin.accent.g, skin.accent.b, 0.45)
                        border.width: root.s(1)
                        Text {
                            id: typeBadgeText
                            anchors.centerIn: parent
                            text: "SYSTEM"
                            font.family: skin.fontFamily
                            font.pixelSize: root.s(9)
                            font.letterSpacing: root.s(2)
                            font.weight: Font.Bold
                            color: skin.accent
                        }
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - typeBadgeText.implicitWidth - root.s(16) - distroLabel.implicitWidth - root.s(16)
                        height: root.s(1)
                        color: skin.lineHi
                    }

                    Text {
                        id: distroLabel
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.sysDistro + " · " + (root.sysKernel.split("-")[0])
                        font.family: skin.fontFamily
                        font.pixelSize: root.s(9)
                        font.letterSpacing: root.s(1.6)
                        font.weight: Font.DemiBold
                        color: skin.muted
                    }
                }

                Item { width: 1; height: root.s(10) }

                // ── Flavor box ────────────────────────────────────────────────
                Rectangle {
                    width: parent.width
                    height: flavorCol.implicitHeight + root.s(20)
                    color: Qt.rgba(1, 1, 1, 0.02)
                    border.color: "transparent"
                    opacity: root.rowsAnim
                    Behavior on opacity { NumberAnimation { duration: 320 } }

                    Rectangle {
                        width: root.s(2); height: parent.height
                        color: skin.accent
                    }

                    Column {
                        id: flavorCol
                        anchors.fill: parent
                        anchors.leftMargin: root.s(12)
                        anchors.rightMargin: root.s(12)
                        anchors.topMargin: root.s(10)
                        anchors.bottomMargin: root.s(10)
                        spacing: root.s(5)

                        component FlavorRow: Row {
                            property string k1: ""
                            property string v1: ""
                            property string k2: ""
                            property string v2: ""
                            width: parent ? parent.width : 0
                            spacing: root.s(8)

                            Text {
                                text: k1
                                font.family: skin.fontFamily
                                font.pixelSize: root.s(8)
                                font.letterSpacing: root.s(1.6)
                                color: skin.muted
                                width: root.s(26)
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: v1
                                font.family: skin.fontFamily
                                font.pixelSize: root.s(11)
                                font.weight: Font.Medium
                                color: skin.text
                                elide: Text.ElideRight
                                width: (parent.width - 2*root.s(26) - 3*root.s(8)) / 2
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: k2
                                font.family: skin.fontFamily
                                font.pixelSize: root.s(8)
                                font.letterSpacing: root.s(1.6)
                                color: skin.muted
                                width: root.s(26)
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: v2
                                font.family: skin.fontFamily
                                font.pixelSize: root.s(11)
                                font.weight: Font.Medium
                                color: skin.text
                                elide: Text.ElideRight
                                width: (parent.width - 2*root.s(26) - 3*root.s(8)) / 2
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        FlavorRow { k1: "WM";  v1: root.sysWM;     k2: "SH";  v2: root.sysShell }
                        FlavorRow { k1: "RES"; v1: root.sysResolution + (root.sysRefresh ? "@" + root.sysRefresh : "");
                                    k2: "PKG"; v2: root.sysPackages }
                    }
                }

                Item { width: 1; height: root.s(12) }

                // ── Disk strip ────────────────────────────────────────────────
                Row {
                    width: parent.width
                    spacing: root.s(10)
                    height: root.s(18)

                    Text {
                        text: "DISK"
                        font.family: skin.fontFamily
                        font.pixelSize: root.s(8)
                        font.letterSpacing: root.s(1.8)
                        color: skin.muted
                        anchors.verticalCenter: parent.verticalCenter
                        width: root.s(28)
                    }

                    Rectangle {
                        width: parent.width - root.s(28) - root.s(10) - diskVal.implicitWidth - root.s(10)
                        height: root.s(6)
                        radius: root.s(3)
                        color: skin.line
                        anchors.verticalCenter: parent.verticalCenter
                        Rectangle {
                            height: parent.height
                            radius: root.s(3)
                            width: parent.width * (root.sysDiskPct / 100)
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: skin.diskBarStart }
                                GradientStop { position: 1.0; color: skin.diskBarEnd }
                            }
                            Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                        }
                    }

                    Text {
                        id: diskVal
                        text: root.sysDisk
                        font.family: skin.fontFamily
                        font.pixelSize: root.s(10)
                        color: skin.text
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Item { width: 1; height: root.s(10) }

                Rectangle { width: parent.width; height: root.s(1); color: skin.lineHi }

                Item { width: 1; height: root.s(10) }

                // ── Bottom stats: CPU | GPU ───────────────────────────────────
                Row {
                    width: parent.width
                    spacing: root.s(12)
                    opacity: root.rowsAnim

                    Column {
                        width: (parent.width - root.s(12) - root.s(1)) / 2
                        spacing: root.s(2)
                        Text {
                            text: "CPU"
                            font.family: skin.fontFamily
                            font.pixelSize: root.s(8)
                            font.letterSpacing: root.s(1.8)
                            font.weight: Font.DemiBold
                            color: skin.muted
                        }
                        Text {
                            text: root.sysCpu
                            font.family: skin.fontFamily
                            font.pixelSize: root.s(12)
                            font.weight: Font.Bold
                            color: skin.text
                            elide: Text.ElideRight
                            width: parent.width
                        }
                        Text {
                            text: root.sysCpuCores
                            font.family: skin.fontFamily
                            font.pixelSize: root.s(9)
                            color: skin.subtle
                        }
                    }

                    Rectangle {
                        width: root.s(1); height: root.s(38)
                        color: skin.line
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Column {
                        width: (parent.width - root.s(32) - root.s(1)) / 2
                        spacing: root.s(6)
                        Text {
                            text: "GPU"
                            font.family: skin.fontFamily
                            font.pixelSize: root.s(8)
                            font.letterSpacing: root.s(1.8)
                            font.weight: Font.DemiBold
                            color: skin.muted
                            horizontalAlignment: Text.AlignRight
                            width: parent.width - root.s(2)
                        }
                        Text {
                            text: root.sysGpu
                            font.family: skin.fontFamily
                            font.pixelSize: root.s(12)
                            font.weight: Font.Bold
                            color: skin.text
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignRight
                            width: parent.width
                        }
                        Text {
                            text: "UP · " + root.sysUptime
                            font.family: skin.fontFamily
                            font.pixelSize: root.s(9)
                            color: skin.subtle
                            horizontalAlignment: Text.AlignRight
                            width: parent.width
                        }
                    }
                }

                Item { width: 1; height: root.s(8) }

                // ── Edition footer ────────────────────────────────────────────
                RowLayout {
                    width: parent.width
                    spacing: root.s(6)
                    height: root.s(70)

                    Text {
                        text: skin.edition
                        font.family: skin.fontFamily
                        font.pixelSize: root.s(7.5)
                        font.letterSpacing: root.s(1.6)
                        font.weight: Font.DemiBold
                        color: skin.subtle
                        
                    }

                    Item { Layout.fillWidth: true; height: 1 }

                    Row {
                        spacing: root.s(2)
                        Repeater {
                            model: 3
                            Rectangle {
                                width: root.s(4); height: root.s(4); radius: width/2
                                color: skin.accent
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                        Text {
                            text: "  " + skin.rarity
                            font.family: skin.fontFamily
                            font.pixelSize: root.s(8)
                            font.letterSpacing: root.s(1.8)
                            font.weight: Font.Bold
                            color: skin.accent
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }

        // ── Border overlays ───────────────────────────────────────────────────
        Rectangle {
            anchors.fill: parent; anchors.margins: root.s(6)
            radius: root.s(16); color: "transparent"
            border.width: root.s(1); border.color: Qt.rgba(1, 1, 1, 0.12)
        }
        Rectangle {
            anchors.fill: parent; anchors.margins: root.s(10)
            radius: root.s(13); color: "transparent"
            border.width: root.s(1); border.color: Qt.rgba(1, 1, 1, 0.04)
        }
        Rectangle {
            anchors.fill: parent
            radius: root.s(20); color: "transparent"
            border.width: root.s(1); border.color: Qt.rgba(1, 1, 1, 0.10)
        }
    }
}
