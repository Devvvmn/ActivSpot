import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "."
import "./pet"
import "./pages"
import "./collapsed"
import "./minibubbles"
import "./themes"

PanelWindow {
    id: islandWindow

    WlrLayershell.namespace: "qs-island"
    WlrLayershell.layer: WlrLayer.Top

    anchors { top: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    focusable: expanded
    color: "transparent"

    Scaler { id: scaler; currentWidth: Screen.width }
    function s(v) { return scaler.s(v); }

    implicitHeight: s(720)

    // =========================================================
    // --- THEME ---
    // =========================================================
    // All theme state lives in the Theme singleton; island.* aliases stay
    // so pages / minibubbles can keep reading island.mauve / island.glassTheme.
    readonly property color base:     Theme.base
    readonly property color surface0: Theme.surface0
    readonly property color surface1: Theme.surface1
    readonly property color surface2: Theme.surface2
    readonly property color text:     Theme.text
    readonly property color subtext0: Theme.subtext0
    readonly property color mauve:    Theme.mauve
    readonly property color blue:     Theme.blue
    readonly property color peach:    Theme.peach
    readonly property color green:    Theme.green
    readonly property color pink:     Theme.pink
    readonly property color teal:     Theme.teal
    readonly property color red:      Theme.red
    readonly property color yellow:   Theme.yellow

    readonly property string themeId: Theme.themeId
    readonly property bool glassTheme: Theme.isGlass
    readonly property string surfaceStyle: Theme.surfaceStyle

    // =========================================================
    // --- STATE ---
    // =========================================================
    property bool expanded:      false
    property bool hovered:       false
    property bool isDragHovered: false
    property bool _dropJustOccurred: false
    onIsDragHoveredChanged: {
        if (!isDragHovered) dragHoverCollapseTimer.restart()
        else dragHoverCollapseTimer.stop()
    }
    Timer {
        id: dragHoverCollapseTimer
        interval: 100
        onTriggered: {
            if (!islandWindow.isDragHovered && !islandWindow._dropJustOccurred)
                islandWindow.expanded = false;
            islandWindow._dropJustOccurred = false;
        }
    }
    property bool userIsSeeking: false

    // Page navigation: "clock" | "music" | "notifs"
    property string currentPage: "clock"
    property string prevPage:    "clock"
    property bool   notifAutoSwitched: false
    onCurrentPageChanged: {
        if (currentPage !== "notifs") { prevPage = currentPage; notifAutoSwitched = false; }
        if (currentPage === "notifs" && !expanded && notifAutoSwitched) notifPageRevertTimer.restart();
        else notifPageRevertTimer.stop();
    }
    property var availablePages: {
        let p = ["clock"];
        if (islandWindow.stashModel.count > 0) p.push("stash");
        if (islandWindow.isRecording)   p.push("recording");
        if (islandWindow.discordInCall) p.push("discord");
        if (islandWindow.isMediaActive) p.push("music");
        if (notifHistory.count > 0 || islandWindow.notifActive) p.push("notifs");
        return p;
    }
    property int stashExpandedHeight: 260
    property bool _isRefreshingStash: false
    onAvailablePagesChanged: {
        // Don't redirect away from appletPicker — it lives outside availablePages by design
        if (!_isRefreshingStash && !islandWindow.editBarMode && availablePages.indexOf(currentPage) < 0)
            currentPage = availablePages.length > 0 ? availablePages[0] : "clock";
    }
    function navigateNext() {
        let i = availablePages.indexOf(currentPage);
        currentPage = availablePages[(i + 1) % availablePages.length];
    }
    function navigatePrev() {
        let i = availablePages.indexOf(currentPage);
        currentPage = availablePages[(i - 1 + availablePages.length) % availablePages.length];
    }

    // Music
    property var musicData: ({
        "status": "Stopped", "title": "", "artist": "", "artUrl": "",
        "percent": 0, "positionStr": "00:00", "lengthStr": "00:00",
        "length": 1, "playerName": ""
    })
    property bool isMediaActive: musicData.status !== "Stopped" && musicData.title !== "" && musicData.title !== "Not Playing"
    property string selectedPlayer: ""
    property var availablePlayers: []

    // Equalizer
    property var eqData: ({ "preset": "Flat", "b1": 0, "b2": 0, "b3": 0, "b4": 0, "b5": 0,
                             "b6": 0, "b7": 0, "b8": 0, "b9": 0, "b10": 0 })

    // CAVA live bars — individual real props so QML bindings update reliably
    property real cavaBar0: 0.1
    property real cavaBar1: 0.1
    property real cavaBar2: 0.1
    property real cavaBar3: 0.1
    property real cavaBar4: 0.1
    property real cavaBar5: 0.1
    property real cavaMax:  0.1  // loudest bar, drives glow

    // Notifications
    property bool notifActive:            false
    property var  notifData:              null
    property bool wasExpandedBeforeNotif: false
    property bool notifBadgeVisible:      false
    property bool dndEnabled:             false

    // Launcher
    property bool launcherActive: false

    // Discord voice
    property bool discordInCall:     false
    property int  discordCallSeconds: 0
    property int  _discordCallStart:  0

    // OSD
    property bool   osdActive: false
    property string osdType:   ""   // "layout" | "volume" | "brightness"
    property string osdValue:  ""

    Timer {
        id: osdTimer; interval: 1500
        onTriggered: islandWindow.osdActive = false
    }

    // VPN
    property bool   vpnActive:       false
    property string vpnInterface:    ""
    property bool   vpnBadgeVisible: false
    property bool   vpnBadgeConnect: true

    onVpnActiveChanged: {
        vpnBadgeConnect = vpnActive;
        vpnBadgeVisible = true;
        vpnBadgeTimer.restart();
    }

    // Screen recording
    property bool isRecording:          false
    property bool isRecordingPaused:    false
    property int  recordingSeconds:     0
    property real recordingDotOpacity:  1.0

    ListModel { id: notifHistoryList }
    property alias notifHistory: notifHistoryList

    // Stash Model for robust file tray
    ListModel { id: stashModelList }
    property alias stashModel: stashModelList

    Process {
        id: stashScanner
        command: ["bash", "-c", "mkdir -p \"$HOME/Downloads/qs_stash\" && ls -1p \"$HOME/Downloads/qs_stash/\" 2>/dev/null | grep -v 'drop_debug.txt' | grep -v 'drop_log.txt' | sed \"s|^|$HOME/Downloads/qs_stash/|\""]
        stdout: StdioCollector {
            onStreamFinished: {
                islandWindow._isRefreshingStash = true;
                let files = this.text.trim().split('\n');
                islandWindow.stashModel.clear();
                for (let i = 0; i < files.length; i++) {
                    if (files[i]) {
                        var isDirectory = files[i].endsWith('/');
                        var fullPath = isDirectory ? files[i].slice(0, -1) : files[i];
                        islandWindow.stashModel.append({
                            fileURL: "file://" + fullPath,
                            filePath: fullPath,
                            isFav: false,
                            isDir: isDirectory
                        });
                    }
                }
                islandWindow._isRefreshingStash = false;
                if (islandWindow.availablePages.indexOf(islandWindow.currentPage) < 0) {
                    islandWindow.currentPage = islandWindow.availablePages.length > 0 ? islandWindow.availablePages[0] : "clock";
                }
            }
        }
    }
    Component.onCompleted: {
        stashScanner.running = true;
    }

    // Pulse animations — lifted to island level so pages can bind to them
    property real notifPulse: 0.9
    SequentialAnimation on notifPulse {
        running: islandWindow.notifActive; loops: Animation.Infinite
        NumberAnimation { to: 0.3; duration: 900; easing.type: Easing.InOutSine }
        NumberAnimation { to: 0.9; duration: 900; easing.type: Easing.InOutSine }
    }

    property real musicPulse: 0.22
    SequentialAnimation on musicPulse {
        running: islandWindow.isMediaActive && islandWindow.musicData.status === "Playing" && !islandWindow.expanded && !islandWindow.notifActive
        loops: Animation.Infinite
        NumberAnimation { to: 0.72; duration: 1000; easing.type: Easing.InOutSine }
        NumberAnimation { to: 0.22; duration: 1000; easing.type: Easing.InOutSine }
    }

    SequentialAnimation on recordingDotOpacity {
        running: islandWindow.isRecording && !islandWindow.isRecordingPaused; loops: Animation.Infinite
        NumberAnimation { to: 0.15; duration: 620; easing.type: Easing.InOutSine }
        NumberAnimation { to: 1.0;  duration: 620; easing.type: Easing.InOutSine }
    }

    onIsRecordingPausedChanged: { if (isRecordingPaused) recordingDotOpacity = 0.38; }

    // Recording seconds counter — paused when recording is paused
    Timer {
        id: recordingSecTimer
        interval: 1000; repeat: true
        running: islandWindow.isRecording && !islandWindow.isRecordingPaused
        onTriggered: islandWindow.recordingSeconds++
    }

    // Volume drag
    property int  currentVol:      50
    property real volStretch:      0.0
    property bool volDragging:     false
    property real volDragStartX:   0.0
    property int  volDragStartVol: 50

    SpringAnimation on volStretch {
        to: 0.0; spring: 5.0; damping: 0.45
        running: !islandWindow.volDragging
    }

    // Visual edge shift caused by elastic stretch (origin at 8%/92% of collapsedW)
    readonly property real volRightExtra: volStretch > 0 ? islandShape.collapsedW * 0.92 * volStretch * 0.26 : 0
    readonly property real volLeftExtra:  volStretch < 0 ? islandShape.collapsedW * 0.92 * (-volStretch) * 0.26 : 0

    // Expose collapsed width so BaseBubble can clamp against the island boundary
    readonly property int islandCollapsedW: islandShape.collapsedW

    // Bubble slot ordering — inner index = closest to island
    property var leftSlots:  ["vpn", "music", "discord"]
    property var rightSlots: ["rec", "notif", "stash", "clock"]

    // Clock / Weather
    property string timeStr:     ""
    property string timeStrSec:  ""
    property string dateStr:     ""
    property string weatherIcon: ""
    property string weatherTemp: "--°"

    // =========================================================
    // --- HELPERS ---
    // =========================================================
    function exec(cmd) { Quickshell.execDetached(["bash", "-c", cmd]); }
    function shellEsc(s) { return "'" + s.replace(/'/g, "'\\''") + "'" }

    function playSound(type) {
        let map = {
            "notification": "/usr/share/sounds/freedesktop/stereo/message.oga",
            "volume":       "/usr/share/sounds/freedesktop/stereo/audio-volume-change.oga",
        };
        let f = map[type] || "";
        if (f) exec("[ -f \"" + f + "\" ] && paplay \"" + f + "\" 2>/dev/null &");
    }

    // --- Slot-based bubble positioning ---

    function bubbleFor(id) {
        if (id === "music")   return musicBubble
        if (id === "discord") return discordBubble
        if (id === "vpn")     return vpnBadge
        if (id === "rec")     return recBubble
        if (id === "notif")   return badgeBubble
        if (id === "stash")   return stashBubble
        if (id === "clock")   return clockBubble
        return null
    }

    // Returns homeX for a bubble id based on its slot position.
    // Uses islandShape.collapsedW so positions are stable relative to the collapsed
    // island edge; bubbles track via fast Behavior animation (160 ms OutExpo) which
    // is quick enough to stay ahead of the island width animation (540 ms OutExpo).
    function homeXFor(id) {
        let half = islandShape.collapsedW / 2
        let ri = rightSlots.indexOf(id)
        if (ri >= 0) {
            let x = Math.floor(Screen.width / 2) + half + s(14) + volRightExtra
            for (let i = 0; i < ri; i++) {
                let b = bubbleFor(rightSlots[i])
                if (b && b.shouldShow) x += b.width + s(8)
            }
            return x
        }
        let li = leftSlots.indexOf(id)
        if (li >= 0) {
            let bub = bubbleFor(id)
            let x = Math.floor(Screen.width / 2) - half - s(14)
                    - (bub ? bub.width : 0) - volLeftExtra
            for (let i = 0; i < li; i++) {
                let b = bubbleFor(leftSlots[i])
                if (b && b.shouldShow) x -= b.width + s(8)
            }
            return x
        }
        return 0
    }

    // Called by BaseBubble on drag release — places bubble into nearest slot.
    // Uses collapsedW for slot positions (snap always happens while collapsed).
    // Uses shouldShow (not visible) to avoid counting fading-out bubbles as occupying space.
    function snapBubble(id, dropCenterX) {
        let newLeft  = leftSlots.filter(v => v !== id)
        let newRight = rightSlots.filter(v => v !== id)
        let iCenter  = Screen.width / 2
        let halfW    = islandShape.collapsedW / 2

        if (dropCenterX <= iCenter) {
            let insertIdx = newLeft.length
            let x = iCenter - halfW - s(12)
            for (let i = 0; i < newLeft.length; i++) {
                let b  = bubbleFor(newLeft[i])
                let bw = (b && b.shouldShow) ? b.width : 0
                if (bw > 0) {
                    x -= bw
                    if (dropCenterX >= x) { insertIdx = i; break }
                    x -= s(8)
                }
            }
            newLeft.splice(insertIdx, 0, id)
        } else {
            let insertIdx = newRight.length
            let x = iCenter + halfW + s(12)
            for (let i = 0; i < newRight.length; i++) {
                let b  = bubbleFor(newRight[i])
                let bw = (b && b.shouldShow) ? b.width : 0
                if (bw > 0) {
                    if (dropCenterX <= x + bw) { insertIdx = i; break }
                    x += bw + s(8)
                }
            }
            newRight.splice(insertIdx, 0, id)
        }

        leftSlots  = newLeft
        rightSlots = newRight
        saveSlots()
    }

    function saveSlots() {
        Quickshell.execDetached(["bash", "-c",
            "mkdir -p ~/.cache/quickshell && printf '%s' \"$1\" > ~/.cache/quickshell/bubble_slots.json",
            "qs_save", JSON.stringify({ left: leftSlots, right: rightSlots })
        ])
    }

    function saveNotifHistory() {
        let items = [];
        for (let i = 0; i < Math.min(notifHistory.count, 100); i++) {
            let it = notifHistory.get(i);
            items.push({ appName: it.appName, title: it.title, body: it.body, icon: it.icon });
        }
        Quickshell.execDetached(["bash", "-c",
            "mkdir -p ~/.cache/quickshell && printf '%s' \"$1\" > ~/.cache/quickshell/notifications.json",
            "qs_save", JSON.stringify(items)
        ]);
    }

    // Deterministic accent color from app name
    function appAccentColor(appName) {
        let hash = 0;
        let str = appName || "System";
        for (let i = 0; i < str.length; i++) hash = (str.charCodeAt(i) + ((hash << 5) - hash)) | 0;
        let palette = [islandWindow.mauve, islandWindow.blue, islandWindow.green,
                       islandWindow.peach, islandWindow.pink, islandWindow.teal];
        return palette[Math.abs(hash) % palette.length];
    }

    // =========================================================
    // --- PAGE REGISTRY ---
    // To add a new page: create pages/YourPage.qml with `property var island`,
    // then add one entry below — everything else (loading, transitions, nav) is automatic.
    // =========================================================
    // Edit-bar mode: double-tap collapsed island → AppletPickerPage
    property bool editBarMode: false

    function enterEditBarMode() {
        editBarMode   = true
        currentPage   = "appletPicker"
        expanded      = true
        Quickshell.execDetached(["bash", "-c", "printf '1' > /tmp/qs_bar_edit"])
    }

    function exitEditBarMode() {
        if (!editBarMode) return
        editBarMode = false
        currentPage = (prevPage && prevPage !== "appletPicker") ? prevPage : "clock"
        expanded    = false
        Quickshell.execDetached(["bash", "-c", "printf '0' > /tmp/qs_bar_edit"])
    }

    property var pageRegistry: [
        { name: "clock",        expandedH: 350, comp: clockPageComp        },
        { name: "recording",    expandedH: 320, comp: recordingPageComp    },
        { name: "discord",      expandedH: 270, comp: discordPageComp      },
        { name: "music",        expandedH: 630, comp: musicPageComp        },
        { name: "notifs",       expandedH: 450, comp: notifsPageComp       },
        { name: "stash",        expandedH: 260, comp: stashPageComp        },
        { name: "appletPicker", expandedH: 380, comp: appletPickerPageComp },
    ]

    Component { id: clockPageComp;        ClockPage        { island: islandWindow } }
    Component { id: recordingPageComp;    RecordingPage    { island: islandWindow } }
    Component { id: discordPageComp;      DiscordPage      { island: islandWindow } }
    Component { id: musicPageComp;        MusicPage        { island: islandWindow } }
    Component { id: notifsPageComp;       NotifsPage       { island: islandWindow } }
    Component { id: notifExpandedComp;    NotifExpandedPage{ island: islandWindow } }
    Component { id: stashPageComp;        StashPage        { island: islandWindow } }
    Component { id: appletPickerPageComp; AppletPickerPage { island: islandWindow } }

    function dismissNotif() {
        notifHideTimer.stop();
        notifActive = false;
        notifData   = null;
        if (!wasExpandedBeforeNotif) expanded = false;
    }

    Timer {
        id: stashRefreshTimer
        interval: 300
        onTriggered: stashScanner.running = true
    }

    function handleImageDrop(urls) {
        islandWindow.exec("echo 'drop received: " + urls + "' >> $HOME/Downloads/qs_stash/drop_debug.txt");
        var hasImage = false;

        var targetDir = "$HOME/Downloads/qs_stash/";
        if (urls.length > 1) {
            var groupName = "group_" + Date.now();
            targetDir = "$HOME/Downloads/qs_stash/" + groupName + "/";
            islandWindow.exec("mkdir -p " + targetDir);
        }

        for (var i = 0; i < urls.length; i++) {
            var url = urls[i].toString().trim();
            islandWindow.exec("echo 'processing url: " + url + "' >> $HOME/Downloads/qs_stash/drop_debug.txt");
            if (url.startsWith("http://") || url.startsWith("https://")) {
                islandWindow.exec("mkdir -p $HOME/Downloads/qs_stash && wget -q -P $HOME/Downloads/qs_stash/ " + islandWindow.shellEsc(url) + " &");
                hasImage = true;
            } else if (url.startsWith("file://")) {
                var filePath = decodeURIComponent(url.replace('file://', ''));
                islandWindow.exec("mkdir -p $HOME/Downloads/qs_stash && cp -r " + islandWindow.shellEsc(filePath) + " " + targetDir + " >> $HOME/Downloads/qs_stash/drop_log.txt 2>&1 &");
                hasImage = true;
            } else if (url.startsWith("data:image/")) {
                // Complex to parse inline
            } else {
                islandWindow.exec("mkdir -p $HOME/Downloads/qs_stash && cp -r " + islandWindow.shellEsc(url) + " " + targetDir + " >> $HOME/Downloads/qs_stash/drop_log.txt 2>&1 &");
                hasImage = true;
            }
        }
        if (hasImage) {
            islandWindow.currentPage = "stash";
            islandWindow.expanded = true;
            stashRefreshTimer.restart();
        }
    }

    // =========================================================
    // --- PROCESSES & TIMERS ---
    // =========================================================

    // Music info polling
    Process {
        id: musicProc
        command: ["bash", "-c", `~/.config/hypr/scripts/quickshell/music/music_info.sh "${islandWindow.selectedPlayer}"`]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    if (this.text && this.text.trim().length > 0) {
                        let d = JSON.parse(this.text);
                        if (!islandWindow.userIsSeeking) islandWindow.musicData = d;
                    }
                } catch(e) { console.warn(e) }
            }
        }
    }

    // Available players polling
    Process {
        id: playersProc
        command: ["bash", "-c", "playerctl -l 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n").filter(l => l.length > 0)
                islandWindow.availablePlayers = lines
            }
        }
    }
    Timer { interval: 3000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: playersProc.running = true }
    Process {
        id: eqProc
        command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/music/equalizer.sh get"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    if (this.text && this.text.trim().length > 0) islandWindow.eqData = JSON.parse(this.text);
                } catch(e) { console.warn(e) }
            }
        }
    }
    Timer { interval: 800; running: true; repeat: true; triggeredOnStart: true
        onTriggered: { musicProc.running = true; eqProc.running = true; } }

    // Watchdog: ensure cavaProc stays in sync with play state (survives reboot/crash)
    Timer { interval: 1500; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            let should = islandWindow.isMediaActive && islandWindow.musicData.status === "Playing";
            if (should && !cavaProc.running)  cavaProc.running = true;
            if (!should && cavaProc.running) cavaProc.running = false;
        }
    }

    // CAVA: streams 4 bar values per frame in real-time
    // Note: Quickshell Process.running is imperative, not reactive —
    // controlled via onMusicDataChanged below.
    Process {
        id: cavaProc
        command: ["bash", "-c", "cava -p ~/.config/hypr/scripts/quickshell/music/cava_island.cfg 2>/dev/null"]
        running: false
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (line) => {
                let parts = line.trim().split(" ");
                if (parts.length < 6) return;
                function norm(s) {
                    let v = parseInt(s);
                    // autosens calibrates to ~210 peak; headroom prevents hard clip
                    return isNaN(v) ? 0.05 : Math.max(0.05, Math.min(1.0, v / 600.0));
                }
                let b0 = norm(parts[0]), b1 = norm(parts[1]),
                    b2 = norm(parts[2]), b3 = norm(parts[3]),
                    b4 = norm(parts[4]), b5 = norm(parts[5]);
                islandWindow.cavaBar0 = b0;
                islandWindow.cavaBar1 = b1;
                islandWindow.cavaBar2 = b2;
                islandWindow.cavaBar3 = b3;
                islandWindow.cavaBar4 = b4;
                islandWindow.cavaBar5 = b5;
                islandWindow.cavaMax  = Math.max(b0, b1, b2, b3, b4, b5);
            }
        }
        onRunningChanged: {
            if (!running) {
                islandWindow.cavaBar0 = 0.1; islandWindow.cavaBar1 = 0.1;
                islandWindow.cavaBar2 = 0.1; islandWindow.cavaBar3 = 0.1;
                islandWindow.cavaBar4 = 0.1; islandWindow.cavaBar5 = 0.1;
                islandWindow.cavaMax  = 0.1;
            }
        }
    }

    Process {
        id: mprisWatcher; running: true
        command: ["bash", "-c", "dbus-monitor --session \"type='signal',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged',arg0='org.mpris.MediaPlayer2.Player'\" 2>/dev/null | grep -m 1 'member=' > /dev/null || sleep 2"]
        onExited: { musicProc.running = true; running = true; }
    }

    // Clock tick
    Timer { interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            let d = new Date();
            islandWindow.timeStr    = Qt.formatDateTime(d, "hh:mm");
            islandWindow.timeStrSec = Qt.formatDateTime(d, "hh:mm:ss");
            islandWindow.dateStr    = Qt.formatDateTime(d, "ddd, MMM dd");
        }
    }

    // Weather (calls --json to refresh cache, then parses hourly slot)
    Process {
        id: weatherProc
        command: ["bash", "-c",
            "data=$(~/.config/hypr/scripts/quickshell/calendar/weather.sh --json 2>/dev/null); " +
            "ct=$(date +%H:%M); " +
            "icon=$(echo \"$data\" | jq -r --arg ct \"$ct\" '(.forecast[0].hourly | map(select(.time <= $ct)) | last) // .forecast[0].hourly[0] | .icon' 2>/dev/null); " +
            "temp=$(echo \"$data\" | jq -r --arg ct \"$ct\" '(.forecast[0].hourly | map(select(.time <= $ct)) | last) // .forecast[0].hourly[0] | .temp' 2>/dev/null); " +
            "echo \"$icon|$temp\""
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                let parts = this.text.trim().split("|");
                if (parts.length >= 2) {
                    let icon = parts[0].trim();
                    let temp = parts[1].trim();
                    if (icon !== "" && icon !== "null") islandWindow.weatherIcon = icon;
                    if (temp !== "" && temp !== "null" && temp !== "0.0") islandWindow.weatherTemp = temp + "°C";
                }
            }
        }
    }
    Timer { interval: 180000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: weatherProc.running = true }

    // Notification auto-dismiss: collapse + show badge if wasn't already open
    Timer {
        id: notifHideTimer
        interval: 5000
        onTriggered: {
            islandWindow.notifActive = false;
            islandWindow.notifData   = null;
            if (!islandWindow.wasExpandedBeforeNotif) {
                islandWindow.expanded          = false;
                islandWindow.notifBadgeVisible = true;
            }
        }
    }

    // Auto-revert notifs collapsed page back to previous page
    Timer {
        id: notifPageRevertTimer
        interval: 2500
        onTriggered: {
            if (!islandWindow.expanded && islandWindow.currentPage === "notifs")
                islandWindow.currentPage = islandWindow.prevPage;
        }
    }

    // Volume read + set
    Process {
        id: volReadProc
        command: ["bash", "-c", "pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -oP '\\d+(?=%)' | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                let v = parseInt(this.text.trim());
                if (!isNaN(v) && !islandWindow.volDragging) islandWindow.currentVol = v;
            }
        }
    }
    Timer { interval: 2000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: volReadProc.running = true }

    Timer {
        id: volSetThrottle; interval: 40
        property int targetVol: -1
        onTriggered: {
            if (targetVol >= 0) {
                Quickshell.execDetached(["bash", "-c", "pactl set-sink-volume @DEFAULT_SINK@ " + targetVol + "%"]);
                targetVol = -1;
            }
        }
    }

    // VPN state poll (any wireguard interface)
    Process {
        id: vpnProc
        command: ["bash", "-c",
            "iface=$(ip link show up type wireguard 2>/dev/null | " +
            "sed -nE 's/^[0-9]+: ([^:@]+):.*/\\1/p' | head -1); " +
            "[ -n \"$iface\" ] && echo \"1:$iface\" || echo '0:'"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                let parts = this.text.trim().split(":");
                let active = parts[0] === "1";
                let iface  = parts.slice(1).join(":").trim();
                if (active && iface) islandWindow.vpnInterface = iface;
                islandWindow.vpnActive = active;
            }
        }
    }
    Timer { interval: 3000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: vpnProc.running = true }

    Timer { id: vpnBadgeTimer; interval: 4000; onTriggered: islandWindow.vpnBadgeVisible = false }

    // Discord voice call detection — mic capture active = in call
    Process {
        id: discordProc
        command: ["bash", "-c",
            "pactl list source-outputs 2>/dev/null | grep -qi 'application.process.binary.*Discord' && echo '1' || echo '0'"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                let inCall = this.text.trim() === "1"
                if (inCall && !islandWindow.discordInCall) {
                    islandWindow._discordCallStart  = Math.floor(Date.now() / 1000)
                    islandWindow.discordCallSeconds = 0
                }
                if (!inCall) islandWindow.discordCallSeconds = 0
                islandWindow.discordInCall = inCall
            }
        }
    }
    Timer { interval: 3000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: discordProc.running = true }
    Timer { interval: 1000; running: islandWindow.discordInCall; repeat: true
        onTriggered: {
            islandWindow.discordCallSeconds = Math.max(0,
                Math.floor(Date.now() / 1000) - islandWindow._discordCallStart)
        }
    }

    // Launcher state — hide island pill when launcher is open
    Process {
        id: launcherStateWatcher; running: true
        command: ["bash", "-c",
            "inotifywait -qq -e close_write,moved_to --include 'qs_launcher_state$' /tmp/ 2>/dev/null; " +
            "[ -f /tmp/qs_launcher_state ] && cat /tmp/qs_launcher_state"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                islandWindow.launcherActive = this.text.trim() === "1"
                launcherStateWatcher.running = false
                launcherStateWatcher.running = true
            }
        }
    }

    // Screen recording state poll
    Process {
        id: recStateProc
        command: ["bash", "-c",
            "PF=~/.cache/qs_recording_state/wl_pid; " +
            "ST=~/.cache/qs_recording_state/start_time; " +
            "PA=~/.cache/qs_recording_state/paused; " +
            "if [ -f \"$PF\" ] && kill -0 $(cat \"$PF\") 2>/dev/null; then " +
            "  p=0; [ -f \"$PA\" ] && p=1; " +
            "  echo \"1:$(cat \"$ST\" 2>/dev/null || date +%s):$p\"; " +
            "else echo '0:0:0'; fi"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                let parts = this.text.trim().split(":");
                let nowRec    = parts[0] === "1";
                let nowPaused = parts.length > 2 && parts[2] === "1";
                if (!islandWindow.isRecording && nowRec) {
                    let startTs = parseInt(parts[1]) || 0;
                    let nowTs   = Math.floor(Date.now() / 1000);
                    islandWindow.recordingSeconds = Math.max(0, nowTs - startTs);
                }
                islandWindow.isRecording       = nowRec;
                islandWindow.isRecordingPaused = nowRec && nowPaused;
            }
        }
    }
    Timer { interval: 2000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: recStateProc.running = true }

    // DND state from disk
    Process {
        id: dndInit; running: true
        command: ["bash", "-c", "cat ~/.cache/qs_dnd 2>/dev/null || echo '0'"]
        stdout: StdioCollector {
            onStreamFinished: { islandWindow.dndEnabled = (this.text.trim() === "1"); }
        }
    }

    // Notification history from disk (load once on startup)
    Process {
        id: notifHistoryLoader; running: true
        command: ["bash", "-c", "cat ~/.cache/quickshell/notifications.json 2>/dev/null || echo '[]'"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let items = JSON.parse(this.text.trim());
                    if (Array.isArray(items)) {
                        for (let i = 0; i < Math.min(items.length, 100); i++) {
                            notifHistory.append({
                                appName: items[i].appName || "System",
                                title:   items[i].title   || "",
                                body:    items[i].body    || "",
                                icon:    items[i].icon    || ""
                            });
                        }
                    }
                } catch(e) { console.warn(e) }
            }
        }
    }

    // Slot order from disk (load once on startup)
    Process {
        id: slotsLoader; running: true
        command: ["bash", "-c", "cat ~/.cache/quickshell/bubble_slots.json 2>/dev/null || echo '{}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let d = JSON.parse(this.text.trim())
                    if (d.left  && Array.isArray(d.left))  islandWindow.leftSlots  = d.left
                    if (d.right && Array.isArray(d.right)) islandWindow.rightSlots = d.right
                    // Merge any new bubble IDs not present in saved slots
                    let all = islandWindow.leftSlots.concat(islandWindow.rightSlots)
                    let r = islandWindow.rightSlots.slice()
                    let l = islandWindow.leftSlots.slice()
                    for (let id of ["rec", "notif", "stash", "clock"]) {
                        if (all.indexOf(id) < 0) r.push(id)
                    }
                    for (let id of ["vpn", "music", "discord"]) {
                        if (all.indexOf(id) < 0) l.push(id)
                    }
                    islandWindow.rightSlots = r
                    islandWindow.leftSlots  = l
                } catch(e) { console.warn(e) }
            }
        }
    }

    // --- Reactive state ---
    onMusicDataChanged: {
        let should = isMediaActive && musicData.status === "Playing";
        if (should && !cavaProc.running)  cavaProc.running = true;
        if (!should && cavaProc.running) cavaProc.running = false;
    }
    onIsMediaActiveChanged: {
        if (isMediaActive) {
            if (currentPage === "clock") currentPage = "music";
        } else {
            if (expanded && !notifActive) expanded = false;
            if (currentPage === "music") currentPage = "clock";
            if (cavaProc.running) cavaProc.running = false;
        }
    }
    onIsRecordingChanged: {
        if (isRecording) {
            recordingSeconds  = 0;
            isRecordingPaused = false;
            // Low priority: don't hijack currentPage — bubble on right shows state
        } else {
            isRecordingPaused = false;
            if (currentPage === "recording") currentPage = "clock";
            if (!expanded) recordingDotOpacity = 1.0;
        }
    }
    onExpandedChanged: {
        if (expanded) {
            islandShape.forceActiveFocus();
            if (notifBadgeVisible) notifBadgeVisible = false;
            notifPageRevertTimer.stop();
        }
        if (!expanded) {
            if (currentPage === "notifs") notifPageRevertTimer.restart();
            // Collapsing while in editBarMode keeps the mode active —
            // the chip stays, single-tap re-expands the picker, double-tap exits.
        }
    }
    onNotifActiveChanged: {
        if (notifActive) notifBadgeVisible = false;
    }

    // =========================================================
    // --- INPUT MASK ---
    // Covers island + badge bubble (no overlap with top bar)
    // =========================================================
    // In editBarMode: mask to island pill column only — bar applets on the
    // sides are outside this region and receive drag events normally.
    mask: editBarMode   ? editBarMaskedRegion
        : expanded      ? null
        : maskedRegion

    Item {
        id: editBarMaskBounds
        x: islandShape.x - s(8)
        y: 0
        width:  islandShape.width + s(16)
        height: islandShape.y + islandShape.expandedH + s(20)
    }
    Region { id: editBarMaskedRegion; item: editBarMaskBounds }

    Item {
        id: maskBounds

        // Bounding box of island + all visible bubbles at their actual (possibly dragged) positions
        readonly property real _il: Math.floor((Screen.width - islandShape.width) / 2)

        readonly property real _minX: {
            let m = _il;
            if (musicBubble.visible)   m = Math.min(m, musicBubble.x);
            if (discordBubble.visible) m = Math.min(m, discordBubble.x);
            if (vpnBadge.visible)      m = Math.min(m, vpnBadge.x);
            if (badgeBubble.visible)   m = Math.min(m, badgeBubble.x);
            if (recBubble.visible)     m = Math.min(m, recBubble.x);
            if (stashBubble.visible)   m = Math.min(m, stashBubble.x);
            if (clockBubble.visible)   m = Math.min(m, clockBubble.x);
            return Math.max(0, m - s(8));
        }

        readonly property real _maxX: {
            let m = _il + islandShape.width;
            if (musicBubble.visible)   m = Math.max(m, musicBubble.x + musicBubble.width);
            if (discordBubble.visible) m = Math.max(m, discordBubble.x + discordBubble.width);
            if (vpnBadge.visible)      m = Math.max(m, vpnBadge.x + vpnBadge.width);
            if (badgeBubble.visible)   m = Math.max(m, badgeBubble.x + badgeBubble.width);
            if (recBubble.visible)     m = Math.max(m, recBubble.x + recBubble.width);
            if (stashBubble.visible)   m = Math.max(m, stashBubble.x + stashBubble.width);
            if (clockBubble.visible)   m = Math.max(m, clockBubble.x + clockBubble.width);
            return Math.min(Screen.width, m + s(8));
        }

        readonly property real _maxY: {
            let m = islandShape.collapsedH + s(8);
            if (musicBubble.visible)   m = Math.max(m, musicBubble.y + musicBubble.height + s(6));
            if (discordBubble.visible) m = Math.max(m, discordBubble.y + discordBubble.height + s(6));
            if (vpnBadge.visible)      m = Math.max(m, vpnBadge.y + vpnBadge.height + s(6));
            if (badgeBubble.visible)   m = Math.max(m, badgeBubble.y + badgeBubble.height + s(6));
            if (recBubble.visible)     m = Math.max(m, recBubble.y + recBubble.height + s(6));
            if (stashBubble.visible)   m = Math.max(m, stashBubble.y + stashBubble.height + s(6));
            if (clockBubble.visible)   m = Math.max(m, clockBubble.y + clockBubble.height + s(6));
            return m;
        }

        x: _minX
        y: 0
        width:  _maxX - _minX
        height: _maxY
    }
    Region { id: maskedRegion; item: maskBounds }

    // Click-outside-to-close (disabled in editBarMode — clicks land on the bar)
    MouseArea {
        anchors.fill: parent
        enabled: islandWindow.expanded && !islandWindow.editBarMode
        visible: islandWindow.expanded
        z: 0
        onClicked: {
            if (islandWindow.notifActive) {
                notifHideTimer.stop();
                islandWindow.notifActive = false;
                islandWindow.notifData   = null;
            }
            islandWindow.expanded = false;
        }
    }

    // =========================================================
    // --- MAIN ISLAND SHAPE ---
    // =========================================================
    Item {
        id: islandShape
        z: 10

        property int collapsedW: {
            if (islandWindow.osdActive)                                                return osdCollapsed.preferredWidth;
            if (islandWindow.editBarMode || islandWindow.currentPage === "appletPicker") return editModeCollapsed.preferredWidth;
            if (islandWindow.currentPage === "recording" && islandWindow.isRecording) return recordingCollapsed.preferredWidth;
            if (islandWindow.currentPage === "discord"   && islandWindow.discordInCall) return discordCollapsed.preferredWidth;
            if (islandWindow.currentPage === "music"     && islandWindow.isMediaActive) return musicCollapsed.preferredWidth;
            if (islandWindow.currentPage === "notifs")                                  return notifsCollapsed.preferredWidth;
            if (islandWindow.currentPage === "stash")                                   return stashCollapsed.preferredWidth;
            return clockCollapsed.preferredWidth;
        }
        property int collapsedH: s(36)
        property int expandedW: {
            if (islandWindow.currentPage === "stash") {
                return Math.min(s(750), Screen.width - s(32));
            }
            return Math.min(s(760), Screen.width - s(32));
        }
        property int expandedH: {
            if (islandWindow.notifActive) return s(88);
            if (islandWindow.currentPage === "stash") return s(islandWindow.stashExpandedHeight);
            let page = islandWindow.pageRegistry.find(p => p.name === islandWindow.currentPage);
            return page ? s(page.expandedH) : s(350);
        }

        width:  islandWindow.expanded ? expandedW  : collapsedW
        height: islandWindow.expanded ? expandedH  : collapsedH
        x: Math.floor((Screen.width - width) / 2)
        y: s(4)

        opacity: islandWindow.launcherActive ? 0.0 : 1.0
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        Behavior on width  { NumberAnimation { duration: 540; easing.type: Easing.OutExpo } }
        Behavior on height {
            SequentialAnimation {
                // For notifications only: width expands first, height follows after
                PauseAnimation { duration: islandWindow.notifActive && islandWindow.expanded ? 220 : 0 }
                NumberAnimation { duration: 540; easing.type: Easing.OutExpo }
            }
        }

        scale: islandWindow.hovered && !islandWindow.expanded ? 1.025 : 1.0
        Behavior on scale { NumberAnimation { duration: 280; easing.type: Easing.OutExpo } }

        // ── Drop shadow — gives floating feeling, stretches with volume drag ──
        Rectangle {
            id: islandShadow
            anchors.fill: parent
            anchors.margins: -s(6)
            anchors.topMargin: s(10)
            radius: bg.radius + s(6)
            Behavior on radius { NumberAnimation { duration: 540; easing.type: Easing.OutExpo } }
            color: Qt.rgba(0, 0, 0, islandWindow.expanded ? 0.38 : 0.28)
            Behavior on color { ColorAnimation { duration: 400 } }
            z: -1

            transform: Scale {
                xScale: islandWindow.expanded ? 1.0 : (1.0 + Math.abs(islandWindow.volStretch) * 0.26)
                origin.x: islandWindow.volStretch >= 0 ? islandShadow.width * 0.08 : islandShadow.width * 0.92
                origin.y: islandShadow.height * 0.5
            }

            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: 1.0
                blurMax: 28
            }
        }

        // ── Background pill ──────────────────────────────────
        Rectangle {
            id: bg
            anchors.fill: parent
            radius: islandWindow.expanded ? s(26) : height / 2
            Behavior on radius { NumberAnimation { duration: 540; easing.type: Easing.OutExpo } }
            // Elastic volume-drag deform
            transform: Scale {
                xScale: islandWindow.expanded ? 1.0 : (1.0 + Math.abs(islandWindow.volStretch) * 0.26)
                origin.x: islandWindow.volStretch >= 0 ? bg.width * 0.08 : bg.width * 0.92
                origin.y: bg.height * 0.5
            }

            color: {
                if (islandWindow.glassTheme) {
                    let g  = islandWindow.surface2;
                    let ga = islandWindow.expanded ? 0.62
                           : islandWindow.hovered  ? 0.50
                           : 0.40;
                    return Qt.rgba(g.r, g.g, g.b, ga);
                }
                let a = islandWindow.expanded ? 0.93
                      : islandWindow.hovered  ? 0.95
                      : islandWindow.isMediaActive ? 0.88 : 0.78;
                return Qt.rgba(islandWindow.base.r, islandWindow.base.g, islandWindow.base.b, a);
            }
            Behavior on color { ColorAnimation { duration: 300 } }

            border.width: islandWindow.volDragging ? 2 : (islandWindow.isRecording ? 2 : (islandWindow.notifActive ? 2 : (islandWindow.isMediaActive && islandWindow.musicData.status === "Playing" && !islandWindow.expanded ? 2 : 1)))
            Behavior on border.width { NumberAnimation { duration: 300 } }
            border.color: {
                if (islandWindow.osdActive && !islandWindow.expanded) {
                    if (islandWindow.osdType === "volume")     return Qt.rgba(islandWindow.blue.r,  islandWindow.blue.g,  islandWindow.blue.b,  0.55)
                    if (islandWindow.osdType === "brightness") return Qt.rgba(islandWindow.peach.r, islandWindow.peach.g, islandWindow.peach.b, 0.55)
                    return Qt.rgba(islandWindow.teal.r, islandWindow.teal.g, islandWindow.teal.b, 0.55)
                }
                if (islandWindow.volDragging) {
                    let t = islandWindow.currentVol / 100.0;
                    let b = islandWindow.blue, m = islandWindow.mauve;
                    return Qt.rgba(b.r + (m.r - b.r) * t, b.g + (m.g - b.g) * t, b.b + (m.b - b.b) * t,
                                   0.3 + t * 0.7);
                }
                if (islandWindow.isRecording)
                    return Qt.rgba(islandWindow.red.r, islandWindow.red.g, islandWindow.red.b, islandWindow.recordingDotOpacity * 0.85);
                if (islandWindow.notifActive)
                    return Qt.rgba(islandWindow.peach.r, islandWindow.peach.g, islandWindow.peach.b, islandWindow.notifPulse);
                if (islandWindow.isMediaActive && islandWindow.musicData.status === "Playing" && !islandWindow.expanded) {
                    // Tighten musicPulse (0.22→0.72) into a calmer 0.22→0.36 band — premium breath, no neon flash
                    let p = 0.22 + (islandWindow.musicPulse - 0.22) * 0.28;
                    return Qt.rgba(islandWindow.mauve.r, islandWindow.mauve.g, islandWindow.mauve.b, p);
                }
                if (islandWindow.isMediaActive)
                    return Qt.rgba(islandWindow.mauve.r, islandWindow.mauve.g, islandWindow.mauve.b,
                                   islandWindow.hovered || islandWindow.expanded ? 0.45 : 0.22);
                return Qt.rgba(islandWindow.text.r, islandWindow.text.g, islandWindow.text.b,
                               islandWindow.hovered ? 0.15 : 0.06);
            }
            Behavior on border.color { ColorAnimation { duration: islandWindow.volDragging ? 80 : 300 } }

            // Notif / Recording inner glow
            Rectangle {
                anchors.fill: parent; radius: bg.radius
                Behavior on radius { NumberAnimation { duration: 540; easing.type: Easing.OutExpo } }
                opacity: islandWindow.isRecording
                    ? islandWindow.recordingDotOpacity * 0.12
                    : (islandWindow.notifActive ? islandWindow.notifPulse * 0.18 : 0)
                Behavior on opacity { enabled: !islandWindow.notifActive && !islandWindow.isRecording; NumberAnimation { duration: 400 } }
                color: islandWindow.isRecording ? islandWindow.red : islandWindow.peach
                Behavior on color { ColorAnimation { duration: 300 } }
            }

            // Expanded gradient veil
            Rectangle {
                anchors.fill: parent; radius: bg.radius
                Behavior on radius { NumberAnimation { duration: 540; easing.type: Easing.OutExpo } }
                visible: islandWindow.expanded
                opacity: islandWindow.expanded ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 400 } }
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: Qt.rgba(islandWindow.base.r, islandWindow.base.g, islandWindow.base.b, islandWindow.glassTheme ? 0.05 : 0.55) }
                    GradientStop { position: 1.0; color: Qt.rgba(islandWindow.base.r, islandWindow.base.g, islandWindow.base.b, islandWindow.glassTheme ? 0.12 : 0.85) }
                }
            }

        }

        // ── Music playing outer glow — beat-reactive, matches island stretch ──
        // Toned down: thin rim, low max opacity, slow attack — reads as gentle breath, not strobe.
        Rectangle {
            id: glowRim
            anchors.fill: parent
            anchors.margins: -s(2)
            radius: bg.radius + s(2)
            Behavior on radius { NumberAnimation { duration: 540; easing.type: Easing.OutExpo } }
            color: "transparent"
            border.width: s(1)
            border.color: Qt.rgba(islandWindow.mauve.r, islandWindow.mauve.g, islandWindow.mauve.b, 0.55)
            // Compressed beat reactivity — caps around 0.30 instead of ~1.0
            opacity: {
                if (!islandWindow.isMediaActive || islandWindow.musicData.status !== "Playing" || islandWindow.expanded)
                    return 0.0;
                return 0.06 + islandWindow.cavaMax * 0.22;
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: islandWindow.cavaMax > 0.5 ? 90 : 260
                    easing.type: Easing.OutCubic
                }
            }
            z: 0

            // Mirror bg's elastic stretch — origin corrected for -s(3) margin offset
            transform: Scale {
                xScale: islandWindow.expanded ? 1.0 : (1.0 + Math.abs(islandWindow.volStretch) * 0.26)
                origin.x: islandWindow.volStretch >= 0
                    ? (s(3) + bg.width * 0.08)
                    : (s(3) + bg.width * 0.92)
                origin.y: glowRim.height * 0.5
            }
        }

        // ── Mouse: hover + horizontal volume drag ────────────
        MouseArea {
            id: islandMouse
            anchors.fill: parent
            anchors.leftMargin:  -s(14)
            anchors.rightMargin: -s(14)
            anchors.bottomMargin: -s(8)
            hoverEnabled: true
            enabled: !islandWindow.expanded
            z: 0

            onEntered: islandWindow.hovered = true
            onExited:  islandWindow.hovered = false

            property bool wasDragging: false

            onPressed: (mouse) => {
                wasDragging = false;
                islandWindow.volDragStartX   = mouse.x;
                islandWindow.volDragStartVol = islandWindow.currentVol;
            }
            onPositionChanged: (mouse) => {
                if (!islandMouse.pressed) return;
                let dx = mouse.x - islandWindow.volDragStartX;
                if (Math.abs(dx) > 8 || wasDragging) {
                    wasDragging = true;
                    islandWindow.volDragging = true;
                    islandWindow.volStretch = Math.max(-1.0, Math.min(1.0, dx / 160.0));
                    let nv = Math.max(0, Math.min(100, islandWindow.volDragStartVol + Math.round(dx / 3.0)));
                    if (nv !== islandWindow.currentVol) {
                        islandWindow.currentVol = nv;
                        volSetThrottle.targetVol = nv;
                        if (!volSetThrottle.running) volSetThrottle.start();
                    }
                }
            }
            onReleased: {
                if (wasDragging) {
                    islandWindow.volDragging = false;
                    if (Math.abs(islandWindow.currentVol - islandWindow.volDragStartVol) > 2)
                        islandWindow.playSound("volume");
                }
            }
            onClicked: {
                if (!wasDragging) islandWindow.expanded = true;
            }
        }

        // ── Double-tap → toggle bar edit mode ─────────────────────
        // Collapsed + not editing  → enter edit mode (expands picker)
        // Collapsed + editing      → exit edit mode entirely
        TapHandler {
            enabled: !islandWindow.expanded
            acceptedButtons: Qt.LeftButton
            // longPressThreshold kept at default; double-tap window = 300 ms
            onDoubleTapped: {
                if (islandWindow.editBarMode) islandWindow.exitEditBarMode()
                else                          islandWindow.enterEditBarMode()
            }
        }

        // ── Scroll to switch pages (hover collapsed or expanded) ──
        // To add a new screen: 1) push its name into availablePages
        //                       2) create an Item with matching opacity condition
        Timer { id: scrollCooldown; interval: 240 }
        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            target: null
            onWheel: (event) => {
                // In expanded edit mode let scroll propagate to the Flickable
                if (islandWindow.editBarMode && islandWindow.expanded) return;
                if (scrollCooldown.running || islandWindow.notifActive || islandWindow.editBarMode) {
                    event.accepted = true; return;
                }
                if (event.angleDelta.y > 0) islandWindow.navigatePrev();
                else                        islandWindow.navigateNext();
                scrollCooldown.start();
                event.accepted = true;
            }
        }

        // ── DropArea for Global Image Drop ────────────
        DropArea {
            anchors.fill: parent
            keys: ["text/uri-list"]
            
            property bool _justDropped: false

            onEntered: (drag) => {
                if (drag.hasUrls) {
                    islandWindow.isDragHovered = true;
                    islandWindow.currentPage = "stash";
                    islandWindow.expanded = true;
                    drag.accept();
                }
            }

            onExited: {
                islandWindow.isDragHovered = false;
                _justDropped = false;
            }

            onDropped: (drop) => {
                if (drop.hasUrls) {
                    _justDropped = true;
                    islandWindow._dropJustOccurred = true;
                    islandWindow.handleImageDrop(drop.urls);
                    islandWindow.isDragHovered = false;
                    drop.accept();
                }
            }
        }

        // ============================================================
        // COLLAPSED CONTENT — one component per page, crossfade
        // ============================================================
        Item {
            id: collapsedContent
            anchors.fill: parent
            clip: true
            opacity: islandWindow.expanded ? 0 : 1
            visible: opacity > 0.001
            Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.InOutCubic } }
            z: 5

            OSDCollapsed {
                id: osdCollapsed; island: islandWindow; anchors.centerIn: parent
                opacity: islandWindow.osdActive ? 1.0 : 0.0
                visible: opacity > 0.001
                z: 6
                Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.InOutCubic } }
            }

            ClockCollapsed {
                id: clockCollapsed; island: islandWindow; anchors.centerIn: parent
                opacity: (!islandWindow.osdActive && !islandWindow.volDragging && islandWindow.currentPage === "clock") ? 1.0 : 0.0
                visible: opacity > 0.001
                Behavior on opacity { SequentialAnimation {
                    PauseAnimation { duration: islandWindow.currentPage === "clock" && !islandWindow.osdActive ? 60 : 0 }
                    NumberAnimation { duration: 200; easing.type: Easing.InOutCubic }
                }}
            }
            MusicCollapsed {
                id: musicCollapsed; island: islandWindow; anchors.centerIn: parent
                opacity: (!islandWindow.osdActive && !islandWindow.volDragging && islandWindow.currentPage === "music" && islandWindow.isMediaActive) ? 1.0 : 0.0
                visible: opacity > 0.001
                Behavior on opacity { SequentialAnimation {
                    PauseAnimation { duration: islandWindow.currentPage === "music" && !islandWindow.osdActive ? 60 : 0 }
                    NumberAnimation { duration: 200; easing.type: Easing.InOutCubic }
                }}
            }
            NotifsCollapsed {
                id: notifsCollapsed; island: islandWindow; anchors.centerIn: parent
                opacity: (!islandWindow.osdActive && !islandWindow.volDragging && islandWindow.currentPage === "notifs") ? 1.0 : 0.0
                visible: opacity > 0.001
                Behavior on opacity { SequentialAnimation {
                    PauseAnimation { duration: islandWindow.currentPage === "notifs" && !islandWindow.osdActive ? 60 : 0 }
                    NumberAnimation { duration: 200; easing.type: Easing.InOutCubic }
                }}
            }
            StashCollapsed {
                id: stashCollapsed; island: islandWindow; anchors.centerIn: parent
                opacity: (!islandWindow.osdActive && !islandWindow.volDragging && islandWindow.currentPage === "stash" && islandWindow.stashModel.count > 0) ? 1.0 : 0.0
                visible: opacity > 0.001
                Behavior on opacity { SequentialAnimation {
                    PauseAnimation { duration: islandWindow.currentPage === "stash" && !islandWindow.osdActive && islandWindow.stashModel.count > 0 ? 60 : 0 }
                    NumberAnimation { duration: islandWindow.stashModel.count > 0 ? 200 : 0; easing.type: Easing.InOutCubic }
                }}
            }
            RecordingCollapsed {
                id: recordingCollapsed; island: islandWindow; anchors.centerIn: parent
                opacity: (!islandWindow.osdActive && !islandWindow.volDragging && islandWindow.currentPage === "recording" && islandWindow.isRecording) ? 1.0 : 0.0
                visible: opacity > 0.001
                Behavior on opacity { SequentialAnimation {
                    PauseAnimation { duration: islandWindow.currentPage === "recording" && !islandWindow.osdActive ? 60 : 0 }
                    NumberAnimation { duration: 200; easing.type: Easing.InOutCubic }
                }}
            }

            DiscordCollapsed {
                id: discordCollapsed; island: islandWindow; anchors.centerIn: parent
                opacity: (!islandWindow.osdActive && !islandWindow.volDragging && islandWindow.currentPage === "discord" && islandWindow.discordInCall) ? 1.0 : 0.0
                visible: opacity > 0.001
                Behavior on opacity { SequentialAnimation {
                    PauseAnimation { duration: islandWindow.currentPage === "discord" ? 60 : 0 }
                    NumberAnimation { duration: 200; easing.type: Easing.InOutCubic }
                }}
            }

            EditModeCollapsed {
                id: editModeCollapsed; island: islandWindow; anchors.centerIn: parent
                opacity: (!islandWindow.osdActive && !islandWindow.volDragging
                          && (islandWindow.editBarMode || islandWindow.currentPage === "appletPicker")) ? 1.0 : 0.0
                visible: opacity > 0.001
                Behavior on opacity { SequentialAnimation {
                    PauseAnimation { duration: (islandWindow.editBarMode || islandWindow.currentPage === "appletPicker") && !islandWindow.osdActive ? 60 : 0 }
                    NumberAnimation { duration: 200; easing.type: Easing.InOutCubic }
                }}
            }

            // Volume text — sibling of liquidOverlay, no transform inheritance
            Row {
                anchors.centerIn: parent; spacing: s(8)
                z: 11
                opacity: islandWindow.volDragging ? 1.0 : 0.0
                visible: opacity > 0.001
                Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                Text {
                    text: islandWindow.currentVol === 0 ? "󰖁" : (islandWindow.currentVol < 40 ? "󰖀" : "󰕾")
                    font.family: "Iosevka Nerd Font"; font.pixelSize: s(20)
                    color: "white"; anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: islandWindow.currentVol + "%"
                    font.family: "JetBrains Mono"; font.weight: Font.Black; font.pixelSize: s(19)
                    color: "white"; anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        // ============================================================
        // EXPANDED: PAGES — loaded from pageRegistry via Loader
        // ============================================================
        Repeater {
            model: islandWindow.pageRegistry
            delegate: Loader {
                anchors.fill: parent
                sourceComponent: modelData.comp
                z: 5

                readonly property bool isCurrent: islandWindow.expanded && !islandWindow.notifActive && islandWindow.currentPage === modelData.name

                opacity: isCurrent ? 1 : 0
                visible: opacity > 0.001
                Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.InOutCubic } }

                transform: Translate {
                    y: !islandWindow.notifActive && islandWindow.currentPage === modelData.name ? 0 : islandWindow.s(-8)
                    Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutExpo } }
                }
            }
        }

        // Incoming notification overlay (above pages, z:6)
        Loader {
            anchors.fill: parent
            sourceComponent: notifExpandedComp
            z: 6
            opacity: islandWindow.expanded && islandWindow.notifActive ? 1 : 0
            visible: opacity > 0.001
            Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.InOutCubic } }
        }

        // ============================================================
        // NAVIGATION BAR: ‹ dots ›
        // ============================================================
        Item {
            id: navBar
            anchors.bottom: parent.bottom; anchors.bottomMargin: s(14)
            anchors.horizontalCenter: parent.horizontalCenter
            height: s(28); width: navRow.width + s(16)
            opacity: islandWindow.expanded && !islandWindow.notifActive && islandWindow.availablePages.length > 1 ? 1.0 : 0.0
            visible: opacity > 0.001
            Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.InOutCubic } }
            z: 10

            Row {
                id: navRow; anchors.centerIn: parent; spacing: s(12)

                Rectangle {
                    width: s(28); height: s(28); radius: s(14)
                    color: leftArrowMouse.containsMouse ? Qt.rgba(islandWindow.surface1.r, islandWindow.surface1.g, islandWindow.surface1.b, 0.7) : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Text { anchors.centerIn: parent; text: "‹"; font.family: "JetBrains Mono"; font.pixelSize: s(20); font.weight: Font.Black; color: islandWindow.subtext0 }
                    MouseArea { id: leftArrowMouse; anchors.fill: parent; hoverEnabled: true; onClicked: islandWindow.navigatePrev() }
                }

                Row {
                    anchors.verticalCenter: parent.verticalCenter; spacing: s(5)
                    Repeater {
                        model: islandWindow.availablePages.length
                        Rectangle {
                            property bool isActive: islandWindow.availablePages[index] === islandWindow.currentPage
                            width: isActive ? s(18) : s(6); height: s(6); radius: s(3)
                            color: isActive ? islandWindow.mauve : islandWindow.surface2
                            Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutExpo } }
                            Behavior on color { ColorAnimation { duration: 200 } }
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                Rectangle {
                    width: s(28); height: s(28); radius: s(14)
                    color: rightArrowMouse.containsMouse ? Qt.rgba(islandWindow.surface1.r, islandWindow.surface1.g, islandWindow.surface1.b, 0.7) : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Text { anchors.centerIn: parent; text: "›"; font.family: "JetBrains Mono"; font.pixelSize: s(20); font.weight: Font.Black; color: islandWindow.subtext0 }
                    MouseArea { id: rightArrowMouse; anchors.fill: parent; hoverEnabled: true; onClicked: islandWindow.navigateNext() }
                }
            }
        }

        focus: islandWindow.expanded
        Keys.onEscapePressed: {
            if (islandWindow.editBarMode) { islandWindow.exitEditBarMode(); event.accepted = true; }
            else if (islandWindow.expanded) { islandWindow.expanded = false; event.accepted = true; }
        }
    }

    // =========================================================
    // MINI-BUBBLES — satellite pills around the main island
    // =========================================================

    NotifMiniBubble {
        id: badgeBubble
        island: islandWindow
        z: 10
        homeX: homeXFor("notif")
        homeY: s(4) + (islandShape.collapsedH - height) / 2
    }

    VpnMiniBubble {
        id: vpnBadge
        island: islandWindow
        z: 10
        homeX: homeXFor("vpn")
        homeY: s(4) + (islandShape.collapsedH - height) / 2
    }

    MusicMiniBubble {
        id: musicBubble
        island: islandWindow
        z: 10
        homeX: homeXFor("music")
        homeY: s(4) + (islandShape.collapsedH - height) / 2
    }

    DiscordMiniBubble {
        id: discordBubble
        island: islandWindow
        z: 10
        homeX: homeXFor("discord")
        homeY: s(4) + (islandShape.collapsedH - height) / 2
    }

    RecordingMiniBubble {
        id: recBubble
        island: islandWindow
        z: 10
        homeX: homeXFor("rec")
        homeY: s(4) + (islandShape.collapsedH - height) / 2
    }

    StashMiniBubble {
        id: stashBubble
        island: islandWindow
        z: 10
        homeX: homeXFor("stash")
        homeY: s(4) + (islandShape.collapsedH - height) / 2
    }

    ClockMiniBubble {
        id: clockBubble
        island: islandWindow
        z: 10
        homeX: homeXFor("clock")
        homeY: s(4) + (islandShape.collapsedH - height) / 2
    }

    // =========================================================
    // IPC: Incoming notification from Main.qml
    // =========================================================
    Process {
        id: notifIpcWatcher; running: true
        command: ["bash", "-c",
            "inotifywait -qq -e close_write,moved_to --include 'qs_island_notif$' /tmp/ 2>/dev/null; " +
            "if [ -f /tmp/qs_island_notif ]; then cat /tmp/qs_island_notif; rm -f /tmp/qs_island_notif; fi"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                let data = this.text.trim();
                if (data) {
                    try {
                        let n = JSON.parse(data);
                        let item = {
                            appName: n.appName || "System",
                            title:   n.title   || "",
                            body:    n.body    || "",
                            icon:    n.icon    || ""
                        };

                        // Always persist to history
                        notifHistory.insert(0, item);
                        islandWindow.saveNotifHistory();

                        if (!islandWindow.dndEnabled) {
                            // Normal: show popup card + sound
                            islandWindow.playSound("notification");
                            islandWindow.notifData            = item;
                            islandWindow.wasExpandedBeforeNotif = islandWindow.expanded;
                            islandWindow.notifActive          = true;
                            islandWindow.notifAutoSwitched    = true;
                            islandWindow.currentPage          = "notifs";
                            islandWindow.expanded             = true;
                            notifHideTimer.restart();
                        } else {
                            // DND: silent badge only
                            if (!islandWindow.expanded) islandWindow.notifBadgeVisible = true;
                        }
                    } catch(e) { console.warn(e) }
                }
                notifIpcWatcher.running = false;
                notifIpcWatcher.running = true;
            }
        }
    }

    // OSD IPC — volume/brightness scripts write "type|value" to /tmp/qs_osd
    Process {
        id: osdIpcWatcher; running: true
        command: ["bash", "-c",
            "inotifywait -qq -e close_write,moved_to --include 'qs_osd$' /tmp/ 2>/dev/null; " +
            "[ -f /tmp/qs_osd ] && cat /tmp/qs_osd && rm -f /tmp/qs_osd"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                let data = this.text.trim()
                if (data) {
                    let parts = data.split("|")
                    if (parts.length >= 2) {
                        islandWindow.osdType  = parts[0]
                        islandWindow.osdValue = parts[1]
                        islandWindow.osdActive = true
                        osdTimer.restart()
                    }
                }
                osdIpcWatcher.running = false
                osdIpcWatcher.running = true
            }
        }
    }

    // Hyprland layout watcher — listens to socket2 activelayout events
    Process {
        id: layoutWatcher; running: true
        command: ["bash", "-c",
            "sock=\"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock\"; " +
            "socat - \"UNIX-CONNECT:$sock\" 2>/dev/null | " +
            "grep --line-buffered '^activelayout>>' | " +
            "while IFS= read -r line; do " +
            "  layout=\"${line##*,}\"; " +
            "  case \"$layout\" in " +
            "    *Russian*)     echo 'Russian' ;; " +
            "    *English*|*US*) echo 'English' ;; " +
            "    *Ukrainian*)   echo 'Ukrainian' ;; " +
            "    *German*)      echo 'German' ;; " +
            "    *French*)      echo 'French' ;; " +
            "    *Spanish*)     echo 'Spanish' ;; " +
            "    *Polish*)      echo 'Polish' ;; " +
            "    *Turkish*)     echo 'Turkish' ;; " +
            "    *Arabic*)      echo 'Arabic' ;; " +
            "    *Chinese*)     echo 'Chinese' ;; " +
            "    *Japanese*)    echo 'Japanese' ;; " +
            "    *Korean*)      echo 'Korean' ;; " +
            "    *)             echo \"$layout\" ;; " +
            "  esac; " +
            "done"
        ]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (line) => {
                let code = line.trim()
                if (code.length >= 1) {
                    islandWindow.osdType   = "layout"
                    islandWindow.osdValue  = code
                    islandWindow.osdActive = true
                    osdTimer.restart()
                }
            }
        }
        onExited: { running = true }
    }

    // IPC: External expand/collapse toggle (e.g. keybind)
    Process {
        id: ipcWatcher; running: true
        command: ["bash", "-c",
            "inotifywait -qq -e close_write,moved_to --include 'qs_island_toggle$' /tmp/ 2>/dev/null; " +
            "if [ -f /tmp/qs_island_toggle ]; then cat /tmp/qs_island_toggle; rm -f /tmp/qs_island_toggle; fi"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                let cmd = this.text.trim();
                if (cmd === "toggle")        islandWindow.expanded = !islandWindow.expanded;
                else if (cmd === "expand")   islandWindow.expanded = true;
                else if (cmd === "collapse") islandWindow.expanded = false;
                else if (cmd === "edit")     islandWindow.editBarMode ? islandWindow.exitEditBarMode() : islandWindow.enterEditBarMode();
                ipcWatcher.running = false;
                ipcWatcher.running = true;
            }
        }
    }
}
