import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Controls
import QtCore
import Quickshell
import Quickshell.Io
import "../"

Item {
    id: window

    // --- Responsive Scaling Logic ---
    Scaler {
        id: scaler
        // Uses the physical screen width so the popup scales synchronously with the TopBar
        currentWidth: Screen.width
    }
    
    // Helper function scoped to the root Item for easy access in deeply nested elements and Canvases
    function s(val) { 
        return scaler.s(val); 
    }

    // -------------------------------------------------------------------------
    // COLORS (Dynamic Matugen Palette)
    // -------------------------------------------------------------------------
    MatugenColors { id: _theme }
    readonly property color base: _theme.base
    readonly property color mantle: _theme.mantle
    readonly property color crust: _theme.crust
    readonly property color text: _theme.text
    readonly property color subtext0: _theme.subtext0
    readonly property color overlay0: _theme.overlay0
    readonly property color overlay1: _theme.overlay1
    readonly property color surface0: _theme.surface0
    readonly property color surface1: _theme.surface1
    readonly property color surface2: _theme.surface2
    
    readonly property color mauve: _theme.mauve
    readonly property color pink: _theme.pink
    readonly property color red: _theme.red
    readonly property color maroon: _theme.maroon
    readonly property color peach: _theme.peach
    readonly property color yellow: _theme.yellow
    readonly property color green: _theme.green
    readonly property color teal: _theme.teal
    readonly property color sapphire: _theme.sapphire
    readonly property color blue: _theme.blue

    // -------------------------------------------------------------------------
    // CACHE (Eliminates startup delay visually)
    // -------------------------------------------------------------------------
    Settings {
        id: widgetCache
        category: "SystemMonitorCache"
        property int cpuUsage: 0
        property int ramUsage: 0
        property int diskUsage: 0
        property int sysTemp: 0
        property string powerProfile: "balanced"
        property int upHours: 0
        property int upMins: 0
        property real sysBrightness: 0
        property string currentUserName: "User"
    }

    // -------------------------------------------------------------------------
    // STATE & POLLING
    // -------------------------------------------------------------------------
    property int cpuUsage: widgetCache.cpuUsage
    property int ramUsage: widgetCache.ramUsage
    property int diskUsage: widgetCache.diskUsage
    property int sysTemp: widgetCache.sysTemp

    property string powerProfile: widgetCache.powerProfile
    
    property int upHours: widgetCache.upHours
    property int upMins: widgetCache.upMins

    property real sysBrightness: widgetCache.sysBrightness
    
    property string currentUserName: widgetCache.currentUserName

    property bool isDraggingBri: false
    Timer { id: briSyncDelay; interval: 800; onTriggered: window.isDraggingBri = false; triggeredOnStart: true; }

    // Unified hue for Performance Profile
    readonly property color profileStart: {
        if (powerProfile === "performance") return window.red;
        if (powerProfile === "power-saver") return window.green;
        return window.blue;
    }
    readonly property color profileEnd: Qt.lighter(profileStart, 1.15)

    // Ambient Blobs - Static for Desktop version
    readonly property color ambientPrimary: window.mauve
    readonly property color ambientSecondary: window.blue

    Process {
        id: userPoller
        command: ["bash", "-c", "echo $USER"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                window.currentUserName = this.text.trim();
                widgetCache.currentUserName = window.currentUserName;
            }
        }
    }

    Process {
        id: sysPoller
        // HIGHLY ROBUST BASH COMMANDS
        command: ["bash", "-c", 
            "vmstat 1 2 | tail -1 | awk '{print 100 - $15}' || echo '0'; " +
            "free -m | awk '/Mem:/ {print int($3/$2 * 100)}' || echo '0'; " +
            "df -h / | awk 'NR==2 {print $5}' | tr -d '%' || echo '0'; " +
            "temp=$(sensors 2>/dev/null | grep -m 1 -E 'Package id 0|Tctl|Tdie|edge|temp1' | grep -oE '\\+[0-9]+\\.[0-9]+' | head -n 1 | tr -d '+' | cut -d. -f1); [ -z \"$temp\" ] && temp=$(cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | head -n 1 | awk '{print int($1/1000)}'); echo \"${temp:-0}\"; " +
            "powerprofilesctl get 2>/dev/null || echo 'balanced'; " +
            "awk '{print int($1/3600)\"h \"int(($1%3600)/60)\"m\"}' /proc/uptime 2>/dev/null || echo '0h 0m'; " +
            "brightnessctl -m 2>/dev/null | awk -F, '{print substr($4, 1, length($4)-1)}' || echo '0'"
        ]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n");
                if (lines.length >= 7) {
                    window.cpuUsage = parseInt(lines[0]) || 0;
                    widgetCache.cpuUsage = window.cpuUsage;

                    window.ramUsage = parseInt(lines[1]) || 0;
                    widgetCache.ramUsage = window.ramUsage;

                    window.diskUsage = parseInt(lines[2]) || 0;
                    widgetCache.diskUsage = window.diskUsage;

                    window.sysTemp = parseInt(lines[3]) || 0;
                    widgetCache.sysTemp = window.sysTemp;

                    window.powerProfile = lines[4];
                    widgetCache.powerProfile = window.powerProfile;

                    let upParts = lines[5].split("h ");
                    if (upParts.length === 2) {
                        window.upHours = parseInt(upParts[0]) || 0;
                        widgetCache.upHours = window.upHours;
                        window.upMins = parseInt(upParts[1].replace("m", "")) || 0;
                        widgetCache.upMins = window.upMins;
                    }

                    if (!window.isDraggingBri) {
                        window.sysBrightness = parseInt(lines[6]) || 0;
                        widgetCache.sysBrightness = window.sysBrightness;
                    }
                }
            }
        }
    }

    Timer {
        interval: 1500; running: true; repeat: true; triggeredOnStart: true;
        onTriggered: sysPoller.running = true
    }

    property real globalOrbitAngle: 0
    NumberAnimation on globalOrbitAngle {
        from: 0; to: Math.PI * 2; duration: 90000; loops: Animation.Infinite; running: true
    }

    // --- ENHANCED STARTUP ANIMATION STATES ---
    property real introMain: 0
    property real introTop: 0
    property real introCore: 0
    property real introSliders: 0
    property real introProfiles: 0

    ParallelAnimation {
        running: true
        NumberAnimation { target: window; property: "introMain"; from: 0; to: 1.0; duration: 800; easing.type: Easing.OutQuart }
        SequentialAnimation {
            PauseAnimation { duration: 100 }
            NumberAnimation { target: window; property: "introTop"; from: 0; to: 1.0; duration: 800; easing.type: Easing.OutBack; easing.overshoot: 1.0 }
        }
        SequentialAnimation {
            PauseAnimation { duration: 250 }
            NumberAnimation { target: window; property: "introCore"; from: 0; to: 1.0; duration: 900; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
        }
        SequentialAnimation {
            PauseAnimation { duration: 350 }
            NumberAnimation { target: window; property: "introSliders"; from: 0; to: 1.0; duration: 800; easing.type: Easing.OutQuart }
        }
        SequentialAnimation {
            PauseAnimation { duration: 550 }
            NumberAnimation { target: window; property: "introProfiles"; from: 0; to: 1.0; duration: 850; easing.type: Easing.OutBack; easing.overshoot: 0.8 }
        }
    }

    // -------------------------------------------------------------------------
    // UI LAYOUT
    // -------------------------------------------------------------------------
    Item {
        anchors.fill: parent
        scale: 0.92 + (0.08 * introMain)
        opacity: introMain
        transform: Translate { y: window.s(15) * (1 - introMain) }

        // Outer Border
        Rectangle {
            anchors.fill: parent
            radius: window.s(20)
            color: window.base
            border.color: window.surface1 
            border.width: 1
            clip: true

            // Rotating Background Blobs
            Rectangle {
                width: parent.width * 0.8; height: width; radius: width / 2
                x: (parent.width / 2 - width / 2) + Math.cos(window.globalOrbitAngle * 2) * window.s(150)
                y: (parent.height / 2 - height / 2) + Math.sin(window.globalOrbitAngle * 2) * window.s(100)
                opacity: 0.08
                color: window.ambientPrimary
            }
            
            Rectangle {
                width: parent.width * 0.9; height: width; radius: width / 2
                x: (parent.width / 2 - width / 2) + Math.sin(window.globalOrbitAngle * 1.5) * window.s(-150)
                y: (parent.height / 2 - height / 2) + Math.cos(window.globalOrbitAngle * 1.5) * window.s(-100)
                opacity: 0.06
                color: window.ambientSecondary
            }

            RowLayout {
                anchors.fill: parent
                spacing: 0

                // Notification center moved to Dynamic Island (navigation arrows inside the island)
                // --- REMOVED: LEFT SIDE NOTIFICATION CENTER ---

                // ==========================================
                // RIGHT SIDE: SYSTEM RESOURCES CORE
                // ==========================================
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    // Radar Rings
                    Item {
                        id: radarItem
                        anchors.fill: parent
                        
                        Repeater {
                            model: 3
                            Rectangle {
                                anchors.centerIn: parent
                                anchors.verticalCenterOffset: window.s(-70)
                                width: window.s(320) + (index * window.s(170))
                                height: width
                                radius: width / 2
                                color: "transparent"
                                border.color: window.ambientSecondary
                                border.width: 1
                                opacity: 0.06 - (index * 0.02)
                            }
                        }
                    }

                    // ==========================================
                    // TOP: UPTIME COMPONENT
                    // ==========================================
                    Row {
                        id: uptimeRow
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.margins: window.s(25)
                        spacing: window.s(6)
                        z: 10
                        
                        transform: Translate { y: window.s(-20) * (1.0 - introTop) }
                        opacity: introTop
                        
                        // Hours Box
                        Rectangle {
                            width: window.s(44); height: window.s(48); radius: window.s(10)
                            color: window.surface0; border.color: window.surface1; border.width: 1
                            
                            Rectangle { anchors.fill: parent; radius: window.s(10); color: window.ambientPrimary; opacity: 0.05; }
                            Column {
                                anchors.centerIn: parent
                                Text { 
                                    text: window.upHours.toString().padStart(2, '0')
                                    font.pixelSize: window.s(18); font.family: "JetBrains Mono"; font.weight: Font.Black
                                    color: window.ambientPrimary
                                    anchors.horizontalCenter: parent.horizontalCenter 
                                }
                                Text { 
                                    text: "HR"; font.pixelSize: window.s(8); font.family: "JetBrains Mono"; font.weight: Font.Bold
                                    color: window.subtext0; anchors.horizontalCenter: parent.horizontalCenter 
                                }
                            }
                        }

                        // Pulsing Colon
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: ":"
                            font.pixelSize: window.s(22); font.family: "JetBrains Mono"; font.weight: Font.Black
                            color: window.ambientPrimary
                            
                            opacity: uptimePulse
                            property real uptimePulse: 1.0
                            SequentialAnimation on uptimePulse {
                                loops: Animation.Infinite; running: true
                                NumberAnimation { to: 0.2; duration: 800; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InOutSine }
                            }
                        }

                        // Mins Box
                        Rectangle {
                            width: window.s(44); height: window.s(48); radius: window.s(10)
                            color: window.surface0; border.color: window.surface1; border.width: 1
                            
                            Rectangle { anchors.fill: parent; radius: window.s(10); color: window.ambientSecondary; opacity: 0.05; }
                            Column {
                                anchors.centerIn: parent
                                Text { 
                                    text: window.upMins.toString().padStart(2, '0')
                                    font.pixelSize: window.s(18); font.family: "JetBrains Mono"; font.weight: Font.Black
                                    color: window.ambientSecondary
                                    anchors.horizontalCenter: parent.horizontalCenter 
                                }
                                Text { 
                                    text: "MIN"; font.pixelSize: window.s(8); font.family: "JetBrains Mono"; font.weight: Font.Bold
                                    color: window.subtext0; anchors.horizontalCenter: parent.horizontalCenter 
                                }
                            }
                        }
                    }

                    // Expanding top-right logout icon
                    Rectangle {
                        id: logoutBtn
                        anchors.top: parent.top; anchors.right: parent.right
                        anchors.margins: window.s(25)
                        z: 10
                        width: logoutMa.containsMouse ? window.s(44) + usernameText.implicitWidth + window.s(12) : window.s(44)
                        height: window.s(44); radius: window.s(14)
                        color: logoutMa.containsMouse ? window.surface0 : "transparent"
                        border.color: logoutMa.containsMouse ? window.surface1 : "transparent"
                        clip: true
                        
                        transform: Translate { y: window.s(-20) * (1.0 - introTop) }
                        opacity: introTop

                        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        Row {
                            anchors.right: parent.right
                            anchors.rightMargin: window.s(13)
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: window.s(12)

                            Text {
                                id: usernameText
                                text: window.currentUserName
                                font.family: "JetBrains Mono"
                                font.weight: Font.Bold
                                font.pixelSize: window.s(14)
                                color: window.text
                                anchors.verticalCenter: parent.verticalCenter
                                opacity: logoutMa.containsMouse ? 1.0 : 0.0
                                Behavior on opacity { NumberAnimation { duration: 250 } }
                            }

                            Text {
                                font.family: "Iosevka Nerd Font"; font.pixelSize: window.s(18)
                                color: logoutMa.containsMouse ? window.red : window.overlay0
                                text: ""
                                anchors.verticalCenter: parent.verticalCenter
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                        }

                        MouseArea {
                            id: logoutMa
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Quickshell.execDetached(["sh", "-c", "echo 'powermenu' > /tmp/qs_widget_state"])
                            }
                        }
                    }

                    // ==========================================
                    // BIG SYSTEM RESOURCES GRID (DESKTOP)
                    // ==========================================
                    Grid {
                        id: sysGrid
                        columns: 2
                        spacing: window.s(25)
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: window.s(-85) 
                        z: 1

                        opacity: introCore
                        transform: Translate { y: window.s(25) * (1 - introCore) }
                        scale: 0.9 + (0.1 * introCore)

                        // 1. CPU Orb
                        Item {
                            id: cpuOrb; width: window.s(145); height: window.s(145)
                            property real animVal: window.cpuUsage
                            Behavior on animVal { NumberAnimation { duration: 1200; easing.type: Easing.OutQuint } }
                            onAnimValChanged: cpuCanvas.requestPaint()
                            
                            scale: cpuMa.containsMouse ? 1.05 : 1.0
                            Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }

                            // Individual Aura - Fixed Overlap
                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width + (cpuMa.containsMouse ? window.s(16) : window.s(4)) 
                                height: width; radius: width / 2
                                color: window.blue
                                opacity: cpuMa.containsMouse ? 0.25 : 0.08
                                Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
                                Behavior on opacity { NumberAnimation { duration: 300 } }
                            }

                            Canvas {
                                id: cpuCanvas; anchors.fill: parent; rotation: 180
                                onPaint: {
                                    var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height);
                                    var cX = width/2; var cY = height/2; var rad = (width/2)-window.s(8);
                                    var eA = (Math.min(100, Math.max(0, parent.animVal)) / 100) * 2 * Math.PI;
                                    ctx.lineCap = "round"; ctx.lineWidth = window.s(8); ctx.beginPath(); ctx.arc(cX, cY, rad, 0, 2*Math.PI); 
                                    ctx.strokeStyle = window.surface0.toString(); ctx.stroke();
                                    var grad = ctx.createLinearGradient(0, height, width, 0); grad.addColorStop(0, window.blue.toString()); grad.addColorStop(1, window.sapphire.toString());
                                    ctx.lineWidth = window.s(14); ctx.beginPath(); ctx.arc(cX, cY, rad, 0, eA); ctx.strokeStyle = grad; ctx.stroke();
                                }
                            }
                            ColumnLayout {
                                anchors.centerIn: parent; spacing: 0
                                RowLayout {
                                    Layout.alignment: Qt.AlignHCenter; spacing: window.s(4)
                                    Text { font.family: "Iosevka Nerd Font"; font.pixelSize: window.s(18); color: window.blue; text: "" }
                                    Text { font.family: "JetBrains Mono"; font.weight: Font.Black; font.pixelSize: window.s(28); color: window.text; text: Math.round(cpuOrb.animVal) + "%" }
                                }
                                Text { Layout.alignment: Qt.AlignHCenter; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: window.s(12); color: window.subtext0; text: "CPU LOAD" }
                            }
                            MouseArea { id: cpuMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor }
                        }

                        // 2. RAM Orb
                        Item {
                            id: ramOrb; width: window.s(145); height: window.s(145)
                            property real animVal: window.ramUsage
                            Behavior on animVal { NumberAnimation { duration: 1200; easing.type: Easing.OutQuint } }
                            onAnimValChanged: ramCanvas.requestPaint()

                            scale: ramMa.containsMouse ? 1.05 : 1.0
                            Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }

                            // Individual Aura - Fixed Overlap
                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width + (ramMa.containsMouse ? window.s(16) : window.s(4))
                                height: width; radius: width / 2
                                color: window.mauve
                                opacity: ramMa.containsMouse ? 0.25 : 0.08
                                Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
                                Behavior on opacity { NumberAnimation { duration: 300 } }
                            }

                            Canvas {
                                id: ramCanvas; anchors.fill: parent; rotation: 180
                                onPaint: {
                                    var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height);
                                    var cX = width/2; var cY = height/2; var rad = (width/2)-window.s(8);
                                    var eA = (Math.min(100, Math.max(0, parent.animVal)) / 100) * 2 * Math.PI;
                                    ctx.lineCap = "round"; ctx.lineWidth = window.s(8); ctx.beginPath(); ctx.arc(cX, cY, rad, 0, 2*Math.PI); 
                                    ctx.strokeStyle = window.surface0.toString(); ctx.stroke();
                                    var grad = ctx.createLinearGradient(0, height, width, 0); grad.addColorStop(0, window.mauve.toString()); grad.addColorStop(1, window.pink.toString());
                                    ctx.lineWidth = window.s(14); ctx.beginPath(); ctx.arc(cX, cY, rad, 0, eA); ctx.strokeStyle = grad; ctx.stroke();
                                }
                            }
                            ColumnLayout {
                                anchors.centerIn: parent; spacing: 0
                                RowLayout {
                                    Layout.alignment: Qt.AlignHCenter; spacing: window.s(4)
                                    Text { font.family: "Iosevka Nerd Font"; font.pixelSize: window.s(18); color: window.mauve; text: "󰍛" }
                                    Text { font.family: "JetBrains Mono"; font.weight: Font.Black; font.pixelSize: window.s(28); color: window.text; text: Math.round(ramOrb.animVal) + "%" }
                                }
                                Text { Layout.alignment: Qt.AlignHCenter; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: window.s(12); color: window.subtext0; text: "MEMORY" }
                            }
                            MouseArea { id: ramMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor }
                        }

                        // 3. DISK Orb
                        Item {
                            id: diskOrb; width: window.s(145); height: window.s(145)
                            property real animVal: window.diskUsage
                            Behavior on animVal { NumberAnimation { duration: 1200; easing.type: Easing.OutQuint } }
                            onAnimValChanged: diskCanvas.requestPaint()

                            scale: diskMa.containsMouse ? 1.05 : 1.0
                            Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }

                            // Individual Aura - Fixed Overlap
                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width + (diskMa.containsMouse ? window.s(16) : window.s(4))
                                height: width; radius: width / 2
                                color: window.peach
                                opacity: diskMa.containsMouse ? 0.25 : 0.08
                                Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
                                Behavior on opacity { NumberAnimation { duration: 300 } }
                            }

                            Canvas {
                                id: diskCanvas; anchors.fill: parent; rotation: 180
                                onPaint: {
                                    var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height);
                                    var cX = width/2; var cY = height/2; var rad = (width/2)-window.s(8);
                                    var eA = (Math.min(100, Math.max(0, parent.animVal)) / 100) * 2 * Math.PI;
                                    ctx.lineCap = "round"; ctx.lineWidth = window.s(8); ctx.beginPath(); ctx.arc(cX, cY, rad, 0, 2*Math.PI); 
                                    ctx.strokeStyle = window.surface0.toString(); ctx.stroke();
                                    var grad = ctx.createLinearGradient(0, height, width, 0); grad.addColorStop(0, window.peach.toString()); grad.addColorStop(1, window.yellow.toString());
                                    ctx.lineWidth = window.s(14); ctx.beginPath(); ctx.arc(cX, cY, rad, 0, eA); ctx.strokeStyle = grad; ctx.stroke();
                                }
                            }
                            ColumnLayout {
                                anchors.centerIn: parent; spacing: 0
                                RowLayout {
                                    Layout.alignment: Qt.AlignHCenter; spacing: window.s(4)
                                    Text { font.family: "Iosevka Nerd Font"; font.pixelSize: window.s(18); color: window.peach; text: "󰋊" }
                                    Text { font.family: "JetBrains Mono"; font.weight: Font.Black; font.pixelSize: window.s(28); color: window.text; text: Math.round(diskOrb.animVal) + "%" }
                                }
                                Text { Layout.alignment: Qt.AlignHCenter; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: window.s(12); color: window.subtext0; text: "STORAGE" }
                            }
                            MouseArea { id: diskMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor }
                        }

                        // 4. TEMP Orb
                        Item {
                            id: tempOrb; width: window.s(145); height: window.s(145)
                            property real animVal: window.sysTemp
                            Behavior on animVal { NumberAnimation { duration: 1200; easing.type: Easing.OutQuint } }
                            onAnimValChanged: tempCanvas.requestPaint()

                            scale: tempMa.containsMouse ? 1.05 : 1.0
                            Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }

                            // Individual Aura - Fixed Overlap
                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width + (tempMa.containsMouse ? window.s(16) : window.s(4))
                                height: width; radius: width / 2
                                color: window.red
                                opacity: tempMa.containsMouse ? 0.25 : 0.08
                                Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
                                Behavior on opacity { NumberAnimation { duration: 300 } }
                            }

                            Canvas {
                                id: tempCanvas; anchors.fill: parent; rotation: 180
                                onPaint: {
                                    var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height);
                                    var cX = width/2; var cY = height/2; var rad = (width/2)-window.s(8);
                                    var eA = (Math.min(100, Math.max(0, parent.animVal)) / 100) * 2 * Math.PI;
                                    ctx.lineCap = "round"; ctx.lineWidth = window.s(8); ctx.beginPath(); ctx.arc(cX, cY, rad, 0, 2*Math.PI); 
                                    ctx.strokeStyle = window.surface0.toString(); ctx.stroke();
                                    var grad = ctx.createLinearGradient(0, height, width, 0); grad.addColorStop(0, window.red.toString()); grad.addColorStop(1, window.maroon.toString());
                                    ctx.lineWidth = window.s(14); ctx.beginPath(); ctx.arc(cX, cY, rad, 0, eA); ctx.strokeStyle = grad; ctx.stroke();
                                }
                            }
                            ColumnLayout {
                                anchors.centerIn: parent; spacing: 0
                                RowLayout {
                                    Layout.alignment: Qt.AlignHCenter; spacing: window.s(4)
                                    Text { font.family: "Iosevka Nerd Font"; font.pixelSize: window.s(18); color: window.red; text: "" }
                                    Text { font.family: "JetBrains Mono"; font.weight: Font.Black; font.pixelSize: window.s(28); color: window.text; text: Math.round(tempOrb.animVal) + "°" }
                                }
                                Text { Layout.alignment: Qt.AlignHCenter; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: window.s(12); color: window.subtext0; text: "SYSTEM TEMP" }
                            }
                            MouseArea { id: tempMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor }
                        }
                    }

                    // ==========================================
                    // BOTTOM DOCKS
                    // ==========================================
                    ColumnLayout {
                        id: bottomDocks
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: window.s(25)
                        spacing: window.s(15)

                        // 1. HARDWARE CONTROLS DOCK (Brightness)
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: window.s(52)
                            radius: window.s(14)
                            color: window.surface0
                            border.color: window.surface1
                            border.width: 1

                            opacity: introSliders
                            transform: Translate { y: window.s(20) * (1.0 - introSliders) }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: window.s(14)
                                spacing: window.s(12)

                                // Brightness Slider
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: window.s(15)

                                    Item {
                                        Layout.preferredWidth: window.s(32)
                                        Layout.preferredHeight: window.s(32)
                                        Text {
                                            anchors.centerIn: parent
                                            text: window.sysBrightness > 66 ? "󰃠" : (window.sysBrightness > 33 ? "󰃟" : "󰃞")
                                            font.family: "Iosevka Nerd Font"
                                            font.pixelSize: window.s(22)
                                            color: window.blue
                                            Behavior on color { ColorAnimation { duration: 200 } }
                                        }
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                        height: window.s(18)
                                        
                                        Timer {
                                            id: briCmdThrottle
                                            interval: 50
                                            property int targetPct: -1
                                            onTriggered: {
                                                if (targetPct >= 0) {
                                                    Quickshell.execDetached(["brightnessctl", "set", targetPct + "%"]);
                                                    targetPct = -1;
                                                }
                                            }
                                        }

                                        Rectangle {
                                            anchors.fill: parent
                                            radius: window.s(9)
                                            color: window.surface1
                                            border.color: window.surface2
                                            border.width: 1
                                            clip: true

                                            Rectangle {
                                                height: parent.height
                                                width: parent.width * (window.sysBrightness / 100)
                                                radius: window.s(9)
                                                opacity: briMa.containsMouse ? 1.0 : 0.85
                                                Behavior on opacity { NumberAnimation { duration: 200 } }
                                                Behavior on width { enabled: !window.isDraggingBri; NumberAnimation { duration: 200; easing.type: Easing.OutQuint } }

                                                gradient: Gradient {
                                                    orientation: Gradient.Horizontal
                                                    GradientStop { position: 0.0; color: window.blue }
                                                    GradientStop { position: 1.0; color: window.sapphire }
                                                }
                                            }
                                        }
                                        MouseArea {
                                            id: briMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onPressed: (mouse) => { briSyncDelay.stop(); window.isDraggingBri = true; updateBri(mouse.x); }
                                            onPositionChanged: (mouse) => { if (pressed) updateBri(mouse.x); }
                                            onReleased: { briSyncDelay.restart(); }
                                            
                                            function updateBri(mx) {
                                                let pct = Math.max(0, Math.min(100, Math.round((mx / width) * 100)));
                                                window.sysBrightness = pct; 
                                                briCmdThrottle.targetPct = pct;
                                                if (!briCmdThrottle.running) briCmdThrottle.start();
                                            }
                                        }
                                    }
                                }

                            }
                        }

                        // 3. POWER PROFILES DOCK
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: window.s(54)
                            radius: window.s(14)
                            color: window.surface0 
                            border.color: window.surface1
                            border.width: 1

                            opacity: introProfiles
                            transform: Translate { y: window.s(20) * (1.0 - introProfiles) }
                            
                            Rectangle {
                                id: sliderPill
                                width: (parent.width - window.s(2)) / 3 
                                height: parent.height - window.s(2)
                                y: window.s(1)
                                radius: window.s(10)
                                x: {
                                    if (window.powerProfile === "performance") return window.s(1);
                                    if (window.powerProfile === "balanced") return width + window.s(1);
                                    return (width * 2) + window.s(1);
                                }
                                
                                Behavior on x { NumberAnimation { duration: 400; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
                                
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: window.profileStart; Behavior on color { ColorAnimation{duration:400} } }
                                    GradientStop { position: 1.0; color: window.profileEnd; Behavior on color { ColorAnimation{duration:400} } }
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                spacing: 0
                                
                                Repeater {
                                    model: ListModel {
                                        ListElement { name: "performance"; icon: "󰓅"; label: "Perform" } 
                                        ListElement { name: "balanced"; icon: "󰗑"; label: "Balance" }   
                                        ListElement { name: "power-saver"; icon: "󰌪"; label: "Saver" } 
                                    }
                                    
                                    delegate: Item {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        
                                        RowLayout {
                                            anchors.centerIn: parent
                                            spacing: window.s(8)
                                            Text {
                                                font.family: "Iosevka Nerd Font"; font.pixelSize: window.s(18)
                                                color: window.powerProfile === name ? window.crust : (profileMa.containsMouse ? window.text : window.subtext0)
                                                text: icon
                                                Behavior on color { ColorAnimation { duration: 200 } }
                                            }
                                            Text {
                                                font.family: "JetBrains Mono"; font.weight: Font.Black; font.pixelSize: window.s(13)
                                                color: window.powerProfile === name ? window.crust : (profileMa.containsMouse ? window.text : window.subtext0)
                                                text: label
                                                Behavior on color { ColorAnimation { duration: 200 } }
                                            }
                                        }
                                        
                                        MouseArea {
                                            id: profileMa
                                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: { Quickshell.execDetached(["powerprofilesctl", "set", name]); sysPoller.running = true; }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
