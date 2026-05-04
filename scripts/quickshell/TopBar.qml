//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "./topbar"
import "./themes"
import qs.Services.UI
import qs.Commons

ShellRoot {

// ── Context menu overlay ───────────────────────────────────────────────────
// Full-screen so outside-clicks are captured for dismiss.
PanelWindow {
    id: ctxOverlay

    visible: PanelService.menuVisible
    color: "transparent"
    screen: PanelService._screen ?? Quickshell.screens[0]

    anchors { top: true; bottom: true; left: true; right: true }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // Dismiss on click anywhere outside the menu box
    MouseArea {
        anchors.fill: parent
        onClicked: PanelService.closeContextMenu(null)
    }

    // Menu box — positioned at the cursor
    Rectangle {
        x: Math.min(Math.round(PanelService.menuX), parent.width  - width  - 4)
        y: Math.min(Math.round(PanelService.menuY), parent.height - height - 4)
        width:  196
        height: PanelService.menuModel.length * 38 + 12
        radius: Style.radiusS
        color:  Color.mSurfaceContainerHigh
        border.color: Qt.rgba(Color.mOutline.r, Color.mOutline.g, Color.mOutline.b, 0.5)
        border.width: 1

        // Eat clicks so they don't propagate to the dismiss MouseArea
        MouseArea { anchors.fill: parent }

        Column {
            anchors { fill: parent; margins: 6 }
            spacing: 2

            Repeater {
                model: PanelService._menu ? PanelService._menu.model : []
                delegate: Rectangle {
                    required property var modelData
                    width:  parent.width
                    height: 36
                    radius: Style.radiusXXS
                    color:  rowMouse.containsMouse
                        ? Qt.rgba(Color.mPrimary.r, Color.mPrimary.g, Color.mPrimary.b, 0.15)
                        : "transparent"

                    Item {
                        anchors.fill: parent

                        Text {
                            id: menuIcon
                            anchors.left:           parent.left
                            anchors.leftMargin:     10
                            anchors.verticalCenter: parent.verticalCenter
                            width: 20
                            horizontalAlignment: Text.AlignHCenter
                            visible: (modelData.icon || "") !== ""
                            text:  IconsTabler.icons[modelData.icon] ?? ""
                            font.family:    "tabler-icons"
                            font.pointSize: Style.fontSizeM
                            color: Color.mOnSurfaceVariant
                        }

                        Text {
                            anchors.left:           menuIcon.right
                            anchors.leftMargin:     8
                            anchors.right:          parent.right
                            anchors.rightMargin:    8
                            anchors.verticalCenter: parent.verticalCenter
                            text:  modelData.label || ""
                            font.family:    "JetBrains Mono"
                            font.pixelSize: 13
                            color: Color.mOnSurface
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: PanelService._trigger(modelData.action || "")
                    }
                }
            }
        }
    }
}

// ── Bar (one per screen) ───────────────────────────────────────────────────
Variants {
    model: Quickshell.screens

    delegate: Component {
        PanelWindow {
            id: barWindow

            required property var modelData

            // Bind this specific bar instance to the dynamically assigned screen
            screen: modelData

            // Hide along with the Dynamic Island when a fullscreen window is
            // focused, so the top of the screen is fully unobstructed.
            visible: !FullscreenService.active

            anchors {
                top: true
                left: true
                right: true
            }

            // --- Responsive Scaling Logic ---
            Scaler {
                id: scaler
                currentWidth: barWindow.width
            }

            property real baseScale: scaler.baseScale

            function s(val) {
                return scaler.s(val);
            }

            property int barHeight: s(36)

            height: barHeight
            margins {
                top: s(4)
                bottom: 0
                left: s(4)
                right: s(4)
            }
            exclusiveZone: barHeight + s(8)   // s(4) above + barHeight + s(4) below
            color: "transparent"

            // ── Theme ─────────────────────────────────────────────────
            // All theme state lives in the Theme singleton; bar.* aliases
            // remain so applets can keep reading bar.mauve / bar.glassTheme.
            readonly property string themeId: Theme.themeId
            readonly property bool glassTheme: Theme.isGlass
            readonly property string surfaceStyle: Theme.surfaceStyle

            readonly property color pillColor: Theme.pillColor
            readonly property color pillBorderColor: Theme.pillBorderColor

            readonly property color base: Theme.base
            readonly property color mantle: Theme.mantle
            readonly property color crust: Theme.crust
            readonly property color text: Theme.text
            readonly property color subtext0: Theme.subtext0
            readonly property color subtext1: Theme.subtext1
            readonly property color surface0: Theme.surface0
            readonly property color surface1: Theme.surface1
            readonly property color surface2: Theme.surface2
            readonly property color overlay0: Theme.overlay0
            readonly property color overlay1: Theme.overlay1
            readonly property color overlay2: Theme.overlay2
            readonly property color blue: Theme.blue
            readonly property color sapphire: Theme.sapphire
            readonly property color peach: Theme.peach
            readonly property color green: Theme.green
            readonly property color red: Theme.red
            readonly property color mauve: Theme.mauve
            readonly property color pink: Theme.pink
            readonly property color yellow: Theme.yellow
            readonly property color teal: Theme.teal

            // ── State Variables ───────────────────────────────────────
            property bool showHelpIcon: true

            // WorkspacesModel reference exposed for WorkspacesApplet
            property var wsModel: workspacesModel

            // Reads non-theme settings (theme is owned by Theme singleton).
            Process {
                id: settingsReader
                command: ["bash", "-c", "cat ~/.config/hypr/settings.json 2>/dev/null || echo '{}'"]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: {
                        try {
                            if (this.text && this.text.trim().length > 0 && this.text.trim() !== "{}") {
                                let parsed = JSON.parse(this.text);
                                if (parsed.topbarHelpIcon !== undefined && barWindow.showHelpIcon !== parsed.topbarHelpIcon) {
                                    barWindow.showHelpIcon = parsed.topbarHelpIcon;
                                }
                            }
                        } catch (e) {}
                    }
                }
            }

            Process {
                id: settingsWatcher
                command: ["bash", "-c", "while [ ! -f ~/.config/hypr/settings.json ]; do sleep 1; done; inotifywait -qq -e modify,close_write ~/.config/hypr/settings.json"]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: {
                        settingsReader.running = false;
                        settingsReader.running = true;
                        settingsWatcher.running = false;
                        settingsWatcher.running = true;
                    }
                }
            }

            // Desktop Chassis Detection
            property bool isDesktop: false
            property string ethStatus: "Ethernet"

            Process {
                id: chassisDetector
                running: true
                command: ["bash", "-c", "if ls /sys/class/power_supply/BAT* 1> /dev/null 2>&1; then echo 'laptop'; else echo 'desktop'; fi"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        barWindow.isDesktop = (this.text.trim() === "desktop");
                    }
                }
            }

            property bool isStartupReady: false
            Timer {
                interval: 10
                running: true
                onTriggered: barWindow.isStartupReady = true
            }

            property bool startupCascadeFinished: false
            Timer {
                interval: 1000
                running: true
                onTriggered: barWindow.startupCascadeFinished = true
            }

            property bool fastPollerLoaded: false
            property bool isDataReady: fastPollerLoaded
            Timer {
                interval: 600
                running: true
                onTriggered: barWindow.isDataReady = true
            }

            property string timeStr: ""
            property string fullDateStr: ""
            property int typeInIndex: 0
            property string dateStr: fullDateStr.substring(0, typeInIndex)

            property string wifiStatus: "Off"
            property string wifiIcon: "󰤮"
            property string wifiSsid: ""

            property string btStatus: "Off"
            property string btIcon: "󰂲"
            property string btDevice: ""

            property string volPercent: "0%"
            property string volIcon: "󰕾"
            property bool isMuted: false

            property string batPercent: "100%"
            property string batIcon: "󰁹"
            property string batStatus: "Unknown"

            property string kbLayout: "us"

            ListModel {
                id: workspacesModel
            }

            property var musicData: {
                "status": "Stopped",
                "title": "",
                "artUrl": "",
                "timeStr": ""
            }

            // Derived properties
            property bool isMediaActive: barWindow.musicData.status !== "Stopped" && barWindow.musicData.title !== ""
            property bool isWifiOn: barWindow.wifiStatus.toLowerCase() === "enabled" || barWindow.wifiStatus.toLowerCase() === "on"
            property bool isBtOn: barWindow.btStatus.toLowerCase() === "enabled" || barWindow.btStatus.toLowerCase() === "on"
            property bool showEthernet: barWindow.isDesktop && !barWindow.isWifiOn
            property bool isSoundActive: !barWindow.isMuted && parseInt(barWindow.volPercent) > 0
            property int batCap: parseInt(barWindow.batPercent) || 0
            property bool isCharging: barWindow.batStatus === "Charging" || barWindow.batStatus === "Full"

            property color batDynamicColor: {
                if (isCharging)
                    return barWindow.green;
                if (batCap <= 20)
                    return barWindow.red;
                return barWindow.text;
            }

            // ── Applet layout order ───────────────────────────────────
            // Persisted to ~/.cache/quickshell/topbar_layout.json
            property var leftAppletOrder: ["help", "ws"]
            property var rightAppletOrder: ["tray", "spacer", "kb", "wifi", "bt", "battery"]

            // ── Edit mode — toggled by double-tap on island ───────────
            property bool barEditMode: false

            // IPC: island writes "1"/"0" to /tmp/qs_bar_edit
            Process {
                id: editModeWatcher
                running: true
                command: ["bash", "-c", "inotifywait -qq -e close_write,moved_to --include 'qs_bar_edit$' /tmp/ 2>/dev/null; " + "[ -f /tmp/qs_bar_edit ] && cat /tmp/qs_bar_edit && rm -f /tmp/qs_bar_edit"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        barWindow.barEditMode = (this.text.trim() === "1");
                        editModeWatcher.running = false;
                        editModeWatcher.running = true;
                    }
                }
            }

            // IPC: AppletPickerPage writes /tmp/qs_bar_reload after updating layout JSON
            Process {
                id: layoutReloadWatcher
                running: true
                command: ["bash", "-c", "inotifywait -qq -e close_write,moved_to --include 'qs_bar_reload$' /tmp/ 2>/dev/null; " + "rm -f /tmp/qs_bar_reload; cat ~/.cache/quickshell/topbar_layout.json 2>/dev/null || echo '{}'"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        try {
                            let d = JSON.parse(this.text.trim());
                            if (d.left && Array.isArray(d.left))
                                barWindow.leftAppletOrder = d.left;
                            if (d.right && Array.isArray(d.right))
                                barWindow.rightAppletOrder = d.right;
                        } catch (e) {}
                        layoutReloadWatcher.running = false;
                        layoutReloadWatcher.running = true;
                    }
                }
            }

            Process {
                id: layoutLoader
                running: true
                command: ["bash", "-c", "cat ~/.cache/quickshell/topbar_layout.json 2>/dev/null || echo '{}'"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        try {
                            let d = JSON.parse(this.text.trim());
                            if (d.left && Array.isArray(d.left))
                                barWindow.leftAppletOrder = d.left;
                            if (d.right && Array.isArray(d.right))
                                barWindow.rightAppletOrder = d.right;
                            // Merge any applet IDs not yet present in saved layout
                            let all = barWindow.leftAppletOrder.concat(barWindow.rightAppletOrder);
                            let r = barWindow.rightAppletOrder.slice();
                            let l = barWindow.leftAppletOrder.slice();
                            for (let id of ["kb", "wifi", "battery"]) {
                                if (all.indexOf(id) < 0)
                                    r.push(id);
                            }
                            for (let id of ["help", "ws"]) {
                                if (all.indexOf(id) < 0)
                                    l.unshift(id);
                            }
                            barWindow.leftAppletOrder = l;
                            barWindow.rightAppletOrder = r;
                        } catch (e) {}
                    }
                }
            }

            function saveLayout() {
                Quickshell.execDetached(["bash", "-c", "mkdir -p ~/.cache/quickshell && printf '%s' \"$1\" > ~/.cache/quickshell/topbar_layout.json", "qs_save", JSON.stringify({
                        left: barWindow.leftAppletOrder,
                        right: barWindow.rightAppletOrder
                    })]);
            }

            // Called by BarZone.snapApplet — single write point, no circular binding
            function updateAppletOrder(zoneSide, newOrder) {
                if (zoneSide === "left")
                    barWindow.leftAppletOrder = newOrder;
                else
                    barWindow.rightAppletOrder = newOrder;
                barWindow.saveLayout();
            }

            // Remove an applet by ID from whichever zone holds it.
            function removeApplet(appletId) {
                let l = barWindow.leftAppletOrder.filter(id => id !== appletId);
                let r = barWindow.rightAppletOrder.filter(id => id !== appletId);
                barWindow.leftAppletOrder = l;
                barWindow.rightAppletOrder = r;
                barWindow.saveLayout();
            }

            // Called when an applet is dragged across the center into the other zone.
            // fromSide: "left" | "right" — zone the applet was dragged FROM.
            // The applet is appended to the near end of the destination zone.
            function crossZoneDrop(appletId, fromSide) {
                let newLeft = barWindow.leftAppletOrder.slice();
                let newRight = barWindow.rightAppletOrder.slice();
                if (fromSide === "left") {
                    newLeft = newLeft.filter(id => id !== appletId);
                    newRight.unshift(appletId);   // insert at left edge of right zone
                } else {
                    newRight = newRight.filter(id => id !== appletId);
                    newLeft.push(appletId);        // append at right edge of left zone
                }
                barWindow.leftAppletOrder = newLeft;
                barWindow.rightAppletOrder = newRight;
                barWindow.saveLayout();
            }

            onLeftAppletOrderChanged: Qt.callLater(saveLayout)
            onRightAppletOrderChanged: Qt.callLater(saveLayout)

            // ==========================================
            // DATA FETCHING
            // ==========================================

            // Workspaces
            Process {
                id: wsDaemon
                command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/workspaces.sh"]
                running: true
            }

            Process {
                id: wsReader
                command: ["cat", "/tmp/qs_workspaces.json"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        let txt = this.text.trim();
                        if (txt !== "") {
                            try {
                                let newData = JSON.parse(txt);
                                if (workspacesModel.count !== newData.length) {
                                    workspacesModel.clear();
                                    for (let i = 0; i < newData.length; i++) {
                                        workspacesModel.append({
                                            "wsId": newData[i].id.toString(),
                                            "wsState": newData[i].state
                                        });
                                    }
                                } else {
                                    for (let i = 0; i < newData.length; i++) {
                                        if (workspacesModel.get(i).wsState !== newData[i].state) {
                                            workspacesModel.setProperty(i, "wsState", newData[i].state);
                                        }
                                        if (workspacesModel.get(i).wsId !== newData[i].id.toString()) {
                                            workspacesModel.setProperty(i, "wsId", newData[i].id.toString());
                                        }
                                    }
                                }
                            } catch (e) {
                                console.warn(e);
                            }
                        }
                    }
                }
            }

            Process {
                id: wsWatcher
                running: true
                command: ["bash", "-c", "inotifywait -qq -e close_write,modify /tmp/qs_workspaces.json"]
                onExited: {
                    wsReader.running = true;
                    running = true;
                }
            }

            // Music
            Process {
                id: musicForceRefresh
                running: true
                command: ["bash", "-c", "bash ~/.config/hypr/scripts/quickshell/music/music_info.sh | tee /tmp/music_info.json"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        let txt = this.text.trim();
                        if (txt !== "") {
                            try {
                                barWindow.musicData = JSON.parse(txt);
                            } catch (e) {
                                console.warn(e);
                            }
                        }
                    }
                }
            }

            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: {
                    if (!barWindow.musicData || barWindow.musicData.status !== "Playing")
                        return;
                    if (!barWindow.musicData.timeStr || barWindow.musicData.timeStr === "")
                        return;

                    let parts = barWindow.musicData.timeStr.split(" / ");
                    if (parts.length !== 2)
                        return;

                    let posParts = parts[0].split(":").map(Number);
                    let lenParts = parts[1].split(":").map(Number);

                    let posSecs = (posParts.length === 3) ? (posParts[0] * 3600 + posParts[1] * 60 + posParts[2]) : (posParts[0] * 60 + posParts[1]);

                    let lenSecs = (lenParts.length === 3) ? (lenParts[0] * 3600 + lenParts[1] * 60 + lenParts[2]) : (lenParts[0] * 60 + lenParts[1]);

                    if (isNaN(posSecs) || isNaN(lenSecs))
                        return;

                    posSecs++;
                    if (posSecs > lenSecs)
                        posSecs = lenSecs;

                    let newPosStr = "";
                    if (posParts.length === 3) {
                        let h = Math.floor(posSecs / 3600);
                        let m = Math.floor((posSecs % 3600) / 60);
                        let s = posSecs % 60;
                        newPosStr = h + ":" + (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s;
                    } else {
                        let m = Math.floor(posSecs / 60);
                        let s = posSecs % 60;
                        newPosStr = (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s;
                    }

                    let newData = Object.assign({}, barWindow.musicData);
                    newData.timeStr = newPosStr + " / " + parts[1];
                    newData.positionStr = newPosStr;
                    if (lenSecs > 0)
                        newData.percent = (posSecs / lenSecs) * 100;

                    barWindow.musicData = newData;
                }
            }

            Process {
                id: mprisWatcher
                running: true
                command: ["bash", "-c", "dbus-monitor --session \"type='signal',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged',arg0='org.mpris.MediaPlayer2.Player'\" \"type='signal',interface='org.mpris.MediaPlayer2.Player',member='Seeked'\" 2>/dev/null | grep -m 1 'member=' > /dev/null || sleep 2"]
                onExited: {
                    musicForceRefresh.running = true;
                    running = true;
                }
            }

            // ==========================================
            // MODULAR SYSTEM WATCHERS
            // ==========================================

            // --- KEYBOARD ---
            Process {
                id: kbPoller
                running: true
                command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/kb_fetch.sh"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        let txt = this.text.trim();
                        if (txt !== "" && barWindow.kbLayout !== txt)
                            barWindow.kbLayout = txt;
                        kbWaiter.running = true;
                        barWindow.fastPollerLoaded = true;
                    }
                }
            }
            Process {
                id: kbWaiter
                command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/kb_wait.sh"]
                onExited: kbPoller.running = true
            }

            // --- AUDIO ---
            Process {
                id: audioPoller
                running: true
                command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/audio_fetch.sh"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        let txt = this.text.trim();
                        if (txt !== "") {
                            try {
                                let data = JSON.parse(txt);
                                let newVol = data.volume.toString() + "%";
                                if (barWindow.volPercent !== newVol)
                                    barWindow.volPercent = newVol;
                                if (barWindow.volIcon !== data.icon)
                                    barWindow.volIcon = data.icon;
                                let newMuted = (data.is_muted === "true");
                                if (barWindow.isMuted !== newMuted)
                                    barWindow.isMuted = newMuted;
                            } catch (e) {
                                console.warn(e);
                            }
                        }
                        audioWaiter.running = true;
                    }
                }
            }
            Process {
                id: audioWaiter
                command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/audio_wait.sh"]
                onExited: audioPoller.running = true
            }

            // --- NETWORK ---
            Process {
                id: networkPoller
                running: true
                command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/network_fetch.sh"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        let txt = this.text.trim();
                        if (txt !== "") {
                            try {
                                let data = JSON.parse(txt);
                                if (barWindow.wifiStatus !== data.status)
                                    barWindow.wifiStatus = data.status;
                                if (barWindow.wifiIcon !== data.icon)
                                    barWindow.wifiIcon = data.icon;
                                if (barWindow.wifiSsid !== data.ssid)
                                    barWindow.wifiSsid = data.ssid;
                                if (barWindow.ethStatus !== data.eth_status)
                                    barWindow.ethStatus = data.eth_status;
                            } catch (e) {
                                console.warn(e);
                            }
                        }
                        networkWaiter.running = true;
                    }
                }
            }
            Process {
                id: networkWaiter
                command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/network_wait.sh"]
                onExited: networkPoller.running = true
            }

            // --- BLUETOOTH ---
            Process {
                id: btPoller
                running: true
                command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/bt_fetch.sh"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        let txt = this.text.trim();
                        if (txt !== "") {
                            try {
                                let data = JSON.parse(txt);
                                if (barWindow.btStatus !== data.status)
                                    barWindow.btStatus = data.status;
                                if (barWindow.btIcon !== data.icon)
                                    barWindow.btIcon = data.icon;
                                if (barWindow.btDevice !== data.connected)
                                    barWindow.btDevice = data.connected;
                            } catch (e) {
                                console.warn(e);
                            }
                        }
                        btWaiter.running = true;
                    }
                }
            }
            Process {
                id: btWaiter
                command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/bt_wait.sh"]
                onExited: btPoller.running = true
            }

            // --- BATTERY ---
            Process {
                id: batteryPoller
                running: true
                command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/battery_fetch.sh"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        let txt = this.text.trim();
                        if (txt !== "") {
                            try {
                                let data = JSON.parse(txt);
                                let newBat = data.percent.toString() + "%";
                                if (barWindow.batPercent !== newBat)
                                    barWindow.batPercent = newBat;
                                if (barWindow.batIcon !== data.icon)
                                    barWindow.batIcon = data.icon;
                                if (barWindow.batStatus !== data.status)
                                    barWindow.batStatus = data.status;
                            } catch (e) {
                                console.warn(e);
                            }
                        }
                        batteryWaiter.running = true;
                    }
                }
            }
            Process {
                id: batteryWaiter
                command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/battery_wait.sh"]
                onExited: batteryPoller.running = true
            }

            // Native Qt Time Formatting
            Timer {
                interval: 1000
                running: true
                repeat: true
                triggeredOnStart: true
                onTriggered: {
                    let d = new Date();
                    barWindow.timeStr = Qt.formatDateTime(d, "hh:mm:ss AP");
                    barWindow.fullDateStr = Qt.formatDateTime(d, "dddd, MMMM dd");
                    if (barWindow.typeInIndex >= barWindow.fullDateStr.length) {
                        barWindow.typeInIndex = barWindow.fullDateStr.length;
                    }
                }
            }

            Timer {
                id: typewriterTimer
                interval: 40
                running: barWindow.isStartupReady && barWindow.typeInIndex < barWindow.fullDateStr.length
                repeat: true
                onTriggered: barWindow.typeInIndex += 1
            }

            // ==========================================
            // UI LAYOUT
            // ==========================================
            Item {
                anchors.fill: parent

                // ── Edit mode: unified background frame ───────────────
                // Mocha
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -barWindow.s(4)
                    radius: barWindow.s(20)
                    color: Qt.rgba(barWindow.surface0.r, barWindow.surface0.g, barWindow.surface0.b, 1.0)
                    border.width: 1
                    border.color: Qt.rgba(barWindow.mauve.r, barWindow.mauve.g, barWindow.mauve.b, 0.50)
                    opacity: (barWindow.barEditMode ? 1 : 0) * (barWindow.glassTheme ? 0 : 1)
                    visible: opacity > 0.001
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 520
                            easing.type: Easing.InOutCubic
                        }
                    }
                    z: -1
                }
                // Glass
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -barWindow.s(4)
                    radius: barWindow.s(20)
                    color: Qt.rgba(1, 1, 1, 0.07)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.25)
                    opacity: (barWindow.barEditMode ? 1 : 0) * (barWindow.glassTheme ? 1 : 0)
                    visible: opacity > 0.001
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 520
                            easing.type: Easing.InOutCubic
                        }
                    }
                    z: -1
                }

                // ── Edit mode: center separator ───────────────────────
                Item {
                    x: centerBox.x
                    width: centerBox.width
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    opacity: barWindow.barEditMode ? 1 : 0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 280
                            easing.type: Easing.OutCubic
                        }
                    }
                    z: 5

                    // vertical dashed line
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        width: 1
                        height: parent.height * 0.55
                        color: Qt.rgba(barWindow.mauve.r, barWindow.mauve.g, barWindow.mauve.b, 0.35)
                    }

                    // ⇄ icon
                    Text {
                        anchors.centerIn: parent
                        text: "⇄"
                        font.pixelSize: barWindow.s(14)
                        color: Qt.rgba(barWindow.mauve.r, barWindow.mauve.g, barWindow.mauve.b, 0.6)
                    }
                }

                // CENTER placeholder — reserves space so zones never overlap the island
                Item {
                    id: centerBox
                    anchors.centerIn: parent
                    height: barWindow.barHeight
                    width: {
                        if (!barWindow.isMediaActive)
                            return barWindow.s(260);
                        let titleLen = Math.min(18, (barWindow.musicData.title || "").length);
                        return barWindow.s(190) + titleLen * barWindow.s(7);
                    }
                    Behavior on width {
                        NumberAnimation {
                            duration: 450
                            easing.type: Easing.OutExpo
                        }
                    }
                }

                // ── LEFT ZONE ──────────────────────────────────────────
                BarZone {
                    id: leftZone
                    side: "left"
                    bar: barWindow
                    appletOrder: barWindow.leftAppletOrder
                    editMode: barWindow.barEditMode
                    showGroupFrames: false
                    anchors.left: parent.left
                    anchors.right: centerBox.left
                    anchors.rightMargin: barWindow.s(12)
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                }

                // ── RIGHT ZONE ─────────────────────────────────────────
                BarZone {
                    id: rightZone
                    side: "right"
                    bar: barWindow
                    appletOrder: barWindow.rightAppletOrder
                    editMode: barWindow.barEditMode
                    anchors.right: parent.right
                    anchors.left: centerBox.right
                    anchors.leftMargin: barWindow.s(12)
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                }
            }
        }
    }
}

} // ShellRoot
