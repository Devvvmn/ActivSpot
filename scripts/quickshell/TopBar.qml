//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "./topbar"

Variants {
    model: Quickshell.screens

    delegate: Component {
        PanelWindow {
            id: barWindow

            required property var modelData

            // Bind this specific bar instance to the dynamically assigned screen
            screen: modelData

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

            property int barHeight: s(48)

            height: barHeight
            margins { top: s(8); bottom: 0; left: s(4); right: s(4) }
            exclusiveZone: barHeight + s(4)
            color: "transparent"

            // Dynamic Matugen Palette
            MatugenColors { id: mocha }

            // ── Color aliases exposed to applets via `bar.*` ──────────
            readonly property color base:     mocha.base
            readonly property color mantle:   mocha.mantle
            readonly property color crust:    mocha.crust
            readonly property color text:     mocha.text
            readonly property color subtext0: mocha.subtext0
            readonly property color subtext1: mocha.subtext1
            readonly property color surface0: mocha.surface0
            readonly property color surface1: mocha.surface1
            readonly property color surface2: mocha.surface2
            readonly property color overlay0: mocha.overlay0
            readonly property color overlay1: mocha.overlay1
            readonly property color overlay2: mocha.overlay2
            readonly property color blue:     mocha.blue
            readonly property color sapphire: mocha.sapphire
            readonly property color peach:    mocha.peach
            readonly property color green:    mocha.green
            readonly property color red:      mocha.red
            readonly property color mauve:    mocha.mauve
            readonly property color pink:     mocha.pink
            readonly property color yellow:   mocha.yellow
            readonly property color teal:     mocha.teal

            // ── State Variables ───────────────────────────────────────
            property bool showHelpIcon: true

            // WorkspacesModel reference exposed for WorkspacesApplet
            property var wsModel: workspacesModel

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

            // EVENT-DRIVEN WATCHER FOR SETTINGS
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
            Timer { interval: 10; running: true; onTriggered: barWindow.isStartupReady = true }

            property bool startupCascadeFinished: false
            Timer { interval: 1000; running: true; onTriggered: barWindow.startupCascadeFinished = true }

            property bool fastPollerLoaded: false
            property bool isDataReady: fastPollerLoaded
            Timer { interval: 600; running: true; onTriggered: barWindow.isDataReady = true }

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

            ListModel { id: workspacesModel }

            property var musicData: { "status": "Stopped", "title": "", "artUrl": "", "timeStr": "" }

            // Derived properties
            property bool isMediaActive:  barWindow.musicData.status !== "Stopped" && barWindow.musicData.title !== ""
            property bool isWifiOn:       barWindow.wifiStatus.toLowerCase() === "enabled" || barWindow.wifiStatus.toLowerCase() === "on"
            property bool isBtOn:         barWindow.btStatus.toLowerCase() === "enabled"   || barWindow.btStatus.toLowerCase() === "on"
            property bool showEthernet:   barWindow.isDesktop && !barWindow.isWifiOn
            property bool isSoundActive:  !barWindow.isMuted && parseInt(barWindow.volPercent) > 0
            property int  batCap:         parseInt(barWindow.batPercent) || 0
            property bool isCharging:     barWindow.batStatus === "Charging" || barWindow.batStatus === "Full"

            property color batDynamicColor: {
                if (isCharging)  return mocha.green;
                if (batCap <= 20) return mocha.red;
                return mocha.text;
            }

            // ── Applet layout order ───────────────────────────────────
            // Persisted to ~/.cache/quickshell/topbar_layout.json
            property var leftAppletOrder:  ["help", "ws"]
            property var rightAppletOrder: ["tray", "spacer", "kb", "wifi", "bt", "battery"]

            // ── Edit mode — toggled by double-tap on island ───────────
            property bool barEditMode: false

            // IPC: island writes "1"/"0" to /tmp/qs_bar_edit
            Process {
                id: editModeWatcher; running: true
                command: ["bash", "-c",
                    "inotifywait -qq -e close_write,moved_to --include 'qs_bar_edit$' /tmp/ 2>/dev/null; " +
                    "[ -f /tmp/qs_bar_edit ] && cat /tmp/qs_bar_edit && rm -f /tmp/qs_bar_edit"
                ]
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
                id: layoutReloadWatcher; running: true
                command: ["bash", "-c",
                    "inotifywait -qq -e close_write,moved_to --include 'qs_bar_reload$' /tmp/ 2>/dev/null; " +
                    "rm -f /tmp/qs_bar_reload; cat ~/.cache/quickshell/topbar_layout.json 2>/dev/null || echo '{}'"
                ]
                stdout: StdioCollector {
                    onStreamFinished: {
                        try {
                            let d = JSON.parse(this.text.trim());
                            if (d.left  && Array.isArray(d.left))  barWindow.leftAppletOrder  = d.left;
                            if (d.right && Array.isArray(d.right)) barWindow.rightAppletOrder = d.right;
                        } catch(e) {}
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
                            if (d.left  && Array.isArray(d.left))  barWindow.leftAppletOrder  = d.left;
                            if (d.right && Array.isArray(d.right)) barWindow.rightAppletOrder = d.right;
                            // Merge any applet IDs not yet present in saved layout
                            let all = barWindow.leftAppletOrder.concat(barWindow.rightAppletOrder);
                            let r = barWindow.rightAppletOrder.slice();
                            let l = barWindow.leftAppletOrder.slice();
                            for (let id of ["kb", "wifi", "battery"]) {
                                if (all.indexOf(id) < 0) r.push(id);
                            }
                            for (let id of ["help", "ws"]) {
                                if (all.indexOf(id) < 0) l.unshift(id);
                            }
                            barWindow.leftAppletOrder  = l;
                            barWindow.rightAppletOrder = r;
                        } catch(e) {}
                    }
                }
            }

            function saveLayout() {
                Quickshell.execDetached(["bash", "-c",
                    "mkdir -p ~/.cache/quickshell && printf '%s' \"$1\" > ~/.cache/quickshell/topbar_layout.json",
                    "qs_save",
                    JSON.stringify({ left: barWindow.leftAppletOrder, right: barWindow.rightAppletOrder })
                ]);
            }

            // Called by BarZone.snapApplet — single write point, no circular binding
            function updateAppletOrder(zoneSide, newOrder) {
                if (zoneSide === "left")  barWindow.leftAppletOrder  = newOrder;
                else                      barWindow.rightAppletOrder = newOrder;
                barWindow.saveLayout();
            }

            // Called when an applet is dragged across the center into the other zone.
            // fromSide: "left" | "right" — zone the applet was dragged FROM.
            // The applet is appended to the near end of the destination zone.
            function crossZoneDrop(appletId, fromSide) {
                let newLeft  = barWindow.leftAppletOrder.slice();
                let newRight = barWindow.rightAppletOrder.slice();
                if (fromSide === "left") {
                    newLeft  = newLeft.filter(id => id !== appletId);
                    newRight.unshift(appletId);   // insert at left edge of right zone
                } else {
                    newRight = newRight.filter(id => id !== appletId);
                    newLeft.push(appletId);        // append at right edge of left zone
                }
                barWindow.leftAppletOrder  = newLeft;
                barWindow.rightAppletOrder = newRight;
                barWindow.saveLayout();
            }

            onLeftAppletOrderChanged:  Qt.callLater(saveLayout)
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
                                        workspacesModel.append({ "wsId": newData[i].id.toString(), "wsState": newData[i].state });
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
                            } catch(e) { console.warn(e) }
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
                            try { barWindow.musicData = JSON.parse(txt); } catch(e) { console.warn(e) }
                        }
                    }
                }
            }

            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: {
                    if (!barWindow.musicData || barWindow.musicData.status !== "Playing") return;
                    if (!barWindow.musicData.timeStr || barWindow.musicData.timeStr === "") return;

                    let parts = barWindow.musicData.timeStr.split(" / ");
                    if (parts.length !== 2) return;

                    let posParts = parts[0].split(":").map(Number);
                    let lenParts = parts[1].split(":").map(Number);

                    let posSecs = (posParts.length === 3)
                        ? (posParts[0] * 3600 + posParts[1] * 60 + posParts[2])
                        : (posParts[0] * 60 + posParts[1]);

                    let lenSecs = (lenParts.length === 3)
                        ? (lenParts[0] * 3600 + lenParts[1] * 60 + lenParts[2])
                        : (lenParts[0] * 60 + lenParts[1]);

                    if (isNaN(posSecs) || isNaN(lenSecs)) return;

                    posSecs++;
                    if (posSecs > lenSecs) posSecs = lenSecs;

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
                    if (lenSecs > 0) newData.percent = (posSecs / lenSecs) * 100;

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
                id: kbPoller; running: true
                command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/kb_fetch.sh"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        let txt = this.text.trim();
                        if (txt !== "" && barWindow.kbLayout !== txt) barWindow.kbLayout = txt;
                        kbWaiter.running = true;
                        barWindow.fastPollerLoaded = true;
                    }
                }
            }
            Process { id: kbWaiter; command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/kb_wait.sh"]; onExited: kbPoller.running = true }

            // --- AUDIO ---
            Process {
                id: audioPoller; running: true
                command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/audio_fetch.sh"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        let txt = this.text.trim();
                        if (txt !== "") {
                            try {
                                let data = JSON.parse(txt);
                                let newVol = data.volume.toString() + "%";
                                if (barWindow.volPercent !== newVol) barWindow.volPercent = newVol;
                                if (barWindow.volIcon !== data.icon) barWindow.volIcon = data.icon;
                                let newMuted = (data.is_muted === "true");
                                if (barWindow.isMuted !== newMuted) barWindow.isMuted = newMuted;
                            } catch(e) { console.warn(e) }
                        }
                        audioWaiter.running = true;
                    }
                }
            }
            Process { id: audioWaiter; command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/audio_wait.sh"]; onExited: audioPoller.running = true }

            // --- NETWORK ---
            Process {
                id: networkPoller; running: true
                command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/network_fetch.sh"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        let txt = this.text.trim();
                        if (txt !== "") {
                            try {
                                let data = JSON.parse(txt);
                                if (barWindow.wifiStatus !== data.status)     barWindow.wifiStatus = data.status;
                                if (barWindow.wifiIcon   !== data.icon)       barWindow.wifiIcon   = data.icon;
                                if (barWindow.wifiSsid   !== data.ssid)       barWindow.wifiSsid   = data.ssid;
                                if (barWindow.ethStatus  !== data.eth_status) barWindow.ethStatus  = data.eth_status;
                            } catch(e) { console.warn(e) }
                        }
                        networkWaiter.running = true;
                    }
                }
            }
            Process { id: networkWaiter; command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/network_wait.sh"]; onExited: networkPoller.running = true }

            // --- BLUETOOTH ---
            Process {
                id: btPoller; running: true
                command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/bt_fetch.sh"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        let txt = this.text.trim();
                        if (txt !== "") {
                            try {
                                let data = JSON.parse(txt);
                                if (barWindow.btStatus !== data.status)    barWindow.btStatus = data.status;
                                if (barWindow.btIcon   !== data.icon)      barWindow.btIcon   = data.icon;
                                if (barWindow.btDevice !== data.connected) barWindow.btDevice = data.connected;
                            } catch(e) { console.warn(e) }
                        }
                        btWaiter.running = true;
                    }
                }
            }
            Process { id: btWaiter; command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/bt_wait.sh"]; onExited: btPoller.running = true }

            // --- BATTERY ---
            Process {
                id: batteryPoller; running: true
                command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/battery_fetch.sh"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        let txt = this.text.trim();
                        if (txt !== "") {
                            try {
                                let data = JSON.parse(txt);
                                let newBat = data.percent.toString() + "%";
                                if (barWindow.batPercent !== newBat)     barWindow.batPercent = newBat;
                                if (barWindow.batIcon    !== data.icon)  barWindow.batIcon    = data.icon;
                                if (barWindow.batStatus  !== data.status) barWindow.batStatus = data.status;
                            } catch(e) { console.warn(e) }
                        }
                        batteryWaiter.running = true;
                    }
                }
            }
            Process { id: batteryWaiter; command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/battery_wait.sh"]; onExited: batteryPoller.running = true }

            // Native Qt Time Formatting
            Timer {
                interval: 1000; running: true; repeat: true; triggeredOnStart: true
                onTriggered: {
                    let d = new Date();
                    barWindow.timeStr    = Qt.formatDateTime(d, "hh:mm:ss AP");
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

                // CENTER placeholder — reserves space so zones never overlap the island
                Item {
                    id: centerBox
                    anchors.centerIn: parent
                    height: barWindow.barHeight
                    width: {
                        if (!barWindow.isMediaActive) return barWindow.s(260);
                        let titleLen = Math.min(18, (barWindow.musicData.title || "").length);
                        return barWindow.s(190) + titleLen * barWindow.s(7);
                    }
                    Behavior on width { NumberAnimation { duration: 450; easing.type: Easing.OutExpo } }
                }

                // ── LEFT ZONE ──────────────────────────────────────────
                BarZone {
                    id: leftZone
                    side: "left"
                    bar:  barWindow
                    appletOrder: barWindow.leftAppletOrder
                    editMode:    barWindow.barEditMode
                    anchors.left:        parent.left
                    anchors.right:       centerBox.left
                    anchors.rightMargin: barWindow.s(12)
                    anchors.top:         parent.top
                    anchors.bottom:      parent.bottom
                }

                // ── RIGHT ZONE ─────────────────────────────────────────
                BarZone {
                    id: rightZone
                    side: "right"
                    bar:  barWindow
                    appletOrder: barWindow.rightAppletOrder
                    editMode:    barWindow.barEditMode
                    anchors.right:      parent.right
                    anchors.left:       centerBox.right
                    anchors.leftMargin: barWindow.s(12)
                    anchors.top:        parent.top
                    anchors.bottom:     parent.bottom
                }
            }
        }
    }
}
