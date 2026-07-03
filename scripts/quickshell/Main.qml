import QtQuick
import QtQuick.Window
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Notifications
import "WindowRegistry.js" as Registry

PanelWindow {
    id: masterWindow

    color: "transparent"

    WlrLayershell.namespace: "qs-master"
    WlrLayershell.layer: WlrLayer.Overlay
    
    exclusionMode: ExclusionMode.Ignore 
    focusable: true

    width: Screen.width
    height: Screen.height

    visible: isVisible

    mask: Region { item: topBarHole; intersection: Intersection.Xor }
    
    Item {
        id: topBarHole
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 65 
    }

    MouseArea {
        anchors.fill: parent
        enabled: masterWindow.isVisible
        onClicked: switchWidget("hidden", "")
    }

    Component.onCompleted: {
        Quickshell.execDetached(["bash", "-c", "echo '" + currentActive + "' > /tmp/qs_active_widget"]);
    }

    property string currentActive: "hidden" 
    property bool isVisible: false
    property string activeArg: ""
    property bool disableMorph: false 
    property int morphDuration: 500
    property int exitDuration: 300 // Controls how fast the outgoing widget disappears

    property real animW: 1
    property real animH: 1
    property real animX: 0
    property real animY: 0
    
    property real targetW: 1
    property real targetH: 1

    property real globalUiScale: 1.0

    // =========================================================
    // --- DAEMON: NOTIFICATION HANDLING
    // =========================================================
    // 1. Permanent History (For the Notification Center)
    ListModel {
        id: globalNotificationHistory
    }

    // 2. Transient Popups (For the OSD)
    ListModel {
        id: activePopupsModel
    }

    property int _popupCounter: 0

    function removePopup(uid) {
        for (let i = 0; i < activePopupsModel.count; i++) {
            if (activePopupsModel.get(i).uid === uid) {
                activePopupsModel.remove(i);
                break;
            }
        }
    }

    // Live notifications kept for cross-process action invocation (the island
    // runs as a separate quickshell process — it sends {id,type,key,text} JSON
    // back through /tmp/qs_notif_action, we invoke on the retained object).
    property var _liveNotifs: ({})

    NotificationServer {
        id: globalNotificationServer
        bodySupported: true
        actionsSupported: true
        imageSupported: true
        inlineReplySupported: true

        onNotification: (n) => {
            // ── Progress notifications → Live Activities ────────────────
            // Apps sending the freedesktop `value` hint (0–100: KDE file
            // ops, some browsers, `notify-send -h int:value:N`) become a
            // live island card with a real progress bar instead of a toast.
            // Replacements (same id, new value) update the card in place.
            let laProgress = -1;
            try {
                let hv = n.hints ? n.hints["value"] : undefined;
                if (hv !== undefined && hv !== null && hv !== "") {
                    let pv = parseInt(hv);
                    if (!isNaN(pv)) laProgress = pv;
                }
            } catch(e) {}
            if (laProgress >= 0) {
                n.tracked = true;   // keep alive so closed → end event fires
                let laId = "notif-" + n.id;
                Quickshell.execDetached([
                    "bash", "-c",
                    'printf "%s\n" "$1" >> /tmp/qs_live_activity',
                    "qs_la_sender",
                    JSON.stringify({
                        id:       laId,
                        icon:     "󰛴",
                        title:    n.summary !== "" ? n.summary : n.appName,
                        subtitle: n.body !== "" ? n.body : n.appName,
                        progress: Math.min(1, laProgress / 100),
                        ttlMs:    45000,
                        kind:     "notif"
                    })
                ]);
                n.closed.connect(() => {
                    Quickshell.execDetached([
                        "bash", "-c",
                        'printf "%s\n" "$1" >> /tmp/qs_live_activity',
                        "qs_la_sender",
                        JSON.stringify({ id: laId, event: "end", status: "ok" })
                    ]);
                });
                return;   // no toast, no history spam — the card is the UI
            }

            console.log("Saving to history:", n.appName, "-", n.summary);

            // Retain so actions/inline-reply can be invoked later from the island
            n.tracked = true;
            masterWindow._liveNotifs[n.id] = n;
            let closedId = n.id;
            n.closed.connect(() => {
                delete masterWindow._liveNotifs[closedId];
                // Broadcast so the island can grey out dead action chips /
                // retract the banner when the app closes the notification
                // (e.g. message read on phone). Append — never clobber a
                // pending unconsumed notification line.
                Quickshell.execDetached([
                    "bash", "-c",
                    'printf "%s\n" "$1" >> /tmp/qs_island_notif',
                    "qs_notif_sender",
                    JSON.stringify({ type: "closed", id: closedId })
                ]);
            });

            // Resolve best icon: prefer n.image (avatar/inline image), fall back to app icon name.
            // n.image may be a plain string path or an object with .source depending on
            // quickshell version — handle both, else avatars silently never show.
            let iconUrl = "";
            try {
                let img = n.image;
                if (img && typeof img === "object" && img.source !== undefined) img = img.source;
                if (img && img.toString() !== "") iconUrl = img.toString();
            } catch(e) {}
            if (iconUrl === "" && n.appIcon !== "") iconUrl = n.appIcon;
            // quickshell wraps filesystem paths in its icon provider
            // ("image://icon//home/…") — unwrap so path detection works downstream
            if (iconUrl.startsWith("image://icon/")) iconUrl = iconUrl.substring(13);

            let notifData = {
                "appName": n.appName !== "" ? n.appName : "System",
                "summary": n.summary !== "" ? n.summary : "No Title",
                "body": n.body !== "" ? n.body : "",
                "iconPath": iconUrl,
                "notif": n
            };

            // A. Insert into the permanent center
            globalNotificationHistory.insert(0, notifData);

            // B. Append to the on-screen popups
            masterWindow._popupCounter++;
            let popupData = Object.assign({ "uid": masterWindow._popupCounter }, notifData);
            activePopupsModel.append(popupData);

            // C. Show in Dynamic Island via IPC — actions/reply metadata included
            let actionList = [];
            try {
                for (let i = 0; i < n.actions.length; i++)
                    actionList.push({ k: n.actions[i].identifier, t: n.actions[i].text });
            } catch(e) {}
            Quickshell.execDetached([
                "bash", "-c",
                'printf "%s\n" "$1" >> /tmp/qs_island_notif',
                "qs_notif_sender",
                JSON.stringify({
                    appName:  notifData.appName,
                    title:    notifData.summary,
                    body:     notifData.body,
                    icon:     notifData.iconPath,
                    id:       n.id,
                    actions:  actionList,
                    hasReply: n.hasInlineReply === true,
                    urgency:  n.urgency !== undefined ? n.urgency : 1
                })
            ]);
        }
    }

    // Back-channel: island → server. Single-shot inotifywait (no -m), anchored.
    Process {
        id: notifActionWatcher; running: true
        command: ["bash", "-c",
            "inotifywait -qq -e close_write,moved_to --include 'qs_notif_action$' /tmp/ 2>/dev/null; " +
            "if [ -f /tmp/qs_notif_action ]; then cat /tmp/qs_notif_action; rm -f /tmp/qs_notif_action; fi"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                // May contain several appended lines — parse each independently
                let lines = this.text.trim().split("\n");
                for (let li = 0; li < lines.length; li++) {
                    let data = lines[li].trim();
                    if (!data) continue;
                    try {
                        let req = JSON.parse(data);
                        let n = masterWindow._liveNotifs[req.id];
                        if (n) {
                            // Each call guarded — the app may have destroyed the
                            // notification between our lookup and the invoke.
                            if (req.type === "reply" && req.text) {
                                try { n.sendInlineReply(req.text); } catch(e) { console.warn("notifAction reply:", e); }
                                try { n.dismiss(); } catch(e) {}
                            } else if (req.type === "action" && req.key) {
                                try {
                                    for (let i = 0; i < n.actions.length; i++)
                                        if (n.actions[i].identifier === req.key) { n.actions[i].invoke(); break; }
                                } catch(e) { console.warn("notifAction invoke:", e); }
                            } else if (req.type === "dismiss") {
                                try { n.dismiss(); } catch(e) {}
                            }
                        } else {
                            console.warn("notifAction: notification", req.id, "no longer live");
                        }
                    } catch(e) { console.warn("notifAction parse:", e) }
                }
                notifActionWatcher.running = false;
                notifActionWatcher.running = true;
            }
        }
    }

    property var notifModel: globalNotificationHistory
    
    // =========================================================

    onGlobalUiScaleChanged: {
        handleNativeScreenChange();
    }

    Process {
        id: settingsReader
        command: ["bash", "-c", "cat ~/.config/hypr/settings.json 2>/dev/null || echo '{}'"]
        running: true 
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    if (this.text && this.text.trim().length > 0 && this.text.trim() !== "{}") {
                        let parsed = JSON.parse(this.text);
                        if (parsed.uiScale !== undefined && masterWindow.globalUiScale !== parsed.uiScale) {
                            masterWindow.globalUiScale = parsed.uiScale;
                        }
                    }
                } catch (e) {
                    console.log("Error parsing settings.json in main.qml:", e);
                }
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

    function getLayout(name, anchorX) {
        return Registry.getLayout(name, 0, 0, Screen.width, Screen.height, masterWindow.globalUiScale, anchorX);
    }

    // Parse an IPC arg into a usable anchor x (or undefined when not numeric).
    function _anchorOf(arg) {
        if (arg === undefined || arg === null || arg === "") return undefined;
        let n = Number(arg);
        return isNaN(n) ? undefined : n;
    }

    Connections {
        target: Screen
        function onWidthChanged() { handleNativeScreenChange(); }
        function onHeightChanged() { handleNativeScreenChange(); }
    }

    function handleNativeScreenChange() {
        if (masterWindow.currentActive === "hidden") return;
        
        let t = getLayout(masterWindow.currentActive, _anchorOf(masterWindow.activeArg));
        if (t) {
            masterWindow.animX = t.rx;
            masterWindow.animY = t.ry;
            masterWindow.animW = t.w;
            masterWindow.animH = t.h;
            masterWindow.targetW = t.w;
            masterWindow.targetH = t.h;
        }
    }

    onIsVisibleChanged: {
        if (isVisible) masterWindow.requestActivate();
    }

    Item {
        x: masterWindow.animX
        y: masterWindow.animY
        width: masterWindow.animW
        height: masterWindow.animH
        clip: true 
        layer.enabled: true 

        // Smoother easing type: OutExpo makes animations feel snappy yet perfectly fluid
        Behavior on x { enabled: !masterWindow.disableMorph; NumberAnimation { duration: masterWindow.morphDuration; easing.type: Easing.OutExpo } }
        Behavior on y { enabled: !masterWindow.disableMorph; NumberAnimation { duration: masterWindow.morphDuration; easing.type: Easing.OutExpo } }
        Behavior on width { enabled: !masterWindow.disableMorph; NumberAnimation { duration: masterWindow.morphDuration; easing.type: Easing.OutExpo } }
        Behavior on height { enabled: !masterWindow.disableMorph; NumberAnimation { duration: masterWindow.morphDuration; easing.type: Easing.OutExpo } }

        opacity: masterWindow.isVisible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: masterWindow.morphDuration === 500 ? 300 : 200; easing.type: Easing.InOutSine } }

        MouseArea {
            anchors.fill: parent
        }

        Item {
            anchors.centerIn: parent
            width: masterWindow.targetW
            height: masterWindow.targetH

            StackView {
                id: widgetStack
                anchors.fill: parent
                focus: true
                
                Keys.onEscapePressed: {
                    switchWidget("hidden", "");
                    event.accepted = true;
                }

                onCurrentItemChanged: {
                    if (currentItem) currentItem.forceActiveFocus();
                }

                replaceEnter: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 400; easing.type: Easing.OutExpo }
                        NumberAnimation { property: "scale"; from: 0.98; to: 1.0; duration: 400; easing.type: Easing.OutBack }
                    }
                }
                replaceExit: Transition {
                    ParallelAnimation {
                        // Uses the dynamically set exitDuration
                        NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: masterWindow.exitDuration; easing.type: Easing.InExpo }
                        NumberAnimation { property: "scale"; from: 1.0; to: 1.02; duration: masterWindow.exitDuration; easing.type: Easing.InExpo }
                    }
                }
            }
        }
    }

    function switchWidget(newWidget, arg) {
        Quickshell.execDetached(["bash", "-c", "echo '" + newWidget + "' > /tmp/qs_active_widget"]);

        prepTimer.stop();
        delayedClear.stop();

        if (newWidget === "hidden") {
            if (currentActive !== "hidden") {
                masterWindow.morphDuration = 250; 
                masterWindow.exitDuration = 250;
                masterWindow.disableMorph = false;
                
                masterWindow.animW = 1;
                masterWindow.animH = 1;
                masterWindow.isVisible = false; 
                
                delayedClear.start();
            }
        } else {
            if (currentActive === "hidden") {
                if (newWidget === "powermenu" || newWidget === "hello") {
                    masterWindow.morphDuration = 1;
                    masterWindow.exitDuration = 280;
                    masterWindow.disableMorph = true;
                    masterWindow.animX = 0;
                    masterWindow.animY = 0;
                    masterWindow.animW = Screen.width;
                    masterWindow.animH = Screen.height;
                } else {
                    masterWindow.morphDuration = 400;
                    masterWindow.exitDuration = 300;
                    masterWindow.disableMorph = false;
                    masterWindow.animX = Math.floor(Screen.width / 2);
                    masterWindow.animY = 35;
                    masterWindow.animW = 1;
                    masterWindow.animH = 1;
                }

                prepTimer.newWidget = newWidget;
                prepTimer.newArg = arg;
                prepTimer.start();
                
            } else {
                // Morphing directly between widgets (including wallpaper)
                masterWindow.morphDuration = 500;
                masterWindow.disableMorph = false;
                
                // If transitioning to wallpaper, make the previous widget disappear significantly faster
                masterWindow.exitDuration = (newWidget === "wallpaper") ? 100 : 300;
                
                executeSwitch(newWidget, arg, false);
            }
        }
    }

    Timer {
        id: prepTimer
        interval: 50
        property string newWidget: ""
        property string newArg: ""
        onTriggered: executeSwitch(newWidget, newArg, false)
    }

    function executeSwitch(newWidget, arg, immediate) {
        masterWindow.currentActive = newWidget;
        masterWindow.activeArg = arg;
        
        let t = getLayout(newWidget, _anchorOf(arg));
        masterWindow.animX = t.rx;
        masterWindow.animY = t.ry;
        masterWindow.animW = t.w;
        masterWindow.animH = t.h;
        masterWindow.targetW = t.w;
        masterWindow.targetH = t.h;
        
        let props = (newWidget === "wallpaper" || newWidget === "plugininstall")
                    ? { "widgetArg": arg } : {};
        if (newWidget === "battery") props["notifModel"] = masterWindow.notifModel;

        if (immediate) {
            widgetStack.replace(t.comp, props, StackView.Immediate);
        } else {
            widgetStack.replace(t.comp, props);
        }
        
        masterWindow.isVisible = true;
    }

    // =========================================================
    // --- IPC: EVENT-DRIVEN WATCHER
    // =========================================================
    Process {
        id: ipcWatcher
        command: ["bash", "-c",
            "inotifywait -qq -e close_write,moved_to --include 'qs_widget_state$' /tmp/ 2>/dev/null; " +
            "if [ -f /tmp/qs_widget_state ]; then cat /tmp/qs_widget_state && rm -f /tmp/qs_widget_state; fi"
        ]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let rawCmd = this.text.trim();

                if (rawCmd !== "") {
                    let parts = rawCmd.split(":");
                    let cmd   = parts[0];
                    // join — args may contain ':' (e.g. plugininstall file paths)
                    let arg   = parts.length > 1 ? parts.slice(1).join(":") : "";

                    if (cmd === "close") {
                        switchWidget("hidden", "");
                    } else if (getLayout(cmd)) {
                        delayedClear.stop();
                        if (cmd === masterWindow.currentActive) {
                            switchWidget("hidden", "");
                        } else {
                            switchWidget(cmd, arg);
                        }
                    }
                }

                ipcWatcher.running = false;
                ipcWatcher.running = true;
            }
        }
      }

    Timer {
        id: delayedClear
        interval: masterWindow.morphDuration 
        onTriggered: {
            masterWindow.currentActive = "hidden";
            widgetStack.clear();
            masterWindow.disableMorph = false;
        }
    }
}
