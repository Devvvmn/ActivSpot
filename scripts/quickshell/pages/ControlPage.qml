import QtQuick
import Quickshell
import Quickshell.Io
import "../themes"

// Control Center — connectivity toggles, volume, quick actions.
// Tiles expand into in-island detail panels (wifi/wired/vpn, bluetooth,
// mixer, displays) so everything stays in one place — no external popups.
Item {
    id: root
    property var island
    clip: true

    // ── Open state ────────────────────────────────────────────────────────
    readonly property bool _open: island.expanded && island.currentPage === "control"

    on_OpenChanged: {
        if (_open) statePoll.restart()
        else detail = ""
        if (!_open || Theme.reduceMotion) return
        _hdrEy = island.s(12); hdrAnim.restart()
    }
    property real _hdrEy: 0
    NumberAnimation { id: hdrAnim; target: root; property: "_hdrEy"; to: 0; duration: 620; easing.type: Easing.OutExpo }

    // ── Detail sub-panel state ────────────────────────────────────────────
    // "" | "network" | "bt" | "mixer" | "display"
    property string detail: ""
    property bool _detailAnimating: false
    onDetailChanged: {
        island.controlExpandedHeight = detail === "" ? 340 : 430
        pwSsid = ""
        if (detail === "network") { wifiProc.running = true; netProc.running = true }
        if (detail === "bt")      btProc.running = true
        if (detail === "mixer")   mixProc.running = true
        if (detail === "display") dispProc.running = true
        if (detail !== "" && !Theme.reduceMotion) {
            _detailAnimating = true
            detailAnimWindow.restart()
        }
    }
    Timer { id: detailAnimWindow; interval: 700; onTriggered: root._detailAnimating = false }

    // External detail request (IPC page:control:<name> via island).
    // Bound property instead of Connections — signal connections on a
    // `property var island` target can silently fail.
    readonly property string _detailReq: island ? island.controlDetailRequest : ""
    on_DetailReqChanged: {
        if (_detailReq === "") return
        if (["network", "bt", "mixer", "display"].indexOf(_detailReq) >= 0) detail = _detailReq
        else if (_detailReq === "main") detail = ""
        Qt.callLater(function () { island.controlDetailRequest = "" })
    }

    // ── System state (main tiles) ─────────────────────────────────────────
    property bool   wifiOn:    false
    property string wifiSsid:  ""
    property bool   btOn:      false
    property int    btCount:   0
    property bool   micMuted:  false
    property bool   sinkMuted: false

    // Detail panel data
    property var wifiNets: []   // {ssid, signal, secured, inUse}
    property var knownConns: [] // saved connection profile names
    property string pwSsid: ""       // network with the password editor open
    property string wifiBusySsid: "" // connect in flight
    property string wifiFailSsid: "" // last failed connect (wrong password)
    property var ethDevs:  []   // {dev, state}
    property var vpnConns: []   // {name, active}
    property var btDevs:   []   // {mac, name, connected}
    property var sinks:    []   // {name, desc, vol, muted, isDefault}
    property var apps:     []   // {idx, name, vol, muted}
    property var mons:     []   // {name, model, w, h, rate, x, y, scale, transform, focused, modes:[{w,h,rate}]}
    property int monSel:   0
    property string dispRes: "" // "WxH" selected in the resolution column
    property int _mixDragging: 0

    function _setIfChanged(prop, arr) {
        if (JSON.stringify(root[prop]) !== JSON.stringify(arr)) root[prop] = arr
    }

    Process {
        id: stateProc
        command: ["bash", "-c",
            "w=$(nmcli -t -f WIFI radio 2>/dev/null); echo \"${w:-disabled}\";" +
            "s=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes' | head -1 | cut -d: -f2-); echo \"${s:--}\";" +
            "if systemctl is-active -q bluetooth 2>/dev/null; then " +
            "timeout 1 bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo 1 || echo 0; " +
            "c=$(timeout 1 bluetoothctl devices Connected 2>/dev/null | grep -c '^Device'); echo \"${c:-0}\"; " +
            "else echo 0; echo 0; fi;" +
            "pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null | grep -q yes && echo 1 || echo 0;" +
            "pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | grep -q yes && echo 1 || echo 0"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = this.text.split("\n")
                if (l.length < 6) return
                root.wifiOn    = l[0].trim() === "enabled"
                root.wifiSsid  = l[1].trim() === "-" ? "" : l[1].trim()
                root.btOn      = l[2].trim() === "1"
                root.btCount   = parseInt(l[3].trim()) || 0
                root.micMuted  = l[4].trim() === "1"
                root.sinkMuted = l[5].trim() === "1"
            }
        }
    }
    Timer {
        id: statePoll
        interval: 4000; running: root._open; repeat: true; triggeredOnStart: true
        onTriggered: stateProc.running = true
    }
    Timer { id: pollSoon; interval: 1200; onTriggered: stateProc.running = true }

    // ── Wi-Fi networks scan ───────────────────────────────────────────────
    Process {
        id: wifiProc
        command: ["bash", "-c", "nmcli -t --rescan no -f IN-USE,SIGNAL,SECURITY,SSID dev wifi list 2>/dev/null | head -40"]
        stdout: StdioCollector {
            onStreamFinished: {
                let nets = [], seen = {}
                const lines = this.text.split("\n")
                for (let i = 0; i < lines.length; i++) {
                    const f = lines[i].split(":")
                    if (f.length < 4) continue
                    const ssid = f.slice(3).join(":").trim()
                    if (ssid === "" || seen[ssid]) continue
                    seen[ssid] = true
                    nets.push({
                        ssid: ssid,
                        signal: parseInt(f[1]) || 0,
                        secured: f[2].trim() !== "" && f[2].trim() !== "--",
                        inUse: f[0].trim() === "*"
                    })
                }
                nets.sort(function (a, b) {
                    if (a.inUse !== b.inUse) return a.inUse ? -1 : 1
                    return b.signal - a.signal
                })
                root._setIfChanged("wifiNets", nets)
            }
        }
    }
    Timer {
        interval: 12000; running: root._open && root.detail === "network"; repeat: true
        onTriggered: wifiProc.running = true
    }
    Timer { id: wifiPollSoon; interval: 3000; onTriggered: { wifiProc.running = true; netProc.running = true } }

    // ── Wired + VPN ───────────────────────────────────────────────────────
    Process {
        id: netProc
        command: ["bash", "-c",
            "nmcli -t -f DEVICE,TYPE,STATE d 2>/dev/null | grep ':ethernet:'; echo '---';" +
            "nmcli -t -f NAME,TYPE,ACTIVE connection show 2>/dev/null | grep -E ':(wireguard|vpn):'; echo '---';" +
            "nmcli -t -f NAME,TYPE connection show 2>/dev/null | grep ':802-11-wireless' | cut -d: -f1; echo '---';" +
            "ip -o link show type wireguard 2>/dev/null | awk -F': ' '{print $2}'; echo '---';" +
            "ip -o link show up type wireguard 2>/dev/null | awk -F': ' '{print $2}'"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = this.text.split("---")
                if (parts.length < 3) return
                let known = []
                const kl = parts[2].split("\n")
                for (let k = 0; k < kl.length; k++)
                    if (kl[k].trim() !== "") known.push(kl[k].trim())
                root._setIfChanged("knownConns", known)
                let eth = [], vpn = []
                const el = parts[0].split("\n")
                for (let i = 0; i < el.length; i++) {
                    const f = el[i].split(":")
                    if (f.length < 3 || f[0].trim() === "") continue
                    eth.push({ dev: f[0].trim(), state: f[2].trim() })
                }
                const vl = parts[1].split("\n")
                for (let j = 0; j < vl.length; j++) {
                    const g = vl[j].split(":")
                    if (g.length < 3 || g[0].trim() === "") continue
                    vpn.push({ name: g[0].trim(), active: g[2].trim() === "yes", external: false })
                }
                // Wireguard interfaces managed outside NetworkManager (wg-quick,
                // systemd-networkd) — shown read-only, no toggle without root
                if (parts.length >= 5) {
                    let upSet = {}
                    const ul = parts[4].split("\n")
                    for (let u = 0; u < ul.length; u++)
                        if (ul[u].trim() !== "") upSet[ul[u].trim()] = true
                    const wl = parts[3].split("\n")
                    for (let w = 0; w < wl.length; w++) {
                        const iface = wl[w].trim()
                        if (iface === "") continue
                        let managed = false
                        for (let v = 0; v < vpn.length; v++)
                            if (vpn[v].name === iface) { managed = true; break }
                        if (!managed) vpn.push({ name: iface, active: !!upSet[iface], external: true })
                    }
                }
                root._setIfChanged("ethDevs", eth)
                root._setIfChanged("vpnConns", vpn)
            }
        }
    }
    Timer {
        interval: 6000; running: root._open && root.detail === "network"; repeat: true
        onTriggered: netProc.running = true
    }

    // ── Wi-Fi connect (with result feedback) ──────────────────────────────
    Process {
        id: wifiConnectProc
        property string targetSsid: ""
        onExited: {
            root.wifiBusySsid = ""
            if (exitCode !== 0) {
                root.wifiFailSsid = targetSsid
                wifiFailClear.restart()
                // nmcli leaves a broken profile behind on a bad password —
                // drop it so the next attempt starts clean (NetworkPopup does the same)
                island.exec("nmcli connection delete '" + targetSsid.replace(/'/g, "'\\''") + "' 2>/dev/null")
            } else {
                root.pwSsid = ""
                root.wifiFailSsid = ""
            }
            wifiProc.running = true
            netProc.running = true
            stateProc.running = true
        }
    }
    Timer { id: wifiFailClear; interval: 5000; onTriggered: root.wifiFailSsid = "" }
    function wifiConnect(ssid, password) {
        if (wifiBusySsid !== "") return
        const esc = ssid.replace(/'/g, "'\\''")
        wifiConnectProc.targetSsid = ssid
        wifiFailSsid = ""
        wifiBusySsid = ssid
        wifiConnectProc.command = password !== ""
            ? ["bash", "-c", "nmcli device wifi connect '" + esc + "' password '" + password.replace(/'/g, "'\\''") + "'"]
            : ["bash", "-c", "nmcli device wifi connect '" + esc + "'"]
        wifiConnectProc.running = true
    }

    // ── Bluetooth devices ─────────────────────────────────────────────────
    Process {
        id: btProc
        command: ["bash", "-c",
            "systemctl is-active -q bluetooth 2>/dev/null || { echo '---'; exit 0; };" +
            "timeout 2 bluetoothctl devices 2>/dev/null; echo '---';" +
            "timeout 2 bluetoothctl devices Connected 2>/dev/null"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = this.text.split("---")
                if (parts.length < 2) return
                let conn = {}
                const cl = parts[1].split("\n")
                for (let i = 0; i < cl.length; i++) {
                    const m = cl[i].match(/^Device ([0-9A-F:]+)/i)
                    if (m) conn[m[1]] = true
                }
                let devs = []
                const dl = parts[0].split("\n")
                for (let j = 0; j < dl.length; j++) {
                    const m = dl[j].match(/^Device ([0-9A-F:]+) (.+)$/i)
                    if (!m) continue
                    devs.push({ mac: m[1], name: m[2].trim(), connected: !!conn[m[1]] })
                }
                devs.sort(function (a, b) {
                    if (a.connected !== b.connected) return a.connected ? -1 : 1
                    return a.name.localeCompare(b.name)
                })
                root._setIfChanged("btDevs", devs)
            }
        }
    }
    Timer {
        interval: 6000; running: root._open && root.detail === "bt"; repeat: true
        onTriggered: btProc.running = true
    }
    Timer { id: btPollSoon; interval: 2500; onTriggered: { btProc.running = true; stateProc.running = true } }

    // ── Audio mixer (sinks + per-app streams) ─────────────────────────────
    Process {
        id: mixProc
        command: ["bash", "-c",
            "pactl -f json list sinks 2>/dev/null; echo '@@@';" +
            "pactl -f json list sink-inputs 2>/dev/null; echo '@@@';" +
            "pactl get-default-sink 2>/dev/null"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                if (root._mixDragging > 0) return
                const parts = this.text.split("@@@")
                if (parts.length < 3) return
                const defSink = parts[2].trim()
                function volPct(v) {
                    if (!v || !v.volume) return 0
                    const k = Object.keys(v.volume)
                    if (k.length === 0) return 0
                    return parseInt(v.volume[k[0]].value_percent) || 0
                }
                let sk = [], ap = []
                try {
                    const raw = JSON.parse(parts[0])
                    for (let i = 0; i < raw.length; i++) {
                        sk.push({
                            name: raw[i].name,
                            desc: raw[i].description || raw[i].name,
                            vol: volPct(raw[i]),
                            muted: !!raw[i].mute,
                            isDefault: raw[i].name === defSink
                        })
                    }
                } catch (e) {}
                try {
                    const raw2 = JSON.parse(parts[1])
                    for (let j = 0; j < raw2.length; j++) {
                        const p = raw2[j].properties || {}
                        ap.push({
                            idx: raw2[j].index,
                            name: p["application.name"] || p["media.name"] || ("stream " + raw2[j].index),
                            vol: volPct(raw2[j]),
                            muted: !!raw2[j].mute
                        })
                    }
                } catch (e) {}
                root._setIfChanged("sinks", sk)
                root._setIfChanged("apps", ap)
            }
        }
    }
    Timer {
        interval: 4000; running: root._open && root.detail === "mixer"; repeat: true
        onTriggered: mixProc.running = true
    }
    Timer { id: mixPollSoon; interval: 700; onTriggered: mixProc.running = true }

    // ── Displays (hyprctl monitors) ───────────────────────────────────────
    Process {
        id: dispProc
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                let out = []
                try {
                    const raw = JSON.parse(this.text)
                    for (let i = 0; i < raw.length; i++) {
                        const m = raw[i]
                        let modes = []
                        const am = m.availableModes || []
                        for (let j = 0; j < am.length; j++) {
                            const mm = am[j].match(/(\d+)x(\d+)@([\d.]+)Hz/)
                            if (mm) modes.push({ w: parseInt(mm[1]), h: parseInt(mm[2]), rate: parseFloat(mm[3]) })
                        }
                        out.push({
                            name: m.name, model: m.model || "",
                            w: m.width, h: m.height,
                            rate: Math.round(m.refreshRate * 100) / 100,
                            x: m.x, y: m.y,
                            scale: m.scale, transform: m.transform || 0,
                            focused: !!m.focused,
                            modes: modes
                        })
                    }
                } catch (e) {}
                if (out.length === 0) return
                root._setIfChanged("mons", out)
                if (root.monSel >= out.length) root.monSel = 0
                const cur = out[root.monSel]
                if (root.dispRes === "" || !root._resExists(cur, root.dispRes))
                    root.dispRes = cur.w + "x" + cur.h
            }
        }
    }
    Timer {
        interval: 5000; running: root._open && root.detail === "display"; repeat: true
        onTriggered: dispProc.running = true
    }
    Timer { id: dispPollSoon; interval: 1200; onTriggered: dispProc.running = true }

    function _resExists(mon, res) {
        for (let i = 0; i < mon.modes.length; i++)
            if (mon.modes[i].w + "x" + mon.modes[i].h === res) return true
        return false
    }
    function resListFor(mon) {
        if (!mon) return []
        let seen = {}, out = []
        for (let i = 0; i < mon.modes.length; i++) {
            const key = mon.modes[i].w + "x" + mon.modes[i].h
            if (seen[key]) continue
            seen[key] = true
            out.push({ w: mon.modes[i].w, h: mon.modes[i].h, key: key })
        }
        out.sort(function (a, b) { return b.w * b.h - a.w * a.h })
        return out
    }
    function ratesFor(mon, res) {
        if (!mon) return []
        let out = []
        for (let i = 0; i < mon.modes.length; i++) {
            const m = mon.modes[i]
            if (m.w + "x" + m.h === res) out.push(m.rate)
        }
        out.sort(function (a, b) { return b - a })
        return out
    }
    // Apply mode/scale: hyprctl keyword + persist to settings.json (same
    // shape MonitorPopup writes) + hyprlax restart, mirroring triggerApply().
    function applyMonitor(mon, w, h, rate, scale) {
        let str = mon.name + "," + w + "x" + h + "@" + rate + "," + mon.x + "x" + mon.y + "," + scale
        if (mon.transform !== 0) str += ",transform," + mon.transform
        let arr = []
        for (let i = 0; i < root.mons.length; i++) {
            const m = root.mons[i]
            const sel = i === root.monSel
            arr.push({
                name: m.name,
                resW: sel ? w : m.w, resH: sel ? h : m.h,
                rate: Math.round(sel ? rate : m.rate),
                x: m.x, y: m.y,
                scale: sel ? scale : m.scale,
                transform: m.transform
            })
        }
        const safeJson = JSON.stringify(arr).replace(/'/g, "'\\''")
        const jsonCmd = "jq '.monitors = " + safeJson + "' \"$HOME/.config/hypr/settings.json\" > \"$HOME/.config/hypr/settings.json.tmp\" && mv \"$HOME/.config/hypr/settings.json.tmp\" \"$HOME/.config/hypr/settings.json\""
        const hyprlaxCmd = "pkill -x hyprlax ; sleep 0.2 ; W=$(cat ~/.cache/wallpaper_picker/current 2>/dev/null) ; [ -n \"$W\" ] && setsid -f $HOME/.local/bin/hyprlax --input cursor:0.0001,workspace \"$W\" >/dev/null 2>&1 &"
        island.exec("hyprctl keyword monitor '" + str + "' ; " + jsonCmd + " ; " + hyprlaxCmd)
        dispPollSoon.restart()
    }

    Timer {
        id: volThrottle; interval: 50
        property int target: -1
        onTriggered: {
            if (target >= 0) {
                island.exec("pactl set-sink-volume @DEFAULT_SINK@ " + target + "%")
                target = -1
            }
        }
    }

    function openWidget(name) {
        island.expanded = false
        island.exec("echo '" + name + "' > /tmp/qs_widget_state")
    }

    function wifiIconFor(sig) {
        if (sig >= 75) return "󰤨"
        if (sig >= 50) return "󰤥"
        if (sig >= 25) return "󰤢"
        return "󰤟"
    }

    // ── Toggle tile (house style: surface0 card + mini switch) ───────────
    component LiquidTile: Rectangle {
        id: tile
        property string icon:     ""
        property string iconOff:  ""
        property string title:    ""
        property string status:   ""
        property bool   active:   false
        property color  accent:   island.mauve
        property int    entryIndex: 0
        property bool   hasMore:  false
        signal toggled()
        signal more()

        radius: island.s(12)
        clip: true
        color: active
            ? Qt.rgba(accent.r, accent.g, accent.b, tileMa.containsMouse ? 0.16 : 0.12)
            : Qt.rgba(island.surface0.r, island.surface0.g, island.surface0.b, tileMa.containsMouse ? 0.85 : 0.70)
        border.width: 1
        border.color: active
            ? Qt.rgba(accent.r, accent.g, accent.b, 0.35)
            : Qt.rgba(island.text.r, island.text.g, island.text.b, tileMa.containsMouse ? 0.16 : 0.10)
        Behavior on color        { ColorAnimation { duration: 180 } }
        Behavior on border.color { ColorAnimation { duration: 180 } }

        scale: tileMa.pressed ? 0.97 : 1.0
        Behavior on scale { SpringAnimation { spring: 4.2; damping: 0.32; epsilon: 0.004 } }

        transform: Translate { y: tile._ey }
        property real _ey: 0
        Connections {
            target: root
            function on_OpenChanged() {
                if (!root._open || Theme.reduceMotion) return
                tile._ey = island.s(22)
                tileStagger.interval = 50 + tile.entryIndex * 60
                tileStagger.restart()
            }
        }
        Timer { id: tileStagger; onTriggered: tileEntry.restart() }
        NumberAnimation { id: tileEntry; target: tile; property: "_ey"; to: 0; duration: 600; easing.type: Easing.OutExpo }

        // Icon bubble pops when the state actually flips
        onActiveChanged: if (!Theme.reduceMotion && root._open) bubblePop.restart()

        // Glass sheen — faint light from the top
        Rectangle {
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: parent.height * 0.5
            radius: parent.radius
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#0dffffff" }
                GradientStop { position: 1.0; color: "#00ffffff" }
            }
        }

        // Soft accent wash inside the card while active (clipped)
        Rectangle {
            x: -width * 0.25; y: -height * 0.35
            width: parent.width * 0.9; height: width; radius: width / 2
            color: Qt.rgba(tile.accent.r, tile.accent.g, tile.accent.b, 0.10)
            opacity: tile.active ? 1.0 : 0.0
            scale: tile.active ? 1.0 : 0.6
            Behavior on opacity { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
            Behavior on scale   { NumberAnimation { duration: 380; easing.type: Easing.OutExpo } }
        }

        Rectangle {
            id: iconBubble
            anchors { left: parent.left; top: parent.top; margins: island.s(12) }
            width: island.s(32); height: width; radius: width / 2
            color: tile.active
                ? Qt.rgba(tile.accent.r, tile.accent.g, tile.accent.b, 0.20)
                : Qt.rgba(island.surface1.r, island.surface1.g, island.surface1.b, 0.85)
            Behavior on color { ColorAnimation { duration: 180 } }

            SequentialAnimation {
                id: bubblePop
                NumberAnimation { target: iconBubble; property: "scale"; to: 1.14; duration: 90;  easing.type: Easing.OutQuad }
                SpringAnimation { target: iconBubble; property: "scale"; to: 1.0;  spring: 3.8; damping: 0.28; epsilon: 0.004 }
            }

            Text {
                anchors.centerIn: parent
                text: tile.active || tile.iconOff === "" ? tile.icon : tile.iconOff
                font.family: "Iosevka Nerd Font"
                font.pixelSize: island.s(15)
                color: tile.active ? tile.accent : Theme.overlay0
                Behavior on color { ColorAnimation { duration: 180 } }
            }
        }

        Rectangle {
            anchors { right: parent.right; top: parent.top; rightMargin: island.s(12); topMargin: island.s(18) }
            width: island.s(36); height: island.s(20); radius: island.s(10)
            color: tile.active ? tile.accent : island.surface1
            Behavior on color { ColorAnimation { duration: 180 } }
            Rectangle {
                width: island.s(14); height: island.s(14); radius: island.s(7)
                color: Qt.rgba(0.97, 0.96, 1.0, 1.0)
                anchors.verticalCenter: parent.verticalCenter
                x: tile.active ? island.s(19) : island.s(3)
                Behavior on x { SpringAnimation { spring: 4.6; damping: 0.36; epsilon: 0.02 } }
            }
        }

        Column {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: island.s(12) }
            spacing: island.s(1)
            Text {
                text: tile.title
                font.family: Theme.fontUI
                font.pixelSize: island.s(12)
                font.weight: Font.DemiBold
                color: island.text
                width: parent.width
                elide: Text.ElideRight
            }
            Text {
                text: tile.status
                font.family: "JetBrains Mono"
                font.pixelSize: island.s(9)
                color: tile.active ? tile.accent : island.subtext0
                width: parent.width
                elide: Text.ElideRight
                Behavior on color { ColorAnimation { duration: 180 } }
            }
        }

        MouseArea {
            id: tileMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tile.toggled()
        }

        Rectangle {
            visible: tile.hasMore
            anchors { right: parent.right; bottom: parent.bottom; margins: island.s(10) }
            width: island.s(24); height: width; radius: width / 2
            color: moreMa.containsMouse
                ? Qt.rgba(island.surface2.r, island.surface2.g, island.surface2.b, 0.95)
                : Qt.rgba(island.surface1.r, island.surface1.g, island.surface1.b, 0.60)
            Behavior on color { ColorAnimation { duration: 140 } }
            scale: moreMa.pressed ? 0.85 : (moreMa.containsMouse ? 1.1 : 1.0)
            Behavior on scale { SpringAnimation { spring: 4.5; damping: 0.32 } }
            Text {
                anchors.centerIn: parent
                text: "󰅂"
                font.family: "Iosevka Nerd Font"
                font.pixelSize: island.s(12)
                color: moreMa.containsMouse ? island.text : island.subtext0
                Behavior on color { ColorAnimation { duration: 140 } }
            }
            MouseArea {
                id: moreMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: tile.more()
            }
        }
    }

    component SectionLabel: Text {
        font.family: "JetBrains Mono"
        font.pixelSize: island.s(8)
        font.weight: Font.Black
        font.letterSpacing: island.s(1.0)
        color: Theme.overlay0
    }

    component QuickAction: Rectangle {
        id: qa
        property string icon:   ""
        property string label:  ""
        property color  accent: island.text
        signal activated()

        radius: island.s(10)
        color: qaMa.containsMouse
            ? Qt.rgba(island.surface2.r, island.surface2.g, island.surface2.b, 0.85)
            : Qt.rgba(island.surface0.r, island.surface0.g, island.surface0.b, 0.70)
        border.width: 1
        border.color: qaMa.containsMouse
            ? Qt.rgba(qa.accent.r, qa.accent.g, qa.accent.b, 0.35)
            : Qt.rgba(island.text.r, island.text.g, island.text.b, 0.10)
        Behavior on color        { ColorAnimation { duration: 140 } }
        Behavior on border.color { ColorAnimation { duration: 140 } }
        scale: qaMa.pressed ? 0.94 : 1.0
        Behavior on scale { SpringAnimation { spring: 4.5; damping: 0.32 } }

        Column {
            anchors.centerIn: parent
            spacing: island.s(4)

            Text {
                text: qa.icon
                font.family: "Iosevka Nerd Font"
                font.pixelSize: island.s(16)
                color: qaMa.containsMouse ? qa.accent : island.subtext0
                anchors.horizontalCenter: parent.horizontalCenter
                Behavior on color { ColorAnimation { duration: 140 } }
                transform: Translate { y: qa._lift }
            }
            Text {
                text: qa.label
                font.family: "JetBrains Mono"
                font.pixelSize: island.s(8)
                color: qaMa.containsMouse ? island.text : island.subtext0
                anchors.horizontalCenter: parent.horizontalCenter
                Behavior on color { ColorAnimation { duration: 140 } }
            }
        }
        property real _lift: qaMa.containsMouse ? -island.s(2) : 0
        Behavior on _lift { NumberAnimation { duration: 220; easing.type: Easing.OutQuint } }

        MouseArea {
            id: qaMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: qa.activated()
        }
    }

    // ── Detail list row (staggered entry, hover shift) ────────────────────
    component DetailRow: Rectangle {
        id: drow
        property string icon:   ""
        property string label:  ""
        property string sub:    ""
        property bool   active: false
        property bool   subDanger: false
        property color  accent: Theme.accent
        property int    rowIndex: 0
        signal clicked()

        height: island.s(34)
        radius: island.s(9)
        color: drowMa.containsMouse
            ? Qt.rgba(island.surface2.r, island.surface2.g, island.surface2.b, 0.75)
            : active
                ? Qt.rgba(accent.r, accent.g, accent.b, 0.10)
                : Qt.rgba(island.surface0.r, island.surface0.g, island.surface0.b, 0.55)
        border.width: 1
        border.color: active
            ? Qt.rgba(accent.r, accent.g, accent.b, 0.30)
            : Qt.rgba(island.text.r, island.text.g, island.text.b, 0.07)
        Behavior on color        { ColorAnimation { duration: 130 } }
        Behavior on border.color { ColorAnimation { duration: 130 } }

        scale: drowMa.pressed ? 0.98 : 1.0
        Behavior on scale { SpringAnimation { spring: 4.6; damping: 0.35 } }

        // Cascade entry: single animated property drives slide + fade
        property real _ex: 0
        opacity: Math.max(0, 1 - _ex / island.s(30))
        transform: Translate { x: drow._ex }
        function _kick() {
            if (!root._detailAnimating || Theme.reduceMotion) return
            _ex = island.s(28)
            rowStagger.interval = 30 + Math.min(rowIndex, 12) * 32
            rowStagger.restart()
        }
        Component.onCompleted: _kick()
        Connections {
            target: root
            function onDetailChanged() { drow._kick() }
        }
        Timer { id: rowStagger; onTriggered: rowEntry.restart() }
        NumberAnimation { id: rowEntry; target: drow; property: "_ex"; to: 0; duration: 480; easing.type: Easing.OutExpo }

        Text {
            id: drowIcon
            anchors { left: parent.left; leftMargin: island.s(10); verticalCenter: parent.verticalCenter }
            text: drow.icon
            font.family: "Iosevka Nerd Font"
            font.pixelSize: island.s(13)
            color: drow.active ? drow.accent : Theme.overlay0
            Behavior on color { ColorAnimation { duration: 130 } }
        }
        Text {
            anchors { left: drowIcon.right; leftMargin: island.s(8); right: drowSub.left; rightMargin: island.s(8); verticalCenter: parent.verticalCenter }
            text: drow.label
            font.family: Theme.fontUI
            font.pixelSize: island.s(11)
            font.weight: drow.active ? Font.DemiBold : Font.Medium
            color: island.text
            elide: Text.ElideRight
        }
        Text {
            id: drowSub
            anchors { right: parent.right; rightMargin: island.s(10); verticalCenter: parent.verticalCenter }
            text: drow.sub
            font.family: "JetBrains Mono"
            font.pixelSize: island.s(8)
            color: drow.subDanger ? island.red : (drow.active ? drow.accent : island.subtext0)
            Behavior on color { ColorAnimation { duration: 130 } }
        }
        MouseArea {
            id: drowMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: drow.clicked()
        }
    }

    // ── App volume row (mixer) ────────────────────────────────────────────
    component AppVolRow: Rectangle {
        id: arow
        property int    appIdx:  -1
        property string label:   ""
        property int    vol:     0
        property bool   muted:   false
        property int    rowIndex: 0

        height: island.s(44)
        radius: island.s(9)
        color: Qt.rgba(island.surface0.r, island.surface0.g, island.surface0.b, 0.55)
        border.width: 1
        border.color: Qt.rgba(island.text.r, island.text.g, island.text.b, 0.07)

        property real _ex: 0
        opacity: Math.max(0, 1 - _ex / island.s(30))
        transform: Translate { x: arow._ex }
        function _kick() {
            if (!root._detailAnimating || Theme.reduceMotion) return
            _ex = island.s(28)
            arowStagger.interval = 30 + Math.min(rowIndex, 12) * 32
            arowStagger.restart()
        }
        Component.onCompleted: _kick()
        Connections {
            target: root
            function onDetailChanged() { arow._kick() }
        }
        Timer { id: arowStagger; onTriggered: arowEntry.restart() }
        NumberAnimation { id: arowEntry; target: arow; property: "_ex"; to: 0; duration: 480; easing.type: Easing.OutExpo }

        Timer {
            id: arowThrottle; interval: 60
            property int target: -1
            onTriggered: {
                if (target >= 0 && arow.appIdx >= 0) {
                    island.exec("pactl set-sink-input-volume " + arow.appIdx + " " + target + "%")
                    target = -1
                }
            }
        }

        Text {
            id: arowMuteBtn
            anchors { left: parent.left; leftMargin: island.s(10); verticalCenter: parent.verticalCenter }
            text: arow.muted ? "󰖁" : "󰕾"
            font.family: "Iosevka Nerd Font"
            font.pixelSize: island.s(13)
            color: arow.muted ? island.red : Theme.overlay0
            Behavior on color { ColorAnimation { duration: 130 } }
            MouseArea {
                anchors.fill: parent
                anchors.margins: -island.s(5)
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    arow.muted = !arow.muted
                    island.exec("pactl set-sink-input-mute " + arow.appIdx + " toggle")
                    mixPollSoon.restart()
                }
            }
        }
        Text {
            anchors { left: arowMuteBtn.right; leftMargin: island.s(8); right: arowPct.left; rightMargin: island.s(8); top: parent.top; topMargin: island.s(6) }
            text: arow.label
            font.family: Theme.fontUI
            font.pixelSize: island.s(10)
            font.weight: Font.Medium
            color: island.text
            elide: Text.ElideRight
        }
        Text {
            id: arowPct
            anchors { right: parent.right; rightMargin: island.s(10); top: parent.top; topMargin: island.s(6) }
            text: arow.vol + "%"
            font.family: "JetBrains Mono"
            font.pixelSize: island.s(9)
            font.weight: Font.Bold
            color: Theme.accent
        }

        Item {
            anchors { left: arowMuteBtn.right; leftMargin: island.s(8); right: parent.right; rightMargin: island.s(10); bottom: parent.bottom }
            height: island.s(18)

            Rectangle {
                id: arowTrack
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: arowMa.pressed ? island.s(8) : island.s(6)
                radius: height / 2
                color: Qt.rgba(island.surface2.r, island.surface2.g, island.surface2.b, 0.90)
                Behavior on height { SpringAnimation { spring: 4.0; damping: 0.34 } }
                Rectangle {
                    anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
                    width: parent.width * Math.min(1.0, arow.vol / 100.0)
                    radius: parent.radius
                    color: arow.muted
                        ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.30)
                        : Theme.accent
                    Behavior on color { ColorAnimation { duration: 130 } }
                }
            }
            MouseArea {
                id: arowMa
                anchors.fill: parent
                onPressed: (m) => { root._mixDragging++; setV(m.x) }
                onPositionChanged: (m) => { if (pressed) setV(m.x) }
                onReleased: { root._mixDragging = Math.max(0, root._mixDragging - 1); mixPollSoon.restart() }
                function setV(x) {
                    const p = Math.round(Math.max(0, Math.min(100, x / width * 100)))
                    arow.vol = p
                    arowThrottle.target = p
                    if (!arowThrottle.running) arowThrottle.start()
                }
            }
        }
    }

    // =====================================================================
    // MAIN VIEW
    // =====================================================================
    Item {
        id: frame
        anchors.fill: parent
        anchors { leftMargin: island.s(22); rightMargin: island.s(22); topMargin: island.s(14); bottomMargin: island.s(46) }

        Item {
            id: mainView
            anchors.fill: parent
            opacity: root.detail === "" ? 1.0 : 0.0
            visible: opacity > 0.001
            enabled: root.detail === ""
            Behavior on opacity { NumberAnimation { duration: Theme.reduceMotion ? 0 : 200; easing.type: Easing.OutCubic } }
            scale: root.detail === "" ? 1.0 : 0.975
            Behavior on scale { NumberAnimation { duration: Theme.reduceMotion ? 0 : 300; easing.type: Easing.OutExpo } }
            property real _tx: root.detail === "" ? 0 : -island.s(44)
            Behavior on _tx { NumberAnimation { duration: Theme.reduceMotion ? 0 : 300; easing.type: Easing.OutExpo } }
            transform: Translate { x: mainView._tx }

            // Header
            Item {
                id: header
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: island.s(20)
                transform: Translate { y: root._hdrEy }

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: island.s(8)
                    Text {
                        text: "󰨙"
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: island.s(13)
                        color: Theme.accent
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "CONTROL CENTER"
                        font.family: "JetBrains Mono"
                        font.pixelSize: island.s(9)
                        font.weight: Font.Black
                        font.letterSpacing: island.s(1.4)
                        color: Theme.overlay0
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                Row {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    spacing: island.s(10)
                    Text {
                        visible: island.vpnActive
                        text: "󰖂 " + island.vpnInterface
                        font.family: "JetBrains Mono"
                        font.pixelSize: island.s(9)
                        font.weight: Font.Bold
                        color: island.green
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        visible: root.wifiOn && root.wifiSsid !== ""
                        text: "󰤨 " + root.wifiSsid
                        font.family: "JetBrains Mono"
                        font.pixelSize: island.s(9)
                        color: island.subtext0
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            Item {
                id: body
                anchors { top: header.bottom; topMargin: island.s(12); left: parent.left; right: parent.right; bottom: parent.bottom }

                // ── Left: 2×2 toggle grid ────────────────────────────────
                Item {
                    id: gridArea
                    anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                    width: Math.round(parent.width * 0.55)

                    readonly property real gap: island.s(12)
                    readonly property real tw:  (width  - gap) / 2
                    readonly property real th:  (height - gap) / 2

                    LiquidTile {
                        x: 0; y: 0; width: gridArea.tw; height: gridArea.th
                        entryIndex: 0
                        icon: "󰤨"; iconOff: "󰤭"
                        title: "Wi-Fi"
                        status: root.wifiOn ? (root.wifiSsid !== "" ? root.wifiSsid : "on") : "off"
                        active: root.wifiOn
                        accent: island.blue
                        hasMore: true
                        onToggled: {
                            root.wifiOn = !root.wifiOn
                            island.exec("nmcli radio wifi " + (root.wifiOn ? "on" : "off"))
                            pollSoon.restart()
                        }
                        onMore: root.detail = "network"
                    }
                    LiquidTile {
                        x: gridArea.tw + gridArea.gap; y: 0; width: gridArea.tw; height: gridArea.th
                        entryIndex: 1
                        icon: root.btCount > 0 ? "󰂱" : "󰂯"; iconOff: "󰂲"
                        title: "Bluetooth"
                        status: root.btOn ? (root.btCount > 0 ? root.btCount + " connected" : "on") : "off"
                        active: root.btOn
                        accent: island.teal
                        hasMore: true
                        onToggled: {
                            root.btOn = !root.btOn
                            island.exec(root.btOn
                                ? "rfkill unblock bluetooth 2>/dev/null; timeout 2 bluetoothctl power on"
                                : "timeout 2 bluetoothctl power off")
                            pollSoon.restart()
                        }
                        onMore: root.detail = "bt"
                    }
                    LiquidTile {
                        x: 0; y: gridArea.th + gridArea.gap; width: gridArea.tw; height: gridArea.th
                        entryIndex: 2
                        icon: "󰂛"; iconOff: "󰂚"
                        title: "Do Not Disturb"
                        status: island.dndEnabled ? "silenced" : "alerts on"
                        active: island.dndEnabled
                        accent: island.mauve
                        onToggled: {
                            island.dndEnabled = !island.dndEnabled
                            island.exec("mkdir -p ~/.cache && echo '" + (island.dndEnabled ? "1" : "0") + "' > ~/.cache/qs_dnd")
                        }
                    }
                    LiquidTile {
                        x: gridArea.tw + gridArea.gap; y: gridArea.th + gridArea.gap; width: gridArea.tw; height: gridArea.th
                        entryIndex: 3
                        icon: "󰁞"
                        title: "Always on Top"
                        status: island.alwaysOnTop ? "pinned" : "auto"
                        active: island.alwaysOnTop
                        accent: island.peach
                        onToggled: {
                            island.alwaysOnTop = !island.alwaysOnTop
                            island.exec("mkdir -p ~/.cache && echo '" + (island.alwaysOnTop ? "1" : "0") + "' > ~/.cache/qs_island_aot")
                        }
                    }
                }

                // ── Right: audio + quick actions ─────────────────────────
                Item {
                    id: rightArea
                    anchors { left: gridArea.right; leftMargin: island.s(14); right: parent.right; top: parent.top; bottom: parent.bottom }

                    Rectangle {
                        id: volCard
                        anchors { top: parent.top; left: parent.left; right: parent.right }
                        height: island.s(84)
                        radius: island.s(12)
                        color: Qt.rgba(island.surface0.r, island.surface0.g, island.surface0.b, 0.70)
                        border.width: 1
                        border.color: volMa.dragging
                            ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.35)
                            : Qt.rgba(island.text.r, island.text.g, island.text.b, 0.10)
                        Behavior on border.color { ColorAnimation { duration: 180 } }
                        clip: true

                        transform: Translate { y: volCard._ey }
                        property real _ey: 0
                        Connections {
                            target: root
                            function on_OpenChanged() {
                                if (!root._open || Theme.reduceMotion) return
                                volCard._ey = island.s(22)
                                volStagger.restart()
                            }
                        }
                        Timer { id: volStagger; interval: 110; onTriggered: volEntry.restart() }
                        NumberAnimation { id: volEntry; target: volCard; property: "_ey"; to: 0; duration: 600; easing.type: Easing.OutExpo }

                        Rectangle {
                            anchors { top: parent.top; left: parent.left; right: parent.right }
                            height: parent.height * 0.5
                            radius: parent.radius
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "#0dffffff" }
                                GradientStop { position: 1.0; color: "#00ffffff" }
                            }
                        }

                        Item {
                            anchors.fill: parent
                            anchors.margins: island.s(14)

                            Row {
                                anchors { top: parent.top; left: parent.left }
                                spacing: island.s(8)
                                Text {
                                    text: root.sinkMuted || island.currentVol === 0 ? "󰖁" : (island.currentVol > 55 ? "󰕾" : "󰖀")
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: island.s(15)
                                    color: root.sinkMuted ? island.red : island.text
                                    anchors.verticalCenter: parent.verticalCenter
                                    Behavior on color { ColorAnimation { duration: 180 } }
                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.margins: -island.s(4)
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.sinkMuted = !root.sinkMuted
                                            island.exec("pactl set-sink-mute @DEFAULT_SINK@ toggle")
                                        }
                                    }
                                }
                                Text {
                                    text: "Volume"
                                    font.family: Theme.fontUI
                                    font.pixelSize: island.s(12)
                                    font.weight: Font.DemiBold
                                    color: island.text
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                            Text {
                                anchors { top: parent.top; right: parent.right }
                                text: root.sinkMuted ? "muted" : island.currentVol + "%"
                                font.family: "JetBrains Mono"
                                font.pixelSize: island.s(12)
                                font.weight: Font.Black
                                color: root.sinkMuted ? island.red : Theme.accent
                                Behavior on color { ColorAnimation { duration: 180 } }
                            }

                            Item {
                                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                                height: island.s(26)

                                Rectangle {
                                    id: volTrack
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width
                                    height: volMa.dragging ? island.s(12) : island.s(8)
                                    radius: height / 2
                                    color: Qt.rgba(island.surface2.r, island.surface2.g, island.surface2.b, 0.90)
                                    Behavior on height { SpringAnimation { spring: 4.0; damping: 0.34 } }

                                    Rectangle {
                                        id: volFill
                                        anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
                                        width: parent.width * Math.min(1.0, island.currentVol / 100.0)
                                        radius: parent.radius
                                        color: root.sinkMuted
                                            ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.30)
                                            : Theme.accent
                                        Behavior on width {
                                            enabled: !volMa.dragging
                                            SpringAnimation { spring: 3.6; damping: 0.36; epsilon: 0.5 }
                                        }
                                        Behavior on color { ColorAnimation { duration: 180 } }
                                    }
                                }
                                // Knob — rides the fill edge, swells while dragging
                                Rectangle {
                                    width: island.s(14); height: width; radius: width / 2
                                    anchors.verticalCenter: volTrack.verticalCenter
                                    x: Math.max(0, Math.min(volTrack.width - width, volFill.width - width / 2))
                                    color: Qt.rgba(0.97, 0.96, 1.0, 1.0)
                                    visible: !root.sinkMuted
                                    scale: volMa.dragging ? 1.25 : (volMa.containsMouse ? 1.1 : 1.0)
                                    Behavior on scale { SpringAnimation { spring: 4.2; damping: 0.30 } }
                                    Behavior on x {
                                        enabled: !volMa.dragging
                                        SpringAnimation { spring: 3.6; damping: 0.36; epsilon: 0.5 }
                                    }
                                }

                                MouseArea {
                                    id: volMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    property bool dragging: false
                                    onPressed: (m) => { dragging = true; setFromX(m.x) }
                                    onPositionChanged: (m) => { if (dragging) setFromX(m.x) }
                                    onReleased: dragging = false
                                    function setFromX(x) {
                                        const p = Math.round(Math.max(0, Math.min(100, x / width * 100)))
                                        island.currentVol = p
                                        if (root.sinkMuted) {
                                            root.sinkMuted = false
                                            island.exec("pactl set-sink-mute @DEFAULT_SINK@ 0")
                                        }
                                        volThrottle.target = p
                                        if (!volThrottle.running) volThrottle.start()
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        id: micRow
                        anchors { top: volCard.bottom; topMargin: island.s(12); left: parent.left; right: parent.right }
                        height: island.s(38)

                        transform: Translate { y: micRow._ey }
                        property real _ey: 0
                        Connections {
                            target: root
                            function on_OpenChanged() {
                                if (!root._open || Theme.reduceMotion) return
                                micRow._ey = island.s(22)
                                micStagger.restart()
                            }
                        }
                        Timer { id: micStagger; interval: 170; onTriggered: micEntry.restart() }
                        NumberAnimation { id: micEntry; target: micRow; property: "_ey"; to: 0; duration: 600; easing.type: Easing.OutExpo }

                        Rectangle {
                            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                            width: (parent.width - island.s(10)) / 2
                            radius: island.s(10)
                            color: root.micMuted
                                ? Qt.rgba(island.red.r, island.red.g, island.red.b, 0.12)
                                : Qt.rgba(island.surface0.r, island.surface0.g, island.surface0.b, micMa.containsMouse ? 0.85 : 0.70)
                            border.width: 1
                            border.color: root.micMuted
                                ? Qt.rgba(island.red.r, island.red.g, island.red.b, 0.35)
                                : Qt.rgba(island.text.r, island.text.g, island.text.b, micMa.containsMouse ? 0.16 : 0.10)
                            Behavior on color        { ColorAnimation { duration: 180 } }
                            Behavior on border.color { ColorAnimation { duration: 180 } }
                            scale: micMa.pressed ? 0.95 : 1.0
                            Behavior on scale { SpringAnimation { spring: 4.2; damping: 0.32 } }

                            Row {
                                anchors.centerIn: parent
                                spacing: island.s(6)
                                Text {
                                    text: root.micMuted ? "󰍭" : "󰍬"
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: island.s(13)
                                    color: root.micMuted ? island.red : island.subtext0
                                    anchors.verticalCenter: parent.verticalCenter
                                    Behavior on color { ColorAnimation { duration: 180 } }
                                }
                                Text {
                                    text: root.micMuted ? "Mic off" : "Mic on"
                                    font.family: Theme.fontUI
                                    font.pixelSize: island.s(11)
                                    font.weight: Font.Medium
                                    color: root.micMuted ? island.red : island.subtext0
                                    anchors.verticalCenter: parent.verticalCenter
                                    Behavior on color { ColorAnimation { duration: 180 } }
                                }
                            }
                            MouseArea {
                                id: micMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.micMuted = !root.micMuted
                                    island.exec("pactl set-source-mute @DEFAULT_SOURCE@ toggle")
                                }
                            }
                        }

                        Rectangle {
                            anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
                            width: (parent.width - island.s(10)) / 2
                            radius: island.s(10)
                            color: mixerMa.containsMouse
                                ? Qt.rgba(island.surface2.r, island.surface2.g, island.surface2.b, 0.85)
                                : Qt.rgba(island.surface0.r, island.surface0.g, island.surface0.b, 0.70)
                            border.width: 1
                            border.color: mixerMa.containsMouse
                                ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.30)
                                : Qt.rgba(island.text.r, island.text.g, island.text.b, 0.10)
                            Behavior on color        { ColorAnimation { duration: 140 } }
                            Behavior on border.color { ColorAnimation { duration: 140 } }
                            scale: mixerMa.pressed ? 0.95 : 1.0
                            Behavior on scale { SpringAnimation { spring: 4.2; damping: 0.32 } }

                            Row {
                                anchors.centerIn: parent
                                spacing: island.s(6)
                                Text {
                                    text: "󰕾"
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: island.s(12)
                                    color: mixerMa.containsMouse ? island.text : island.subtext0
                                    anchors.verticalCenter: parent.verticalCenter
                                    Behavior on color { ColorAnimation { duration: 140 } }
                                }
                                Text {
                                    text: "Mixer"
                                    font.family: Theme.fontUI
                                    font.pixelSize: island.s(11)
                                    font.weight: Font.Medium
                                    color: mixerMa.containsMouse ? island.text : island.subtext0
                                    anchors.verticalCenter: parent.verticalCenter
                                    Behavior on color { ColorAnimation { duration: 140 } }
                                }
                            }
                            MouseArea {
                                id: mixerMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.detail = "mixer"
                            }
                        }
                    }

                    Item {
                        id: actionsBlock
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                        height: actionsLabel.height + island.s(6) + island.s(58)

                        transform: Translate { y: actionsBlock._ey }
                        property real _ey: 0
                        Connections {
                            target: root
                            function on_OpenChanged() {
                                if (!root._open || Theme.reduceMotion) return
                                actionsBlock._ey = island.s(22)
                                actStagger.restart()
                            }
                        }
                        Timer { id: actStagger; interval: 230; onTriggered: actEntry.restart() }
                        NumberAnimation { id: actEntry; target: actionsBlock; property: "_ey"; to: 0; duration: 600; easing.type: Easing.OutExpo }

                        SectionLabel {
                            id: actionsLabel
                            text: "QUICK ACTIONS"
                            anchors { top: parent.top; left: parent.left; leftMargin: island.s(2) }
                        }

                        Row {
                            anchors { top: actionsLabel.bottom; topMargin: island.s(6); left: parent.left; right: parent.right; bottom: parent.bottom }
                            spacing: island.s(10)
                            readonly property real bw: (width - island.s(30)) / 4

                            QuickAction { width: parent.bw; height: parent.height; icon: "󰸉"; label: "walls";    accent: island.pink
                                onActivated: root.openWidget("wallpaper") }
                            QuickAction { width: parent.bw; height: parent.height; icon: "󰍹"; label: "displays"; accent: island.blue
                                onActivated: root.detail = "display" }
                            QuickAction { width: parent.bw; height: parent.height; icon: "󰌾"; label: "lock";     accent: island.yellow
                                onActivated: { island.expanded = false; island.exec("~/.config/hypr/scripts/lock.sh") } }
                            QuickAction { width: parent.bw; height: parent.height; icon: "󰐥"; label: "power";    accent: island.red
                                onActivated: root.openWidget("powermenu") }
                        }
                    }
                }
            }
        }

        // =================================================================
        // DETAIL PANEL — slides in over the main view
        // =================================================================
        Item {
            id: detailPane
            anchors.fill: parent
            opacity: root.detail !== "" ? 1.0 : 0.0
            visible: opacity > 0.001
            enabled: root.detail !== ""
            Behavior on opacity { NumberAnimation { duration: Theme.reduceMotion ? 0 : 220; easing.type: Easing.OutCubic } }
            property real _tx: root.detail !== "" ? 0 : island.s(56)
            Behavior on _tx { NumberAnimation { duration: Theme.reduceMotion ? 0 : 340; easing.type: Easing.OutExpo } }
            transform: Translate { x: detailPane._tx }

            // Right-click anywhere in the panel goes back
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.RightButton
                onClicked: root.detail = ""
                z: -1
            }

            Item {
                id: detailHeader
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: island.s(26)

                Rectangle {
                    id: backBtn
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    width: island.s(26); height: width; radius: width / 2
                    color: backMa.containsMouse
                        ? Qt.rgba(island.surface2.r, island.surface2.g, island.surface2.b, 0.95)
                        : Qt.rgba(island.surface1.r, island.surface1.g, island.surface1.b, 0.70)
                    Behavior on color { ColorAnimation { duration: 140 } }
                    scale: backMa.pressed ? 0.88 : (backMa.containsMouse ? 1.08 : 1.0)
                    Behavior on scale { SpringAnimation { spring: 4.5; damping: 0.32 } }
                    Text {
                        anchors.centerIn: parent
                        text: "󰅁"
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: island.s(14)
                        color: island.text
                        transform: Translate { x: backMa.containsMouse ? -island.s(1) : 0 }
                    }
                    MouseArea {
                        id: backMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.detail = ""
                    }
                }

                Text {
                    anchors { left: backBtn.right; leftMargin: island.s(10); verticalCenter: parent.verticalCenter }
                    text: root.detail === "network" ? "WI-FI & NETWORKS"
                        : root.detail === "bt"      ? "BLUETOOTH"
                        : root.detail === "display" ? "DISPLAYS"
                        : "AUDIO MIXER"
                    font.family: "JetBrains Mono"
                    font.pixelSize: island.s(9)
                    font.weight: Font.Black
                    font.letterSpacing: island.s(1.4)
                    color: Theme.overlay0
                }

                Rectangle {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    width: island.s(26); height: width; radius: width / 2
                    color: refreshMa.containsMouse
                        ? Qt.rgba(island.surface2.r, island.surface2.g, island.surface2.b, 0.95)
                        : Qt.rgba(island.surface1.r, island.surface1.g, island.surface1.b, 0.70)
                    Behavior on color { ColorAnimation { duration: 140 } }
                    Text {
                        id: refreshIcon
                        anchors.centerIn: parent
                        text: "󰑐"
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: island.s(12)
                        color: island.subtext0
                    }
                    RotationAnimation {
                        id: refreshSpin
                        target: refreshIcon; property: "rotation"
                        from: 0; to: 360; duration: 600
                        easing.type: Easing.OutCubic
                    }
                    MouseArea {
                        id: refreshMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!Theme.reduceMotion) refreshSpin.restart()
                            if (root.detail === "network") {
                                island.exec("nmcli dev wifi rescan")
                                wifiPollSoon.restart()
                                netProc.running = true
                            } else if (root.detail === "bt") {
                                btProc.running = true
                            } else if (root.detail === "mixer") {
                                mixProc.running = true
                            } else if (root.detail === "display") {
                                dispProc.running = true
                            }
                        }
                    }
                }
            }

            Item {
                id: detailBody
                anchors { top: detailHeader.bottom; topMargin: island.s(12); left: parent.left; right: parent.right; bottom: parent.bottom }

                // ── NETWORK: wifi list | wired + vpn ─────────────────────
                Item {
                    anchors.fill: parent
                    visible: root.detail === "network"

                    Item {
                        id: wifiCol
                        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                        width: Math.round(parent.width * 0.52)

                        SectionLabel {
                            id: wifiLbl
                            text: "WI-FI NETWORKS"
                            anchors { top: parent.top; left: parent.left; leftMargin: island.s(2) }
                        }
                        Flickable {
                            anchors { top: wifiLbl.bottom; topMargin: island.s(6); left: parent.left; right: parent.right; bottom: parent.bottom }
                            contentHeight: wifiList.implicitHeight
                            clip: true
                            Column {
                                id: wifiList
                                width: parent.width
                                spacing: island.s(6)
                                Repeater {
                                    model: root.wifiNets
                                    Column {
                                        id: wifiEntry
                                        required property var modelData
                                        required property int index
                                        width: wifiList.width
                                        spacing: island.s(4)

                                        readonly property bool editorOpen: root.pwSsid === modelData.ssid
                                        onEditorOpenChanged: {
                                            if (editorOpen) {
                                                pwInput.text = ""
                                                pwInput.echoMode = TextInput.Password
                                                Qt.callLater(function () { pwInput.forceActiveFocus() })
                                            }
                                        }

                                        DetailRow {
                                            rowIndex: wifiEntry.index
                                            width: parent.width
                                            icon: root.wifiIconFor(wifiEntry.modelData.signal)
                                            label: wifiEntry.modelData.ssid
                                            sub: root.wifiBusySsid === wifiEntry.modelData.ssid ? "connecting…"
                                                : root.wifiFailSsid === wifiEntry.modelData.ssid ? "wrong password"
                                                : wifiEntry.modelData.inUse ? "connected"
                                                : wifiEntry.editorOpen ? "enter password"
                                                : (wifiEntry.modelData.secured ? "󰌾 " + wifiEntry.modelData.signal + "%" : wifiEntry.modelData.signal + "%")
                                            subDanger: root.wifiFailSsid === wifiEntry.modelData.ssid
                                            active: wifiEntry.modelData.inUse || wifiEntry.editorOpen
                                            accent: island.blue
                                            onClicked: {
                                                if (wifiEntry.modelData.inUse || root.wifiBusySsid !== "") return
                                                if (wifiEntry.editorOpen) { root.pwSsid = ""; return }
                                                // Known or open network → connect directly;
                                                // new secured network → inline password editor
                                                if (!wifiEntry.modelData.secured
                                                        || root.knownConns.indexOf(wifiEntry.modelData.ssid) >= 0)
                                                    root.wifiConnect(wifiEntry.modelData.ssid, "")
                                                else
                                                    root.pwSsid = wifiEntry.modelData.ssid
                                            }
                                        }

                                        // Inline password editor
                                        Rectangle {
                                            width: parent.width
                                            height: wifiEntry.editorOpen ? island.s(36) : 0
                                            visible: height > 1
                                            clip: true
                                            radius: island.s(9)
                                            color: Qt.rgba(island.surface0.r, island.surface0.g, island.surface0.b, 0.85)
                                            border.width: 1
                                            border.color: pwInput.activeFocus
                                                ? Qt.rgba(island.blue.r, island.blue.g, island.blue.b, 0.45)
                                                : Qt.rgba(island.text.r, island.text.g, island.text.b, 0.10)
                                            Behavior on height       { NumberAnimation { duration: Theme.reduceMotion ? 0 : 240; easing.type: Easing.OutExpo } }
                                            Behavior on border.color { ColorAnimation { duration: 140 } }

                                            Text {
                                                id: pwLock
                                                anchors { left: parent.left; leftMargin: island.s(10); verticalCenter: parent.verticalCenter }
                                                text: "󰌾"
                                                font.family: "Iosevka Nerd Font"
                                                font.pixelSize: island.s(12)
                                                color: island.blue
                                            }
                                            TextInput {
                                                id: pwInput
                                                anchors { left: pwLock.right; leftMargin: island.s(8); right: pwEye.left; rightMargin: island.s(6); verticalCenter: parent.verticalCenter }
                                                height: parent.height
                                                verticalAlignment: TextInput.AlignVCenter
                                                echoMode: TextInput.Password
                                                passwordCharacter: "•"
                                                font.family: "JetBrains Mono"
                                                font.pixelSize: island.s(11)
                                                color: island.text
                                                selectionColor: Qt.rgba(island.blue.r, island.blue.g, island.blue.b, 0.35)
                                                clip: true
                                                onAccepted: {
                                                    if (text.length > 0)
                                                        root.wifiConnect(wifiEntry.modelData.ssid, text)
                                                }
                                                Keys.onEscapePressed: root.pwSsid = ""

                                                Text {
                                                    visible: pwInput.text.length === 0
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: "password"
                                                    font.family: "JetBrains Mono"
                                                    font.pixelSize: island.s(10)
                                                    color: island.subtext0
                                                }
                                            }
                                            // Show / hide password
                                            Text {
                                                id: pwEye
                                                anchors { right: pwGo.left; rightMargin: island.s(6); verticalCenter: parent.verticalCenter }
                                                text: pwInput.echoMode === TextInput.Password ? "󰈈" : "󰈉"
                                                font.family: "Iosevka Nerd Font"
                                                font.pixelSize: island.s(12)
                                                color: pwEyeMa.containsMouse ? island.text : island.subtext0
                                                Behavior on color { ColorAnimation { duration: 130 } }
                                                MouseArea {
                                                    id: pwEyeMa
                                                    anchors.fill: parent
                                                    anchors.margins: -island.s(5)
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: pwInput.echoMode = pwInput.echoMode === TextInput.Password
                                                        ? TextInput.Normal : TextInput.Password
                                                }
                                            }
                                            // Connect
                                            Rectangle {
                                                id: pwGo
                                                anchors { right: parent.right; rightMargin: island.s(5); verticalCenter: parent.verticalCenter }
                                                width: island.s(26); height: island.s(26); radius: width / 2
                                                readonly property bool ready: pwInput.text.length > 0 && root.wifiBusySsid === ""
                                                color: ready
                                                    ? (pwGoMa.containsMouse
                                                        ? Qt.rgba(island.blue.r, island.blue.g, island.blue.b, 0.90)
                                                        : Qt.rgba(island.blue.r, island.blue.g, island.blue.b, 0.75))
                                                    : Qt.rgba(island.surface1.r, island.surface1.g, island.surface1.b, 0.70)
                                                Behavior on color { ColorAnimation { duration: 140 } }
                                                scale: pwGoMa.pressed ? 0.85 : 1.0
                                                Behavior on scale { SpringAnimation { spring: 4.5; damping: 0.32 } }
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: root.wifiBusySsid !== "" ? "󰑐" : "󰅂"
                                                    font.family: "Iosevka Nerd Font"
                                                    font.pixelSize: island.s(13)
                                                    color: pwGo.ready ? island.base : island.subtext0
                                                }
                                                MouseArea {
                                                    id: pwGoMa
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        if (pwGo.ready)
                                                            root.wifiConnect(wifiEntry.modelData.ssid, pwInput.text)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                Text {
                                    visible: root.wifiNets.length === 0
                                    text: root.wifiOn ? "no networks found" : "wi-fi is off"
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: island.s(9)
                                    color: island.subtext0
                                    padding: island.s(8)
                                }
                            }
                        }
                    }

                    Item {
                        anchors { left: wifiCol.right; leftMargin: island.s(14); right: parent.right; top: parent.top; bottom: parent.bottom }

                        Column {
                            id: netRightCol
                            anchors { top: parent.top; left: parent.left; right: parent.right }
                            spacing: island.s(6)

                            SectionLabel { text: "WIRED"; leftPadding: island.s(2) }
                            Repeater {
                                model: root.ethDevs
                                DetailRow {
                                    required property var modelData
                                    required property int index
                                    rowIndex: index + 1
                                    width: netRightCol.width
                                    icon: "󰈀"
                                    label: modelData.dev
                                    sub: modelData.state.indexOf("connected") === 0 ? "connected" : modelData.state
                                    active: modelData.state.indexOf("connected") === 0
                                    accent: island.green
                                    onClicked: {
                                        island.exec("nmcli device " +
                                            (modelData.state.indexOf("connected") === 0 ? "disconnect " : "connect ") + modelData.dev)
                                        wifiPollSoon.restart()
                                    }
                                }
                            }
                            Text {
                                visible: root.ethDevs.length === 0
                                text: "no wired devices"
                                font.family: "JetBrains Mono"
                                font.pixelSize: island.s(9)
                                color: island.subtext0
                                leftPadding: island.s(8)
                            }

                            Item { width: 1; height: island.s(6) }

                            SectionLabel { text: "VPN"; leftPadding: island.s(2) }
                            Repeater {
                                model: root.vpnConns
                                DetailRow {
                                    required property var modelData
                                    required property int index
                                    rowIndex: index + 3
                                    width: netRightCol.width
                                    icon: "󰖂"
                                    label: modelData.name
                                    sub: modelData.external
                                        ? (modelData.active ? "active · external" : "down · external")
                                        : (modelData.active ? "active" : "tap to connect")
                                    active: modelData.active
                                    accent: island.green
                                    onClicked: {
                                        if (modelData.external) return
                                        island.exec("nmcli connection " + (modelData.active ? "down '" : "up '") + modelData.name + "'")
                                        wifiPollSoon.restart()
                                    }
                                }
                            }
                            Text {
                                visible: root.vpnConns.length === 0
                                text: "no vpn profiles"
                                font.family: "JetBrains Mono"
                                font.pixelSize: island.s(9)
                                color: island.subtext0
                                leftPadding: island.s(8)
                            }
                        }

                    }
                }

                // ── BLUETOOTH: paired devices ────────────────────────────
                Item {
                    anchors.fill: parent
                    visible: root.detail === "bt"

                    SectionLabel {
                        id: btLbl
                        text: root.btOn ? "PAIRED DEVICES" : "PAIRED DEVICES — BLUETOOTH IS OFF"
                        anchors { top: parent.top; left: parent.left; leftMargin: island.s(2) }
                    }
                    Flickable {
                        anchors { top: btLbl.bottom; topMargin: island.s(6); left: parent.left; right: parent.right; bottom: parent.bottom }
                        contentHeight: btList.implicitHeight
                        clip: true
                        Column {
                            id: btList
                            width: parent.width
                            spacing: island.s(6)
                            Repeater {
                                model: root.btDevs
                                DetailRow {
                                    required property var modelData
                                    required property int index
                                    rowIndex: index
                                    width: btList.width
                                    icon: modelData.connected ? "󰂱" : "󰂯"
                                    label: modelData.name
                                    sub: modelData.connected ? "connected — tap to disconnect" : "tap to connect"
                                    active: modelData.connected
                                    accent: island.teal
                                    onClicked: {
                                        island.exec("timeout 10 bluetoothctl " +
                                            (modelData.connected ? "disconnect " : "connect ") + modelData.mac)
                                        btPollSoon.restart()
                                    }
                                }
                            }
                            Text {
                                visible: root.btDevs.length === 0
                                text: root.btOn ? "no paired devices — pair via bluetoothctl" : "turn bluetooth on to see devices"
                                font.family: "JetBrains Mono"
                                font.pixelSize: island.s(9)
                                color: island.subtext0
                                padding: island.s(8)
                            }
                        }
                    }
                }

                // ── MIXER: output devices | app streams ──────────────────
                Item {
                    anchors.fill: parent
                    visible: root.detail === "mixer"

                    Item {
                        id: sinkCol
                        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                        width: Math.round(parent.width * 0.46)

                        SectionLabel {
                            id: sinkLbl
                            text: "OUTPUT DEVICE"
                            anchors { top: parent.top; left: parent.left; leftMargin: island.s(2) }
                        }
                        Flickable {
                            anchors { top: sinkLbl.bottom; topMargin: island.s(6); left: parent.left; right: parent.right; bottom: parent.bottom }
                            contentHeight: sinkList.implicitHeight
                            clip: true
                            Column {
                                id: sinkList
                                width: parent.width
                                spacing: island.s(6)
                                Repeater {
                                    model: root.sinks
                                    DetailRow {
                                        required property var modelData
                                        required property int index
                                        rowIndex: index
                                        width: sinkList.width
                                        icon: modelData.isDefault ? "󰄬" : "󰕾"
                                        label: modelData.desc
                                        sub: modelData.muted ? "muted" : modelData.vol + "%"
                                        active: modelData.isDefault
                                        accent: Theme.accent
                                        onClicked: {
                                            if (modelData.isDefault) return
                                            island.exec("pactl set-default-sink '" + modelData.name + "'")
                                            mixPollSoon.restart()
                                        }
                                    }
                                }
                                Text {
                                    visible: root.sinks.length === 0
                                    text: "no output devices"
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: island.s(9)
                                    color: island.subtext0
                                    padding: island.s(8)
                                }
                            }
                        }
                    }

                    Item {
                        anchors { left: sinkCol.right; leftMargin: island.s(14); right: parent.right; top: parent.top; bottom: parent.bottom }

                        SectionLabel {
                            id: appLbl
                            text: "APPLICATIONS"
                            anchors { top: parent.top; left: parent.left; leftMargin: island.s(2) }
                        }
                        Flickable {
                            anchors { top: appLbl.bottom; topMargin: island.s(6); left: parent.left; right: parent.right; bottom: parent.bottom }
                            contentHeight: appList.implicitHeight
                            clip: true
                            Column {
                                id: appList
                                width: parent.width
                                spacing: island.s(6)
                                Repeater {
                                    model: root.apps
                                    AppVolRow {
                                        required property var modelData
                                        required property int index
                                        rowIndex: index
                                        width: appList.width
                                        appIdx: modelData.idx
                                        label: modelData.name
                                        vol: modelData.vol
                                        muted: modelData.muted
                                    }
                                }
                                Text {
                                    visible: root.apps.length === 0
                                    text: "nothing is playing"
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: island.s(9)
                                    color: island.subtext0
                                    padding: island.s(8)
                                }
                            }
                        }
                    }
                }

                // ── DISPLAYS: resolutions | rates + scale ────────────────
                Item {
                    id: dispPanel
                    anchors.fill: parent
                    visible: root.detail === "display"

                    readonly property var curMon: root.mons.length > root.monSel ? root.mons[root.monSel] : null

                    // Monitor picker (only when several)
                    Row {
                        id: monPicker
                        visible: root.mons.length > 1
                        height: visible ? island.s(26) : 0
                        spacing: island.s(6)
                        Repeater {
                            model: root.mons
                            Rectangle {
                                required property var modelData
                                required property int index
                                width: monPickText.implicitWidth + island.s(20)
                                height: island.s(24)
                                radius: island.s(8)
                                color: root.monSel === index
                                    ? Qt.rgba(island.blue.r, island.blue.g, island.blue.b, 0.14)
                                    : Qt.rgba(island.surface0.r, island.surface0.g, island.surface0.b, 0.60)
                                border.width: 1
                                border.color: root.monSel === index
                                    ? Qt.rgba(island.blue.r, island.blue.g, island.blue.b, 0.35)
                                    : Qt.rgba(island.text.r, island.text.g, island.text.b, 0.08)
                                Behavior on color        { ColorAnimation { duration: 140 } }
                                Behavior on border.color { ColorAnimation { duration: 140 } }
                                Text {
                                    id: monPickText
                                    anchors.centerIn: parent
                                    text: modelData.name
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: island.s(9)
                                    font.weight: Font.Bold
                                    color: root.monSel === index ? island.blue : island.subtext0
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.monSel = index
                                        const m = root.mons[index]
                                        root.dispRes = m.w + "x" + m.h
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        anchors { top: monPicker.bottom; topMargin: root.mons.length > 1 ? island.s(8) : 0; left: parent.left; right: parent.right; bottom: parent.bottom }

                        Item {
                            id: resCol
                            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                            width: Math.round(parent.width * 0.44)

                            SectionLabel {
                                id: resLbl
                                text: "RESOLUTION"
                                anchors { top: parent.top; left: parent.left; leftMargin: island.s(2) }
                            }
                            Flickable {
                                anchors { top: resLbl.bottom; topMargin: island.s(6); left: parent.left; right: parent.right; bottom: parent.bottom; bottomMargin: island.s(16) }
                                contentHeight: resList.implicitHeight
                                clip: true
                                Column {
                                    id: resList
                                    width: parent.width
                                    spacing: island.s(6)
                                    Repeater {
                                        model: root.resListFor(dispPanel.curMon)
                                        DetailRow {
                                            required property var modelData
                                            required property int index
                                            rowIndex: index
                                            width: resList.width
                                            readonly property var mon: root.mons.length > root.monSel ? root.mons[root.monSel] : null
                                            icon: "󰍹"
                                            label: modelData.key
                                            sub: mon && mon.w === modelData.w && mon.h === modelData.h ? "current" : ""
                                            active: root.dispRes === modelData.key
                                            accent: island.blue
                                            onClicked: root.dispRes = modelData.key
                                        }
                                    }
                                    Text {
                                        visible: root.mons.length === 0
                                        text: "no monitor data"
                                        font.family: "JetBrains Mono"
                                        font.pixelSize: island.s(9)
                                        color: island.subtext0
                                        padding: island.s(8)
                                    }
                                }
                            }
                        }

                        Item {
                            id: rateCol
                            anchors { left: resCol.right; leftMargin: island.s(14); right: parent.right; top: parent.top; bottom: parent.bottom }

                            readonly property var mon: root.mons.length > root.monSel ? root.mons[root.monSel] : null

                            SectionLabel {
                                id: rateLbl
                                text: "REFRESH RATE"
                                anchors { top: parent.top; left: parent.left; leftMargin: island.s(2) }
                            }
                            Flickable {
                                anchors { top: rateLbl.bottom; topMargin: island.s(6); left: parent.left; right: parent.right; bottom: scaleBlock.top; bottomMargin: island.s(10) }
                                contentHeight: rateList.implicitHeight
                                clip: true
                                Column {
                                    id: rateList
                                    width: parent.width
                                    spacing: island.s(6)
                                    Repeater {
                                        model: root.ratesFor(rateCol.mon, root.dispRes)
                                        DetailRow {
                                            required property var modelData
                                            required property int index
                                            rowIndex: index
                                            width: rateList.width
                                            readonly property bool isCurrent: rateCol.mon
                                                && rateCol.mon.w + "x" + rateCol.mon.h === root.dispRes
                                                && Math.abs(rateCol.mon.rate - modelData) < 0.6
                                            icon: "󰓅"
                                            label: modelData.toFixed(2) + " Hz"
                                            sub: isCurrent ? "current" : "tap to apply"
                                            active: isCurrent
                                            accent: island.green
                                            onClicked: {
                                                if (isCurrent || !rateCol.mon) return
                                                const parts = root.dispRes.split("x")
                                                root.applyMonitor(rateCol.mon, parseInt(parts[0]), parseInt(parts[1]), modelData, rateCol.mon.scale)
                                            }
                                        }
                                    }
                                }
                            }

                            // Scale stepper + info
                            Item {
                                id: scaleBlock
                                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                                height: island.s(56)

                                SectionLabel {
                                    id: scaleLbl
                                    text: "SCALE"
                                    anchors { top: parent.top; left: parent.left; leftMargin: island.s(2) }
                                }
                                Rectangle {
                                    anchors { top: scaleLbl.bottom; topMargin: island.s(6); left: parent.left; right: parent.right; bottom: parent.bottom }
                                    radius: island.s(9)
                                    color: Qt.rgba(island.surface0.r, island.surface0.g, island.surface0.b, 0.55)
                                    border.width: 1
                                    border.color: Qt.rgba(island.text.r, island.text.g, island.text.b, 0.07)

                                    Rectangle {
                                        id: scaleMinus
                                        anchors { left: parent.left; leftMargin: island.s(6); verticalCenter: parent.verticalCenter }
                                        width: island.s(24); height: width; radius: width / 2
                                        color: minusMa.containsMouse
                                            ? Qt.rgba(island.surface2.r, island.surface2.g, island.surface2.b, 0.95)
                                            : Qt.rgba(island.surface1.r, island.surface1.g, island.surface1.b, 0.70)
                                        Behavior on color { ColorAnimation { duration: 130 } }
                                        scale: minusMa.pressed ? 0.85 : 1.0
                                        Behavior on scale { SpringAnimation { spring: 4.5; damping: 0.32 } }
                                        Text { anchors.centerIn: parent; text: "󰍴"; font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(12); color: island.text }
                                        MouseArea {
                                            id: minusMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                const m = rateCol.mon
                                                if (!m) return
                                                const ns = Math.max(0.5, Math.round((m.scale - 0.25) * 100) / 100)
                                                root.applyMonitor(m, m.w, m.h, m.rate, ns)
                                            }
                                        }
                                    }
                                    Text {
                                        anchors.centerIn: parent
                                        text: rateCol.mon ? rateCol.mon.scale.toFixed(2) + "×" : "—"
                                        font.family: "JetBrains Mono"
                                        font.pixelSize: island.s(12)
                                        font.weight: Font.Black
                                        color: island.text
                                    }
                                    Rectangle {
                                        anchors { right: parent.right; rightMargin: island.s(6); verticalCenter: parent.verticalCenter }
                                        width: island.s(24); height: width; radius: width / 2
                                        color: plusMa.containsMouse
                                            ? Qt.rgba(island.surface2.r, island.surface2.g, island.surface2.b, 0.95)
                                            : Qt.rgba(island.surface1.r, island.surface1.g, island.surface1.b, 0.70)
                                        Behavior on color { ColorAnimation { duration: 130 } }
                                        scale: plusMa.pressed ? 0.85 : 1.0
                                        Behavior on scale { SpringAnimation { spring: 4.5; damping: 0.32 } }
                                        Text { anchors.centerIn: parent; text: "󰐕"; font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(12); color: island.text }
                                        MouseArea {
                                            id: plusMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                const m = rateCol.mon
                                                if (!m) return
                                                const ns = Math.min(3.0, Math.round((m.scale + 0.25) * 100) / 100)
                                                root.applyMonitor(m, m.w, m.h, m.rate, ns)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Multi-monitor arrangement stays in the full overlay
                    Text {
                        anchors { bottom: parent.bottom; left: parent.left; leftMargin: island.s(2) }
                        text: (parent.curMon ? parent.curMon.name + (parent.curMon.model ? " · " + parent.curMon.model : "") + "   " : "")
                        font.family: "JetBrains Mono"
                        font.pixelSize: island.s(8)
                        color: island.subtext0
                        width: parent.width * 0.44
                        elide: Text.ElideRight
                    }
                    Text {
                        visible: root.mons.length > 1
                        anchors { bottom: parent.bottom; right: parent.right }
                        text: "arrange layout 󰅂"
                        font.family: "JetBrains Mono"
                        font.pixelSize: island.s(9)
                        color: arrMa.containsMouse ? Theme.accent : island.subtext0
                        Behavior on color { ColorAnimation { duration: 140 } }
                        MouseArea {
                            id: arrMa
                            anchors.fill: parent
                            anchors.margins: -island.s(6)
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.openWidget("monitors")
                        }
                    }
                }
            }
        }
    }
}
