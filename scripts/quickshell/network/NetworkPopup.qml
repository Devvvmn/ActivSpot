import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Window
import QtCore
import Quickshell
import Quickshell.Io
import "../"
import "../themes"

Item {
    id: window
    
    // --- Responsive Scaling Logic ---
    Scaler {
        id: scaler
        currentWidth: Screen.width
    }
    
    function s(val) { 
        return scaler.s(val); 
    }
    
    focus: true

    Shortcut {
        sequence: "Tab"
        onActivated: {
            if (window.pendingWifiId !== "") {
                window.pendingWifiId = ""; window.pendingWifiSsid = "";
                return;
            }
            window.playSfx("switch.wav");
            window.activeMode = window.activeMode === "wifi" ? "bt"
                              : (window.activeMode === "bt" ? "eth" : "wifi");
        }
    }

    // -------------------------------------------------------------------------
    // INSTANT CACHING ENGINE & SHARED STATE
    // -------------------------------------------------------------------------
    Settings {
        id: cache
        category: "QS_NetworkWidget"
        property string lastWifiSsid: ""
        property string lastWifiJson: ""
        property string lastBtJson: ""
        property string lastEthJson: ""
    }

    readonly property string cacheDir: Quickshell.env("XDG_RUNTIME_DIR") ? (Quickshell.env("XDG_RUNTIME_DIR") + "/qs_network") : (Quickshell.env("HOME") + "/.cache/qs_network")
    readonly property string modeFilePath: cacheDir + "/mode"

    property bool ignoreNextModeFileUpdate: false
    Process {
        id: modeReader
        command: ["bash", "-c", "cat '" + window.modeFilePath + "' 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                let mode = this.text.trim();
                if ((mode === "wifi" || mode === "bt" || mode === "eth") && window.activeMode !== mode) {
                    window.ignoreNextModeFileUpdate = true;
                    window.activeMode = mode;
                }
            }
        }
    }

    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: modeReader.running = true
    }

    Component.onCompleted: {
        Quickshell.execDetached(["bash", "-c", "mkdir -p '" + window.cacheDir + "'; if [ ! -f '" + window.modeFilePath + "' ]; then echo '" + activeMode + "' > '" + window.modeFilePath + "'; fi"]);

        if (cache.lastWifiJson !== "") processWifiJson(cache.lastWifiJson);
        if (cache.lastBtJson !== "") processBtJson(cache.lastBtJson);
        if (cache.lastEthJson !== "") processEthJson(cache.lastEthJson);
        introState = 1.0;
        
        if (window.activeMode === "wifi") savedNetworksFetcher.running = true;
    }

    function playSfx(filename) {
        try {
            let rawUrl = Qt.resolvedUrl("sounds/" + filename).toString();
            let cleanPath = rawUrl;
            if (cleanPath.indexOf("file://") === 0) cleanPath = cleanPath.substring(7); 
            let cmd = "pw-play '" + cleanPath + "' 2>/dev/null || paplay '" + cleanPath + "' 2>/dev/null";
            Quickshell.execDetached(["sh", "-c", cmd]);
        } catch(e) {}
    }

    // Bind every color to the global Theme singleton so the popup follows
    // theme switching (mocha / apple / nord / carbon / …) live.
    readonly property color base: Theme.base
    readonly property color mantle: Theme.mantle
    readonly property color crust: Theme.crust
    readonly property color text: Theme.text
    readonly property color subtext0: Theme.subtext0
    readonly property color overlay0: Theme.overlay0
    readonly property color overlay1: Theme.overlay1
    readonly property color surface0: Theme.surface0
    readonly property color surface1: Theme.surface1
    readonly property color surface2: Theme.surface2

    readonly property color mauve: Theme.mauve
    readonly property color pink: Theme.pink
    readonly property color sapphire: Theme.sapphire
    readonly property color blue: Theme.blue
    readonly property color red: Theme.red
    readonly property color maroon: Theme.maroon
    readonly property color peach: Theme.peach
    readonly property color green: Theme.green
    readonly property color teal: Theme.teal
    readonly property bool isLight: Theme.isLight
    readonly property color hairline: Theme.isLight ? Qt.rgba(0,0,0,0.08) : Qt.rgba(1,1,1,0.06)
    // single theme-driven accent — same in every mode, follows the Theme singleton
    readonly property color accent: Theme.accent

    readonly property string scriptsDir: Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/network"
    
    readonly property color wifiAccent: Qt.lighter(window.sapphire, 1.15)
    readonly property color btAccent: window.mauve
    readonly property color ethAccent: Qt.lighter(window.green, 1.05)

    property string activeMode: "bt"
    readonly property color activeColor: window.accent
    readonly property color activeGradientSecondary: Qt.darker(window.activeColor, 1.25)

    // Mode-specific glyphs used by the central core (offline / idle / disconnect-on-hover).
    readonly property string offlineGlyph:   activeMode === "wifi" ? "󰤮" : (activeMode === "eth" ? "󰌙" : "󰂲")
    readonly property string idleGlyph:      activeMode === "wifi" ? "󰤨" : (activeMode === "eth" ? "󰈀" : "󰂯")
    readonly property string disconnectGlyph: activeMode === "wifi" ? "󰖪" : (activeMode === "eth" ? "󰌙" : "󰂲")

    // Interaction & Device States
    property var busyTasks: ({})
    property var disconnectingDevices: ({})
    property string connectingId: ""
    property string failedId: ""
    
    Timer { 
        id: busyTimeout; interval: 15000; 
        onTriggered: { window.busyTasks = ({}); window.disconnectingDevices = ({}); window.connectingId = ""; } 
    }
    Timer { id: failClearTimer; interval: 4000; onTriggered: window.failedId = "" }

    Timer { id: ethPendingReset; interval: 8000; onTriggered: { window.ethPowerPending = false; window.expectedEthPower = ""; } }
    Timer { id: wifiPendingReset; interval: 8000; onTriggered: { window.wifiPowerPending = false; window.expectedWifiPower = ""; } }
    Timer { id: btPendingReset; interval: 8000; onTriggered: { window.btPowerPending = false; window.expectedBtPower = ""; } }

    property bool showInfoView: false

    property string pendingWifiSsid: ""
    property string pendingWifiId: ""
    property var savedWifiNetworks: []

    Process {
        id: savedNetworksFetcher
        command: ["bash", "-c", "nmcli -t -f NAME connection show | grep -v 'lo'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let text = this.text.trim();
                window.savedWifiNetworks = text ? text.split('\n') : [];
            }
        }
    }

    Process {
        id: connectProcess
        property string targetId: ""
        property string targetSsid: ""

        onExited: {
            let code = exitCode;
            let bt = window.busyTasks;
            delete bt[targetId];
            window.busyTasks = Object.assign({}, bt);
            
            if (code !== 0) {
                window.failedId = targetId;
                failClearTimer.restart();
                window.playSfx("error.wav"); 
                
                if (window.activeMode === "wifi" && targetSsid !== "") {
                    Quickshell.execDetached(["bash", "-c", "nmcli connection delete '" + targetSsid + "' 2>/dev/null"]);
                    
                    let newSaved = [];
                    for(let i = 0; i < window.savedWifiNetworks.length; i++) {
                        if(window.savedWifiNetworks[i] !== targetSsid) {
                            newSaved.push(window.savedWifiNetworks[i]);
                        }
                    }
                    window.savedWifiNetworks = newSaved;
                }
            }
            
            window.connectingId = "";
            if (window.activeMode === "wifi") wifiPoller.running = true;
            else if (window.activeMode === "eth") ethPoller.running = true;
            else btPoller.running = true;
        }
    }

    function connectDevice(mode, id, macOrSsid, password) {
        window.connectingId = id;
        window.failedId = "";
        let bt = window.busyTasks;
        bt[id] = true;
        window.busyTasks = Object.assign({}, bt);
        busyTimeout.restart();

        connectProcess.targetId = id;
        connectProcess.targetSsid = (mode === "wifi") ? macOrSsid : ""; 
        
        if (mode === "wifi") {
            if (password !== "") {
                connectProcess.command = ["bash", "-c", "nmcli device wifi connect '" + macOrSsid + "' password '" + password + "'"];
            } else {
                connectProcess.command = ["bash", "-c", "nmcli device wifi connect '" + macOrSsid + "'"];
            }
        } else {
            connectProcess.command = ["bash", "-c", window.scriptsDir + "/bluetooth_panel_logic.sh --connect '" + macOrSsid + "'"];
        }
        connectProcess.running = true;
    }

    property var currentCores: [null, null, null, null, null]
    property var coreVisualIndices: [0, 0, 0, 0, 0]
    property int activeCoreCount: 0
    property real smoothedActiveCoreCount: activeCoreCount
    Behavior on smoothedActiveCoreCount { NumberAnimation { duration: 1000; easing.type: Easing.InOutExpo } }

    function syncCores() {
        let list = window.currentObjList;
        if (!currentPower) list = [];
        else {
            if (!Array.isArray(list)) list = [list];
        }

        let newCores = [window.currentCores[0], window.currentCores[1], window.currentCores[2], window.currentCores[3], window.currentCores[4]];
        let found = [false, false, false, false, false];

        for (let i = 0; i < list.length && i < 5; i++) {
            let dev = list[i];
            let id = window.activeMode === "wifi" ? dev.ssid : dev.mac;
            for (let c = 0; c < 5; c++) {
                if (newCores[c] && (window.activeMode === "wifi" ? newCores[c].ssid : newCores[c].mac) === id) { 
                    found[c] = true; newCores[c] = dev; break; 
                }
            }
        }

        for (let c = 0; c < 5; c++) { if (!found[c]) newCores[c] = null; }

        for (let i = 0; i < list.length && i < 5; i++) {
            let dev = list[i];
            let id = window.activeMode === "wifi" ? dev.ssid : dev.mac;
            let isFound = false;
            for (let c = 0; c < 5; c++) {
                if (newCores[c] && (window.activeMode === "wifi" ? newCores[c].ssid : newCores[c].mac) === id) { isFound = true; break; }
            }
            if (!isFound) {
                for (let c = 0; c < 5; c++) {
                    if (!newCores[c]) { newCores[c] = dev; break; }
                }
            }
        }

        window.currentCores = [...newCores];

        let activeCount = 0;
        let newVis = [0, 0, 0, 0, 0];
        for (let c = 0; c < 5; c++) {
            if (newCores[c]) {
                newVis[c] = activeCount;
                activeCount++;
            }
        }
        window.coreVisualIndices = newVis;
        window.activeCoreCount = activeCount;
    }

    onCurrentConnChanged: {
        showInfoView = currentConn;
        if (currentConn) updateInfoNodes();
    }

    onActiveModeChanged: {
        if (!window.ignoreNextModeFileUpdate) {
            Quickshell.execDetached(["bash", "-c", "echo '" + window.activeMode + "' > '" + window.modeFilePath + "'"]);
        }
        window.ignoreNextModeFileUpdate = false;
        
        window.pendingWifiId = ""; window.pendingWifiSsid = "";
        if (window.activeMode === "wifi") savedNetworksFetcher.running = true;

        infoListModel.clear();
        window.busyTasks = ({});
        window.disconnectingDevices = ({});
        window.currentCores = [null, null, null, null, null];
        window.coreVisualIndices = [0, 0, 0, 0, 0];
        window.activeCoreCount = 0;
        syncCores();
        window.showInfoView = window.currentConn;
        if (window.showInfoView) window.updateInfoNodes();
    }

    ListModel { id: wifiListModel }
    ListModel { id: btListModel }
    ListModel { id: ethListModel }
    ListModel { id: infoListModel }

    function syncModel(listModel, dataArray) {
        for (let i = listModel.count - 1; i >= 0; i--) {
            let id = listModel.get(i).id;
            let found = false;
            for (let j = 0; j < dataArray.length; j++) {
                if (id === dataArray[j].id) { found = true; break; }
            }
            if (!found) { listModel.remove(i); }
        }
        
        for (let i = 0; i < dataArray.length && i < 30; i++) {
            let d = dataArray[i];
            let foundIdx = -1;
            for (let j = i; j < listModel.count; j++) {
                if (listModel.get(j).id === d.id) { foundIdx = j; break; }
            }
            
            let obj = {
                id: d.id || "", ssid: d.ssid || "", mac: d.mac || "",
                name: d.name || d.ssid || "", icon: d.icon || "", security: d.security || "", action: d.action || "",
                isInfoNode: d.isInfoNode || false, isActionable: d.isActionable !== undefined ? d.isActionable : false, 
                cmdStr: d.cmdStr || "", parentIndex: d.parentIndex !== undefined ? d.parentIndex : -1
            };

            if (foundIdx === -1) {
                listModel.insert(i, obj);
            } else {
                if (foundIdx !== i) { listModel.move(foundIdx, i, 1); }
                for (let key in obj) { 
                    if (listModel.get(i)[key] !== obj[key]) {
                        listModel.setProperty(i, key, obj[key]); 
                    }
                }
            }
        }
    }

    property int hoveredCardCount: 0
    readonly property bool isListLocked: hoveredCardCount > 0
    property var nextWifiList: null
    property var nextBtList: null
    property var nextInfoList: null

    onIsListLockedChanged: {
        if (!isListLocked) {
            if (nextWifiList !== null) { window.syncModel(wifiListModel, nextWifiList); window.wifiList = nextWifiList; nextWifiList = null; }
            if (nextBtList !== null) { window.syncModel(btListModel, nextBtList); window.btList = nextBtList; nextBtList = null; }
            if (nextInfoList !== null) { window.syncModel(infoListModel, nextInfoList); nextInfoList = null; }
        }
    }

    property bool wifiPowerPending: false
    property string expectedWifiPower: ""
    property string wifiPower: "off"
    property var wifiConnected: null
    property var wifiList: []
    property string strongestWifiSsid: ""
    readonly property bool isWifiConn: !!window.wifiConnected && window.wifiConnected.ssid !== undefined

    readonly property string targetWifiSsid: {
        let found = false;
        if (cache.lastWifiSsid !== "") {
            for (let i = 0; i < wifiList.length; i++) {
                if (wifiList[i].id === cache.lastWifiSsid) { found = true; break; }
            }
        }
        return found ? cache.lastWifiSsid : strongestWifiSsid;
    }

    onWifiConnectedChanged: {
        if (window.wifiConnected && window.wifiConnected.ssid) { cache.lastWifiSsid = window.wifiConnected.ssid; }
        syncCores();
        if (window.currentConn && window.activeMode === "wifi") updateInfoNodes();
    }

    property bool btPowerPending: false
    property string expectedBtPower: ""
    property string btPower: "off"
    property var btConnected: []
    property var btList: []
    readonly property bool isBtConn: window.btConnected.length > 0

    onBtConnectedChanged: {
        syncCores();
        if (window.currentConn && window.activeMode === "bt") updateInfoNodes()
    }

    // ── Ethernet (wired) state ────────────────────────────────────────────
    // "power" here means the wired device is up/connected (toggling it runs
    // nmcli device connect/disconnect). There is no radio to flip.
    property bool ethPowerPending: false
    property string expectedEthPower: ""
    property string ethPower: "off"
    property string ethDevice: ""        // device name, present even when offline
    property var ethConnected: null      // {id,name,icon,ip,speed,mac} or null
    property var ethList: []
    readonly property bool isEthConn: !!window.ethConnected && window.ethConnected.id !== undefined

    onEthConnectedChanged: {
        syncCores();
        if (window.currentConn && window.activeMode === "eth") updateInfoNodes();
    }

    readonly property bool currentPower: activeMode === "wifi" ? window.wifiPower === "on"
                                       : (activeMode === "eth" ? window.ethPower === "on" : window.btPower === "on")
    onCurrentPowerChanged: { syncCores(); }

    readonly property bool currentPowerPending: activeMode === "wifi" ? window.wifiPowerPending
                                              : (activeMode === "eth" ? window.ethPowerPending : window.btPowerPending)
    readonly property bool currentConn: activeMode === "wifi" ? window.isWifiConn
                                      : (activeMode === "eth" ? window.isEthConn : window.isBtConn)

    readonly property var currentObjList: activeMode === "wifi" ? (window.isWifiConn ? [window.wifiConnected] : [])
                                        : (activeMode === "eth" ? (window.isEthConn ? [window.ethConnected] : []) : window.btConnected)
    
    readonly property bool isLogicMultiState: window.activeMode === "bt" && window.activeCoreCount > 1
    
    property real multiTransitionState: (isLogicMultiState && window.currentPower) ? 1.0 : 0.0
    Behavior on multiTransitionState { NumberAnimation { duration: 1200; easing.type: Easing.InOutExpo } }

    function updateInfoNodes() {
        let nodes = [];
        
        let isActConn = window.currentConn;
        let cList = window.currentObjList;
        if (!Array.isArray(cList)) cList = cList ? [cList] : [];

        if (isActConn && cList.length > 0) {
            for (let i = 0; i < cList.length; i++) {
                let obj = cList[i];
                let cIndex = 0;
                
                if (window.activeMode === "bt") {
                    for (let c = 0; c < 5; c++) {
                        if (window.currentCores[c] && window.currentCores[c].mac === obj.mac) { cIndex = c; break; }
                    }
                }

                if (window.activeMode === "wifi") {
                    let sigValue = obj.signal !== undefined ? obj.signal + "%" : "Calculating...";
                    nodes.push({ id: "sig_" + i, name: sigValue, icon: obj.icon || "󰤨", action: "Signal Strength", isInfoNode: true, isActionable: false, parentIndex: cIndex });
                    nodes.push({ id: "sec_" + i, name: obj.security || "Open", icon: "󰦝", action: "Security", isInfoNode: true, isActionable: false, parentIndex: cIndex });
                    if (obj.ip) nodes.push({ id: "ip_" + i, name: obj.ip, icon: "󰩟", action: "IP Address", isInfoNode: true, isActionable: false, parentIndex: cIndex });
                    if (obj.freq) nodes.push({ id: "freq_" + i, name: obj.freq, icon: "󰖧", action: "Band", isInfoNode: true, isActionable: false, parentIndex: cIndex });
                } else if (window.activeMode === "eth") {
                    if (obj.ip)    nodes.push({ id: "eip_" + i,  name: obj.ip,    icon: "󰩟", action: "IP Address", isInfoNode: true, isActionable: false, parentIndex: cIndex });
                    if (obj.speed) nodes.push({ id: "espd_" + i, name: obj.speed, icon: "󰓅", action: "Link Speed", isInfoNode: true, isActionable: false, parentIndex: cIndex });
                    nodes.push({ id: "edev_" + i, name: obj.id || window.ethDevice || "eth", icon: "󰈀", action: "Interface", isInfoNode: true, isActionable: false, parentIndex: cIndex });
                    if (obj.mac) nodes.push({ id: "emac_" + i, name: obj.mac, icon: "󰒋", action: "MAC Address", isInfoNode: true, isActionable: false, parentIndex: cIndex });
                } else {
                    nodes.push({ id: "bat_" + obj.mac, name: (obj.battery || "0") + "%", icon: "󰥉", action: "Battery", isInfoNode: true, isActionable: false, parentIndex: cIndex });
                    if (obj.profile) {
                        nodes.push({ id: "prof_" + obj.mac, name: obj.profile, icon: (obj.profile === "Hi-Fi (A2DP)" ? "󰓃" : "󰋎"), action: "Audio Profile", isInfoNode: true, isActionable: false, parentIndex: cIndex });
                    }
                    nodes.push({ id: "mac_" + obj.mac, name: obj.mac || "Unknown", icon: "󰒋", action: "MAC Address", isInfoNode: true, isActionable: false, parentIndex: cIndex });
                }
            }
            nodes.push({ id: "action_scan", name: window.activeMode === "eth" ? "Back" : "Scan Devices", icon: window.activeMode === "eth" ? "󰌍" : "󰍉", action: "Switch View", isInfoNode: true, isActionable: true, cmdStr: "TOGGLE_VIEW", parentIndex: -1 });
        }
        
        if (window.isListLocked) window.nextInfoList = nodes;
        else { window.syncModel(infoListModel, nodes); window.nextInfoList = null; }
    }

    function processWifiJson(textData) {
        if (textData === "") return;
        try {
            let data = JSON.parse(textData);
            let fetchedPower = data.power || "off";
            
            if (window.wifiPowerPending) {
                window.wifiPower = window.expectedWifiPower; 
                if (fetchedPower === window.expectedWifiPower) {
                    window.wifiPowerPending = false; 
                    wifiPendingReset.stop();
                }
            } else {
                window.wifiPower = fetchedPower;
                window.expectedWifiPower = "";
            }

            let wasWifiConn = !!window.wifiConnected && window.wifiConnected.ssid !== undefined;
            let newConnected = data.connected;
            let newNetworks = data.networks ? data.networks : [];

            if (newConnected && newConnected.ssid) {
                let match = newNetworks.find(n => n.id === newConnected.ssid || n.ssid === newConnected.ssid);
                if (match) {
                    newConnected.icon = match.icon || newConnected.icon;
                    newConnected.name = match.name || newConnected.name;
                    newConnected.security = match.security || newConnected.security;
                    newConnected.signal = match.signal || newConnected.signal;
                    newConnected.freq = match.freq || newConnected.freq;
                    newConnected.ip = match.ip || newConnected.ip;
                }
            }

            let isNowWifiConn = !!newConnected && newConnected.ssid !== undefined;

            if (JSON.stringify(window.wifiConnected) !== JSON.stringify(newConnected)) {
                window.wifiConnected = newConnected;
            }
            
            if (newNetworks.length > 0) {
                let maxSig = -1; let bestSsid = newNetworks[0].id;
                for (let i = 0; i < newNetworks.length; i++) {
                    let sig = parseInt(newNetworks[i].signal || 0);
                    if (sig > maxSig) { maxSig = sig; bestSsid = newNetworks[i].id; }
                }
                window.strongestWifiSsid = bestSsid;
            } else { window.strongestWifiSsid = ""; }

            newNetworks.sort((a, b) => a.id.localeCompare(b.id));

            if (isNowWifiConn && window.activeMode === "wifi") {
                newNetworks.push({ id: "action_settings", ssid: "Current Device", mac: "", name: "Current Device", icon: "󰒓", security: "", action: "View Info", isInfoNode: false, isActionable: true, cmdStr: "TOGGLE_VIEW", parentIndex: -1 });
            }

            if (JSON.stringify(window.wifiList) !== JSON.stringify(newNetworks)) {
                if (window.isListLocked) window.nextWifiList = newNetworks;
                else { window.syncModel(wifiListModel, newNetworks); window.wifiList = newNetworks; window.nextWifiList = null; }
            }

            if (window.activeMode === "wifi") {
                if (!wasWifiConn && isNowWifiConn) {
                    window.showInfoView = true;
                }
                
                let dd = window.disconnectingDevices;
                let ddChanged = false;
                for (let ssid in dd) {
                    if (!isNowWifiConn || (newConnected && newConnected.ssid !== ssid)) {
                        delete dd[ssid];
                        ddChanged = true;
                    }
                }
                if (ddChanged) {
                    window.disconnectingDevices = Object.assign({}, dd);
                    if (Object.keys(window.disconnectingDevices).length === 0 && Object.keys(window.busyTasks).length === 0) busyTimeout.stop();
                }
                
                let newlyConnected = false;
                let bt = window.busyTasks;
                if (isNowWifiConn && newConnected && bt[newConnected.ssid]) {
                    newlyConnected = true;
                    delete bt[newConnected.ssid];
                    window.connectingId = "";
                }
                if (newlyConnected) {
                    window.playSfx("connect.wav");
                    window.busyTasks = Object.assign({}, bt);
                    if (Object.keys(window.busyTasks).length === 0 && Object.keys(window.disconnectingDevices).length === 0) busyTimeout.stop();
                }

                if (isNowWifiConn || window.isBtConn) window.updateInfoNodes();
            }
        } catch(e) {}
    }

    function processBtJson(textData) {
        if (textData === "") return;
        try {
            let data = JSON.parse(textData);
            let fetchedPower = data.power || "off";
            
            if (window.btPowerPending) {
                window.btPower = window.expectedBtPower; 
                if (fetchedPower === window.expectedBtPower) {
                    window.btPowerPending = false; 
                    btPendingReset.stop();
                }
            } else {
                window.btPower = fetchedPower;
                window.expectedBtPower = "";
            }

            let oldBtLen = window.btConnected.length;
            let newBtConnected = data.connected || [];
            if (!Array.isArray(newBtConnected)) newBtConnected = [newBtConnected];
            let isNowBtConn = newBtConnected.length > 0;

            if (JSON.stringify(window.btConnected) !== JSON.stringify(newBtConnected)) {
                window.btConnected = newBtConnected;
            }

            let newDevices = data.devices ? data.devices : [];
            newDevices.sort((a, b) => a.id.localeCompare(b.id));

            if (isNowBtConn && window.activeMode === "bt") {
                newDevices.push({ id: "action_settings", ssid: "", mac: "action_settings", name: "Current Device", icon: "󰒓", action: "View Info", isInfoNode: false, isActionable: true, cmdStr: "TOGGLE_VIEW", parentIndex: -1 });
            }

            if (JSON.stringify(window.btList) !== JSON.stringify(newDevices)) {
                if (window.isListLocked) window.nextBtList = newDevices;
                else { window.syncModel(btListModel, newDevices); window.btList = newDevices; window.nextBtList = null; }
            }

            if (window.activeMode === "bt") {
                if (newBtConnected.length > oldBtLen) {
                    window.showInfoView = true;
                }

                let dd = window.disconnectingDevices;
                let ddChanged = false;
                for (let mac in dd) {
                    let stillConnected = false;
                    for (let i = 0; i < newBtConnected.length; i++) {
                        if (newBtConnected[i].mac === mac) { stillConnected = true; break; }
                    }
                    if (!stillConnected) {
                        delete dd[mac];
                        ddChanged = true;
                    }
                }
                if (ddChanged) {
                    window.disconnectingDevices = Object.assign({}, dd);
                    if (Object.keys(window.disconnectingDevices).length === 0 && Object.keys(window.busyTasks).length === 0) busyTimeout.stop();
                }
                
                let newlyConnected = false;
                let bt = window.busyTasks;
                for (let i = 0; i < newBtConnected.length; i++) {
                    let mac = newBtConnected[i].mac;
                    if (bt[mac]) {
                        newlyConnected = true;
                        delete bt[mac];
                        window.connectingId = "";
                    }
                }
                if (newlyConnected) {
                    window.playSfx("connect.wav");
                    window.busyTasks = Object.assign({}, bt);
                    if (Object.keys(window.busyTasks).length === 0 && Object.keys(window.disconnectingDevices).length === 0) busyTimeout.stop();
                }

                if (isNowBtConn || window.isWifiConn) window.updateInfoNodes();
            }
        } catch(e) {}
    }

    function processEthJson(textData) {
        if (textData === "") return;
        try {
            let data = JSON.parse(textData);
            let fetchedPower = data.power || "off";

            if (window.ethPowerPending) {
                window.ethPower = window.expectedEthPower;
                if (fetchedPower === window.expectedEthPower) {
                    window.ethPowerPending = false;
                    ethPendingReset.stop();
                }
            } else {
                window.ethPower = fetchedPower;
                window.expectedEthPower = "";
            }

            window.ethDevice = data.device || "";

            let wasEthConn = window.isEthConn;
            let newConnected = data.connected || null;
            let isNowEthConn = !!newConnected && newConnected.id !== undefined;

            if (JSON.stringify(window.ethConnected) !== JSON.stringify(newConnected)) {
                window.ethConnected = newConnected;
            }

            // Single "Current Device" toggle card when connected (mirrors wifi/bt).
            let newList = [];
            if (isNowEthConn && window.activeMode === "eth") {
                newList.push({ id: "action_settings", ssid: "", mac: "action_settings", name: "Current Device", icon: "󰒓", action: "View Info", isInfoNode: false, isActionable: true, cmdStr: "TOGGLE_VIEW", parentIndex: -1 });
            }
            if (JSON.stringify(window.ethList) !== JSON.stringify(newList)) {
                window.syncModel(ethListModel, newList);
                window.ethList = newList;
            }

            if (window.activeMode === "eth") {
                if (!wasEthConn && isNowEthConn) {
                    window.showInfoView = true;
                    window.playSfx("connect.wav");
                }
                // Clear any lingering disconnect spinner once the link is gone.
                if (!isNowEthConn && Object.keys(window.disconnectingDevices).length > 0) {
                    window.disconnectingDevices = ({});
                    if (Object.keys(window.busyTasks).length === 0) busyTimeout.stop();
                }
                if (isNowEthConn) window.updateInfoNodes();
            }
        } catch(e) {}
    }

    Process {
        id: ethPoller
        command: ["bash", window.scriptsDir + "/eth_panel_logic.sh"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                cache.lastEthJson = this.text.trim();
                processEthJson(cache.lastEthJson);
            }
        }
    }

    Process {
        id: wifiPoller
        command: ["bash", window.scriptsDir + "/wifi_panel_logic.sh"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                cache.lastWifiJson = this.text.trim();
                processWifiJson(cache.lastWifiJson);
            }
        }
    }

    Process {
        id: btPoller
        command: ["bash", window.scriptsDir + "/bluetooth_panel_logic.sh", "--status"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                cache.lastBtJson = this.text.trim();
                processBtJson(cache.lastBtJson);
            }
        }
    }
    
    Timer {
        interval: (Object.keys(window.busyTasks).length > 0 || Object.keys(window.disconnectingDevices).length > 0) ? 1000 : 3000
        running: true; repeat: true
        onTriggered: {
            if (!wifiPoller.running) wifiPoller.running = true;
            if (!btPoller.running) btPoller.running = true;
            if (!ethPoller.running) ethPoller.running = true;
        }
    }

    property real globalOrbitAngle: 0
    NumberAnimation on globalOrbitAngle {
        from: 0; to: Math.PI * 2; duration: 200000; loops: Animation.Infinite; running: true
    }

    property real introState: 0.0
    Behavior on introState { NumberAnimation { duration: 1500; easing.type: Easing.OutCubic } }

    component LoadingDots : Row {
        spacing: window.s(5)
        property color dotCol: window.text
        Repeater {
            model: 3
            Rectangle {
                width: window.s(3); height: window.s(3); radius: window.s(1); color: dotCol
                SequentialAnimation on y {
                    loops: Animation.Infinite
                    PauseAnimation { duration: index * 100 }
                    NumberAnimation { from: 0; to: window.s(-6); duration: 250; easing.type: Easing.OutSine }
                    NumberAnimation { from: window.s(-6); to: 0; duration: 250; easing.type: Easing.InSine }
                    PauseAnimation { duration: (2 - index) * 100 }
                }
            }
        }
    }

    // =====================================================================
    //  macOS Control-Center style presentation
    //  (all data/logic lives above; this is pure presentation + animation)
    // =====================================================================
    Item {
        id: root
        anchors.fill: parent

        // ─── Mode metadata ────────────────────────────────────────────────
        readonly property var _modes: {
            let m = ["wifi", "bt"];
            if (window.ethDevice !== "") m.push("eth");
            return m;
        }
        function _modeName(m) { return m === "wifi" ? "Wi-Fi" : (m === "eth" ? "Ethernet" : "Bluetooth"); }
        function _modeIcon(m) { return m === "wifi" ? "󰤨" : (m === "eth" ? "󰈀" : "󰂯"); }
        function _modeAccent(m) { return window.accent; }

        // Subtitle under the master row
        readonly property string _statusText: {
            if (window.currentPowerPending) return "…";
            if (!window.currentPower) return "Off";
            if (window.activeMode === "wifi") return window.isWifiConn && window.wifiConnected ? (window.wifiConnected.ssid || "On") : "On";
            if (window.activeMode === "eth")  return window.isEthConn ? "Connected" : "Not connected";
            return window.isBtConn ? (window.btConnected.length + (window.btConnected.length === 1 ? " device" : " devices")) : "On";
        }

        // ─── Reusable macOS pill toggle ───────────────────────────────────
        component MacSwitch : Item {
            id: sw
            property bool on: false
            property bool pending: false
            property color accent: window.activeColor
            signal toggled()
            implicitWidth: window.s(40); implicitHeight: window.s(24)

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: sw.on ? sw.accent : window.surface2
                Behavior on color { ColorAnimation { duration: 260 } }

                Rectangle {
                    id: knob
                    width: parent.height - window.s(4); height: width; radius: width / 2
                    y: window.s(2)
                    x: sw.on ? (parent.width - width - window.s(2)) : window.s(2)
                    color: "#ffffff"
                    Behavior on x { SpringAnimation { spring: 3.0; damping: 0.32; mass: 0.7 } }

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true; shadowColor: "#55000000"; shadowBlur: 0.4; shadowVerticalOffset: 1
                    }

                    Text {
                        anchors.centerIn: parent; visible: sw.pending
                        font.family: "Iosevka Nerd Font"; font.pixelSize: window.s(12); color: sw.accent
                        text: "󰑮"
                        RotationAnimation on rotation { from: 0; to: 360; duration: 800; loops: Animation.Infinite; running: sw.pending }
                    }
                }
            }
            MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onClicked: sw.toggled()
            }
        }

        // ─── Master power toggle (wifi radio / bt / eth connect) ──────────
        function _togglePower() {
            if (window.pendingWifiId !== "") { window.pendingWifiId = ""; window.pendingWifiSsid = ""; }
            if (window.activeMode === "eth") {
                if (window.ethPowerPending || window.ethDevice === "") return;
                window.expectedEthPower = window.ethPower === "on" ? "off" : "on";
                window.ethPowerPending = true;
                window.playSfx(window.expectedEthPower === "on" ? "power_on.wav" : "power_off.wav");
                ethPendingReset.restart();
                window.ethPower = window.expectedEthPower;
                Quickshell.execDetached(["nmcli", "device", window.expectedEthPower === "on" ? "connect" : "disconnect", window.ethDevice]);
                ethPoller.running = true;
            } else if (window.activeMode === "wifi") {
                if (window.wifiPowerPending) return;
                window.expectedWifiPower = window.wifiPower === "on" ? "off" : "on";
                window.wifiPowerPending = true;
                window.playSfx(window.expectedWifiPower === "on" ? "power_on.wav" : "power_off.wav");
                wifiPendingReset.restart();
                window.wifiPower = window.expectedWifiPower;
                Quickshell.execDetached(["nmcli", "radio", "wifi", window.wifiPower]);
                wifiPoller.running = true;
            } else {
                if (window.btPowerPending) return;
                window.expectedBtPower = window.btPower === "on" ? "off" : "on";
                window.btPowerPending = true;
                window.playSfx(window.expectedBtPower === "on" ? "power_on.wav" : "power_off.wav");
                btPendingReset.restart();
                window.btPower = window.expectedBtPower;
                Quickshell.execDetached(["bash", window.scriptsDir + "/bluetooth_panel_logic.sh", "--toggle"]);
                btPoller.running = true;
            }
        }

        // ─── Disconnect a connected device ────────────────────────────────
        function _disconnect(dev) {
            if (!dev) return;
            let key = window.activeMode === "wifi" ? dev.ssid : dev.mac;
            let dd = window.disconnectingDevices; dd[key] = true;
            window.disconnectingDevices = Object.assign({}, dd);
            busyTimeout.restart();
            window.playSfx("disconnect.wav");
            let cmd = window.activeMode === "wifi"
                ? "nmcli device disconnect $(nmcli -t -f DEVICE,TYPE d | grep wifi | cut -d: -f1 | head -n1)"
                : (window.activeMode === "eth"
                    ? "nmcli device disconnect '" + (window.ethDevice || dev.id) + "'"
                    : "bash " + window.scriptsDir + "/bluetooth_panel_logic.sh --disconnect '" + dev.mac + "'");
            Quickshell.execDetached(["sh", "-c", cmd]);
            if (window.activeMode === "wifi") wifiPoller.running = true;
            else if (window.activeMode === "eth") ethPoller.running = true;
            else btPoller.running = true;
        }

        // ─── Connect / select a list item ─────────────────────────────────
        function _selectItem(itemId, ssid, mac, security) {
            let sec = security ? ("" + security).trim().toLowerCase() : "";
            let isSecure = sec !== "" && sec !== "open" && sec !== "--" && sec !== "none";
            let isSaved = window.savedWifiNetworks.indexOf(ssid) !== -1;
            if (window.activeMode === "wifi" && isSecure && !isSaved) {
                window.pendingWifiSsid = ssid;
                window.pendingWifiId = itemId;
            } else {
                window.connectDevice(window.activeMode, itemId, window.activeMode === "wifi" ? ssid : mac, "");
            }
        }

        function _isConnectedId(rid) {
            if (window.activeMode === "wifi") return window.wifiConnected && window.wifiConnected.ssid === rid;
            if (window.activeMode === "eth") return false;
            for (let i = 0; i < window.btConnected.length; i++) if (window.btConnected[i].mac === rid) return true;
            return false;
        }

        function _joinWifi(pw) {
            if (!pw || pw.length < 1) return;
            window.connectDevice("wifi", window.pendingWifiId, window.pendingWifiSsid, pw);
            window.pendingWifiId = ""; window.pendingWifiSsid = "";
        }

        // ─── Panel ────────────────────────────────────────────────────────
        Rectangle {
            id: panel
            anchors.fill: parent
            radius: window.s(18)
            color: window.base
            border.color: window.hairline
            border.width: 1
            clip: true

            // intro pop
            scale: window.introState >= 1.0 ? 1.0 : 0.985
            opacity: window.introState
            Behavior on scale { NumberAnimation { duration: 360; easing.type: Easing.OutCubic } }

            Column {
                anchors.fill: parent
                anchors.margins: window.s(16)
                spacing: window.s(12)

                // ── Header ────────────────────────────────────────────────
                Item {
                    width: parent.width; height: window.s(28)
                    Text {
                        anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                        text: "Network"
                        font.family: "Inter"; font.weight: Font.Bold; font.pixelSize: window.s(18)
                        color: window.text
                    }
                    // rescan / refresh
                    Rectangle {
                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                        width: window.s(28); height: window.s(28); radius: width / 2
                        color: refreshMa.containsMouse ? window.surface1 : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Text {
                            id: refreshIcon
                            anchors.centerIn: parent
                            text: "󰑐"; font.family: "Iosevka Nerd Font"; font.pixelSize: window.s(14)
                            color: window.subtext0
                        }
                        MouseArea {
                            id: refreshMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                window.playSfx("switch.wav");
                                refreshSpin.restart();
                                if (window.activeMode === "wifi") { Quickshell.execDetached(["nmcli", "device", "wifi", "rescan"]); wifiPoller.running = true; }
                                else if (window.activeMode === "eth") ethPoller.running = true;
                                else btPoller.running = true;
                            }
                        }
                        RotationAnimation { id: refreshSpin; target: refreshIcon; property: "rotation"; from: 0; to: 360; duration: 600; easing.type: Easing.OutCubic }
                    }
                }

                // ── Segmented control ─────────────────────────────────────
                Rectangle {
                    id: segTrack
                    width: parent.width; height: window.s(32)
                    radius: window.s(9)
                    color: window.surface0

                    readonly property real pad: window.s(3)
                    readonly property real segW: (width - pad * 2) / Math.max(1, root._modes.length)
                    readonly property int selIdx: Math.max(0, root._modes.indexOf(window.activeMode))

                    // sliding selection pill
                    Rectangle {
                        height: parent.height - segTrack.pad * 2
                        width: segTrack.segW
                        radius: window.s(7)
                        y: segTrack.pad
                        x: segTrack.pad + segTrack.selIdx * segTrack.segW
                        color: root._modeAccent(window.activeMode)
                        Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
                        Behavior on color { ColorAnimation { duration: 220 } }
                    }

                    Row {
                        anchors.fill: parent
                        anchors.margins: segTrack.pad
                        Repeater {
                            model: root._modes
                            Item {
                                width: segTrack.segW; height: parent.height
                                readonly property bool sel: modelData === window.activeMode
                                Row {
                                    anchors.centerIn: parent; spacing: window.s(5)
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: root._modeIcon(modelData)
                                        font.family: "Iosevka Nerd Font"; font.pixelSize: window.s(12)
                                        color: sel ? window.crust : window.subtext0
                                        Behavior on color { ColorAnimation { duration: 200 } }
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: root._modeName(modelData)
                                        font.family: "Inter"; font.weight: Font.DemiBold; font.pixelSize: window.s(12)
                                        color: sel ? window.crust : window.subtext0
                                        Behavior on color { ColorAnimation { duration: 200 } }
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (window.pendingWifiId !== "") { window.pendingWifiId = ""; window.pendingWifiSsid = ""; }
                                        if (window.activeMode !== modelData) window.playSfx("switch.wav");
                                        window.activeMode = modelData;
                                    }
                                }
                            }
                        }
                    }
                }

                // ── Master row: mode label + status + switch ───────────────
                Rectangle {
                    width: parent.width; height: window.s(50)
                    radius: window.s(12)
                    color: window.surface0

                    Row {
                        anchors.left: parent.left; anchors.leftMargin: window.s(12)
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: window.s(11)
                        Rectangle {
                            width: window.s(32); height: window.s(32); radius: window.s(9)
                            anchors.verticalCenter: parent.verticalCenter
                            color: window.currentPower ? root._modeAccent(window.activeMode) : window.surface2
                            Behavior on color { ColorAnimation { duration: 250 } }
                            Text {
                                anchors.centerIn: parent
                                text: root._modeIcon(window.activeMode)
                                font.family: "Iosevka Nerd Font"; font.pixelSize: window.s(16)
                                color: window.currentPower ? window.crust : window.subtext0
                                Behavior on color { ColorAnimation { duration: 250 } }
                            }
                        }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: window.s(1)
                            Text {
                                text: root._modeName(window.activeMode)
                                font.family: "Inter"; font.weight: Font.DemiBold; font.pixelSize: window.s(14)
                                color: window.text
                            }
                            Text {
                                text: root._statusText
                                font.family: "Inter"; font.pixelSize: window.s(11)
                                color: window.currentConn ? root._modeAccent(window.activeMode) : window.subtext0
                                width: window.s(200); elide: Text.ElideRight
                                Behavior on color { ColorAnimation { duration: 250 } }
                            }
                        }
                    }

                    MacSwitch {
                        anchors.right: parent.right; anchors.rightMargin: window.s(12)
                        anchors.verticalCenter: parent.verticalCenter
                        on: window.currentPower
                        pending: window.currentPowerPending
                        accent: root._modeAccent(window.activeMode)
                        onToggled: root._togglePower()
                    }
                }

                // ── Content area (cross-fades on mode/power change) ────────
                Item {
                    id: contentArea
                    width: parent.width
                    height: parent.height - y

                    // mode-change fade
                    opacity: 1.0
                    Connections {
                        target: window
                        function onActiveModeChanged() { modeFade.restart(); }
                    }
                    NumberAnimation { id: modeFade; target: contentArea; property: "opacity"; from: 0.0; to: 1.0; duration: 350; easing.type: Easing.OutCubic }

                    // ░ OFF / empty state ░
                    Column {
                        anchors.centerIn: parent
                        spacing: window.s(8)
                        opacity: window.currentPower ? 0.0 : 1.0
                        visible: opacity > 0.01
                        Behavior on opacity { NumberAnimation { duration: 300 } }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: window.offlineGlyph
                            font.family: "Iosevka Nerd Font"; font.pixelSize: window.s(40); color: window.surface2
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root._modeName(window.activeMode) + " is Off"
                            font.family: "Inter"; font.weight: Font.DemiBold; font.pixelSize: window.s(13); color: window.subtext0
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: window.activeMode === "eth" ? "No active wired link" : "Turn on to see available connections"
                            font.family: "Inter"; font.pixelSize: window.s(11); color: window.overlay1
                        }
                    }

                    // ░ Scrollable list ░
                    Flickable {
                        id: listFlick
                        anchors.fill: parent
                        contentWidth: width
                        contentHeight: listCol.height
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        opacity: window.currentPower ? 1.0 : 0.0
                        visible: opacity > 0.01
                        Behavior on opacity { NumberAnimation { duration: 300 } }

                        readonly property var availModel: window.activeMode === "wifi" ? wifiListModel
                                                          : (window.activeMode === "bt" ? btListModel : null)

                        Column {
                            id: listCol
                            width: listFlick.width
                            spacing: window.s(6)

                            // ── Connected device(s) card ──────────────────
                            Repeater {
                                model: window.currentPower ? window.currentObjList : []
                                delegate: Rectangle {
                                    id: connCard
                                    width: listCol.width
                                    height: window.s(50)
                                    radius: window.s(11)
                                    required property var modelData
                                    required property int index

                                    readonly property string ckey: window.activeMode === "wifi" ? (modelData.ssid || "") : (modelData.mac || "")
                                    readonly property bool busy: !!window.disconnectingDevices[ckey]

                                    color: connMa.containsMouse ? window.surface1 : window.surface0
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    // thin accent edge marks the active connection
                                    Rectangle {
                                        anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                                        width: window.s(3); height: parent.height * 0.5; radius: width
                                        color: root._modeAccent(window.activeMode)
                                    }

                                    // entry stagger
                                    property real _in: 0.0
                                    Component.onCompleted: connIn.start()
                                    NumberAnimation { id: connIn; target: connCard; property: "_in"; from: 0; to: 1; duration: 440; easing.type: Easing.OutExpo }
                                    opacity: _in
                                    transform: Translate { x: (1 - connCard._in) * window.s(14) }

                                    Row {
                                        anchors.left: parent.left; anchors.leftMargin: window.s(12)
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: window.s(11)
                                        Rectangle {
                                            width: window.s(30); height: window.s(30); radius: window.s(8)
                                            anchors.verticalCenter: parent.verticalCenter
                                            color: root._modeAccent(window.activeMode)
                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData.icon || window.idleGlyph
                                                font.family: "Iosevka Nerd Font"; font.pixelSize: window.s(15); color: window.crust
                                            }
                                        }
                                        Column {
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: window.s(1)
                                            Text {
                                                text: (window.activeMode === "wifi" ? modelData.ssid : (modelData.name || modelData.id)) || "Connected"
                                                font.family: "Inter"; font.weight: Font.DemiBold; font.pixelSize: window.s(14); color: window.text
                                                width: window.s(200); elide: Text.ElideRight
                                            }
                                            Text {
                                                text: {
                                                    if (window.activeMode === "eth") return (modelData.ip || "") + (modelData.speed ? "  ·  " + modelData.speed : "");
                                                    if (window.activeMode === "wifi") return modelData.ip ? "Connected · " + modelData.ip : "Connected";
                                                    return modelData.battery ? "Connected · " + modelData.battery + "%" : "Connected";
                                                }
                                                font.family: "Inter"; font.pixelSize: window.s(11); color: window.subtext0
                                                width: window.s(200); elide: Text.ElideRight
                                            }
                                        }
                                    }

                                    // trailing: checkmark, or disconnect ✕ on hover, or spinner
                                    Item {
                                        anchors.right: parent.right; anchors.rightMargin: window.s(12)
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: window.s(22); height: window.s(22)
                                        LoadingDots { anchors.centerIn: parent; visible: connCard.busy; dotCol: window.text }
                                        Text {
                                            anchors.centerIn: parent
                                            visible: !connCard.busy
                                            text: connMa.containsMouse ? "󰅖" : "󰄬"
                                            font.family: "Iosevka Nerd Font"; font.pixelSize: window.s(15)
                                            color: connMa.containsMouse ? window.red : root._modeAccent(window.activeMode)
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                        }
                                    }

                                    MouseArea {
                                        id: connMa
                                        anchors.fill: parent; hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onEntered: window.hoveredCardCount++
                                        onExited: window.hoveredCardCount--
                                        onClicked: if (!connCard.busy) root._disconnect(modelData)
                                    }
                                }
                            }

                            // ── eth info chips for the connected link ──────
                            Flow {
                                width: listCol.width
                                spacing: window.s(6)
                                visible: window.activeMode === "eth" && window.isEthConn
                                Repeater {
                                    model: {
                                        if (window.activeMode !== "eth" || !window.ethConnected) return [];
                                        let c = window.ethConnected; let a = [];
                                        if (c.id)    a.push({ k: "Interface", v: c.id,   i: "󰈀" });
                                        if (c.mac)   a.push({ k: "MAC",       v: c.mac,  i: "󰒋" });
                                        return a;
                                    }
                                    delegate: Rectangle {
                                        required property var modelData
                                        height: window.s(36); radius: window.s(9); color: window.surface0
                                        width: chipRow.width + window.s(20)
                                        Row {
                                            id: chipRow; anchors.centerIn: parent; spacing: window.s(7)
                                            Text { anchors.verticalCenter: parent.verticalCenter; text: modelData.i; font.family: "Iosevka Nerd Font"; font.pixelSize: window.s(13); color: window.subtext0 }
                                            Column {
                                                anchors.verticalCenter: parent.verticalCenter; spacing: 0
                                                Text { text: modelData.k; font.family: "Inter"; font.pixelSize: window.s(9); color: window.overlay1 }
                                                Text { text: modelData.v; font.family: "Inter"; font.weight: Font.DemiBold; font.pixelSize: window.s(12); color: window.text }
                                            }
                                        }
                                    }
                                }
                            }

                            // ── Section label for available items ─────────
                            Item {
                                width: listCol.width; height: window.s(20)
                                visible: listFlick.availModel !== null
                                Text {
                                    anchors.left: parent.left; anchors.leftMargin: window.s(4); anchors.bottom: parent.bottom
                                    text: (window.activeMode === "wifi" ? "OTHER NETWORKS" : "DEVICES")
                                    font.family: "Inter"; font.weight: Font.Bold; font.pixelSize: window.s(10); font.letterSpacing: window.s(1)
                                    color: window.overlay1
                                }
                            }

                            // ── Available networks / devices ──────────────
                            Repeater {
                                model: listFlick.availModel
                                delegate: Rectangle {
                                    id: row
                                    width: listCol.width
                                    required property int index
                                    required property string id
                                    required property string ssid
                                    required property string mac
                                    required property string name
                                    required property string icon
                                    required property string security
                                    required property bool isActionable

                                    readonly property bool _hidden: row.isActionable || root._isConnectedId(row.id)
                                    readonly property bool _busy: !!window.busyTasks[row.id]
                                    readonly property bool _secure: {
                                        let s = row.security ? row.security.trim().toLowerCase() : "";
                                        return s !== "" && s !== "open" && s !== "--" && s !== "none";
                                    }

                                    height: _hidden ? 0 : window.s(44)
                                    clip: true
                                    visible: height > 0
                                    Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                                    radius: window.s(10)
                                    color: rowMa.containsMouse ? window.surface1 : "transparent"
                                    Behavior on color { ColorAnimation { duration: 150 } }

                                    // stagger entry
                                    property real _in: 0.0
                                    Component.onCompleted: rowInTimer.start()
                                    Timer { id: rowInTimer; interval: 30 + row.index * 30; onTriggered: rowIn.start() }
                                    NumberAnimation { id: rowIn; target: row; property: "_in"; from: 0; to: 1; duration: 420; easing.type: Easing.OutExpo }
                                    opacity: row._hidden ? 0 : row._in
                                    transform: Translate { x: (1 - row._in) * window.s(16) }

                                    Row {
                                        anchors.left: parent.left; anchors.leftMargin: window.s(12)
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: window.s(11)
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: row.icon || window.idleGlyph
                                            font.family: "Iosevka Nerd Font"; font.pixelSize: window.s(16)
                                            color: window.subtext0
                                        }
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: row.name || row.ssid || row.id
                                            font.family: "Inter"; font.weight: Font.Medium; font.pixelSize: window.s(13)
                                            color: window.text
                                            width: window.s(230); elide: Text.ElideRight
                                        }
                                    }

                                    Item {
                                        anchors.right: parent.right; anchors.rightMargin: window.s(12)
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: window.s(22); height: window.s(22)
                                        LoadingDots { anchors.centerIn: parent; visible: row._busy; dotCol: window.text }
                                        Text {
                                            anchors.centerIn: parent
                                            visible: !row._busy && row._secure
                                            text: "󰌾"; font.family: "Iosevka Nerd Font"; font.pixelSize: window.s(12)
                                            color: window.overlay1
                                        }
                                    }

                                    MouseArea {
                                        id: rowMa
                                        anchors.fill: parent; hoverEnabled: true
                                        enabled: !row._hidden
                                        cursorShape: Qt.PointingHandCursor
                                        onEntered: window.hoveredCardCount++
                                        onExited: window.hoveredCardCount--
                                        onClicked: {
                                            if (row._busy) return;
                                            window.playSfx("switch.wav");
                                            root._selectItem(row.id, row.ssid, row.mac, row.security);
                                        }
                                    }
                                }
                            }

                            // ── empty hint when powered but nothing to show ──
                            Item {
                                width: listCol.width; height: window.s(60)
                                visible: window.currentPower && !window.currentConn
                                         && (listFlick.availModel === null || listFlick.availModel.count === 0)
                                Text {
                                    anchors.centerIn: parent
                                    text: window.activeMode === "eth" ? "No wired connection" : "Searching…"
                                    font.family: "Inter"; font.pixelSize: window.s(13); color: window.overlay1
                                }
                            }

                            Item { width: 1; height: window.s(8) } // bottom breathing room
                        }
                    }
                }
            }

            // ─── Password sheet (slides up when a secured network is tapped) ─
            Rectangle {
                id: pwSheet
                anchors.left: parent.left; anchors.right: parent.right
                height: window.s(124)
                radius: window.s(18)
                color: window.mantle
                border.color: window.hairline; border.width: 1

                readonly property bool open: window.pendingWifiId !== ""
                y: open ? parent.height - height : parent.height
                Behavior on y { NumberAnimation { duration: 360; easing.type: Easing.OutExpo } }

                onOpenChanged: if (open) pwField.forceActiveFocus()

                Column {
                    anchors.fill: parent
                    anchors.margins: window.s(16)
                    spacing: window.s(10)
                    Text {
                        text: "Password for “" + window.pendingWifiSsid + "”"
                        font.family: "Inter"; font.weight: Font.DemiBold; font.pixelSize: window.s(13); color: window.text
                        width: parent.width; elide: Text.ElideRight
                    }
                    Rectangle {
                        width: parent.width; height: window.s(36); radius: window.s(10)
                        color: window.surface0; border.color: pwField.activeFocus ? window.accent : window.surface2; border.width: 1
                        Behavior on border.color { ColorAnimation { duration: 200 } }
                        TextInput {
                            id: pwField
                            anchors.fill: parent; anchors.leftMargin: window.s(12); anchors.rightMargin: window.s(12)
                            verticalAlignment: TextInput.AlignVCenter
                            echoMode: TextInput.Password
                            font.family: "Inter"; font.pixelSize: window.s(13); color: window.text
                            clip: true
                            onAccepted: { let p = text; text = ""; root._joinWifi(p); }
                            Keys.onEscapePressed: { window.pendingWifiId = ""; window.pendingWifiSsid = ""; text = ""; }
                        }
                    }
                    Row {
                        anchors.right: parent.right
                        spacing: window.s(8)
                        Rectangle {
                            width: window.s(84); height: window.s(32); radius: window.s(9)
                            color: cancelMa.containsMouse ? window.surface1 : window.surface0
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Text { anchors.centerIn: parent; text: "Cancel"; font.family: "Inter"; font.weight: Font.DemiBold; font.pixelSize: window.s(12); color: window.text }
                            MouseArea { id: cancelMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: { window.pendingWifiId = ""; window.pendingWifiSsid = ""; pwField.text = ""; } }
                        }
                        Rectangle {
                            width: window.s(96); height: window.s(32); radius: window.s(9)
                            color: window.accent; opacity: joinMa.containsMouse ? 0.9 : 1.0
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                            Text { anchors.centerIn: parent; text: "Join"; font.family: "Inter"; font.weight: Font.Bold; font.pixelSize: window.s(12); color: window.crust }
                            MouseArea { id: joinMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: { let p = pwField.text; pwField.text = ""; root._joinWifi(p); } }
                        }
                    }
                }
            }
        }
    }
}
