import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "./themes"

PanelWindow {
    id: launcherRoot

    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.anchors.top:    true
    WlrLayershell.anchors.bottom: true
    WlrLayershell.anchors.left:   true
    WlrLayershell.anchors.right:  true

    color: "transparent"
    visible: _showing

    MatugenColors { id: theme }
    Scaler        { id: scaler; currentWidth: Screen.width }
    function s(v) { return scaler.s(v) }

    // ─── State ───────────────────────────────────────────────────────────────

    property bool open:            false
    property bool _showing:        false
    property bool webSearchSelected: false

    Timer {
        id: hideTimer; interval: 600
        onTriggered: launcherRoot._showing = false
    }

    // Tell island to hide (1) or show (0) — two static processes, no binding issues
    Process { id: islandHideProc; command: ["bash", "-c", "echo 1 > /tmp/qs_launcher_state"] }
    Process { id: islandShowProc; command: ["bash", "-c", "echo 0 > /tmp/qs_launcher_state"] }

    // On startup ensure island is visible (clears any stale state from previous session)
    Component.onCompleted: { islandShowProc.running = true }

    onOpenChanged: {
        if (open) {
            hideTimer.stop()
            _showing = true
            islandHideProc.running = false
            islandHideProc.running = true
            searchInput.text = ""
            filterApps("")
            appsProc.running = false
            appsProc.running = true
            Qt.callLater(function() { searchInput.forceActiveFocus() })
        } else {
            hideTimer.restart()
            islandShowProc.running = false
            islandShowProc.running = true
        }
    }

    // ─── App data ─────────────────────────────────────────────────────────────

    ListModel { id: allAppsModel }
    ListModel { id: filteredModel }

    function fuzzyScore(name, query) {
        let n = name.toLowerCase(), q = query.toLowerCase()
        if (n === q)          return 4
        if (n.startsWith(q))  return 3
        if (n.includes(q))    return 2
        let qi = 0
        for (let i = 0; i < n.length && qi < q.length; i++)
            if (n[i] === q[qi]) qi++
        return qi === q.length ? 1 : 0
    }

    function openWebSearch() {
        let q = searchInput.text.trim()
        if (!q) return
        webSearchProc.searchQuery = q
        webSearchProc.running = false
        webSearchProc.running = true
        open = false
    }

    function filterApps(query) {
        webSearchSelected = false
        filteredModel.clear()
        let q = query.trim()
        if (!q) {
            for (let i = 0; i < allAppsModel.count; i++) {
                let a = allAppsModel.get(i)
                filteredModel.append({ name: a.name, exec: a.exec, icon: a.icon, desktop: a.desktop })
            }
        } else {
            let scored = []
            for (let i = 0; i < allAppsModel.count; i++) {
                let a = allAppsModel.get(i)
                let sc = fuzzyScore(a.name, q)
                if (sc > 0) scored.push({ sc, a })
            }
            scored.sort((x, y) => y.sc - x.sc || x.a.name.localeCompare(y.a.name))
            for (let i = 0; i < scored.length; i++) {
                let a = scored[i].a
                filteredModel.append({ name: a.name, exec: a.exec, icon: a.icon, desktop: a.desktop })
            }
        }
        appList.currentIndex = 0
    }

    function launchApp(idx) {
        if (idx < 0 || idx >= filteredModel.count) return
        let a = filteredModel.get(idx)
        launchProc.launchCmd = a.exec
        launchProc.running   = false
        launchProc.running   = true
        // Tell the float dock a window is coming (pending bounce icon).
        // desktop stem ≈ expected window class; the dock matches it fuzzily.
        pendingNotifyProc.payload = JSON.stringify({
            cls: a.desktop || a.name, icon: a.icon || "", ts: Date.now()
        })
        pendingNotifyProc.running = false
        pendingNotifyProc.running = true
        open = false
    }

    // Writes pending-launch info for FloatDock. Guarded by the float mode flag —
    // outside float mode there is no dock to consume (and rm) the file.
    Process {
        id: pendingNotifyProc
        property string payload: ""
        command: ["bash", "-c",
            "[ -f /tmp/qs_float_mode ] || exit 0; printf '%s' \"$1\" > /tmp/qs_dock_pending",
            "qs", payload]
    }

    Process {
        id: appsProc
        command: ["bash", "-c", "bash $HOME/.config/hypr/scripts/get_apps.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                allAppsModel.clear()
                let lines = this.text.trim().split("\n")
                for (let i = 0; i < lines.length; i++) {
                    let p = lines[i].split("|")
                    if (p.length >= 2 && p[0])
                        allAppsModel.append({ name: p[0], exec: p[1], icon: p[2] || "", desktop: p[3] || "" })
                }
                filterApps(searchInput.text)
            }
        }
    }

    Process {
        id: launchProc
        property string launchCmd: ""
        command: ["bash", "-c", "nohup sh -c " + JSON.stringify(launchCmd) + " >/dev/null 2>&1 &"]
    }

    Process {
        id: webSearchProc
        property string searchQuery: ""
        command: ["bash", "-c",
            "xdg-open $(python3 -c 'import sys,urllib.parse;print(\"https://www.google.com/search?q=\"+urllib.parse.quote(sys.argv[1]))' " +
            JSON.stringify(searchQuery) + ") >/dev/null 2>&1 &"
        ]
    }

    // ─── IPC ──────────────────────────────────────────────────────────────────

    Process {
        id: ipcWatcher; running: true
        command: ["bash", "-c",
            "inotifywait -qq -e close_write,moved_to --include 'qs_launcher$' /tmp/ 2>/dev/null; " +
            "[ -f /tmp/qs_launcher ] && cat /tmp/qs_launcher && rm -f /tmp/qs_launcher"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                let cmd = this.text.trim()
                if      (cmd === "open")   launcherRoot.open = true
                else if (cmd === "close")  launcherRoot.open = false
                else if (cmd === "toggle") launcherRoot.open = !launcherRoot.open
                ipcWatcher.running = false
                ipcWatcher.running = true
            }
        }
    }

    // ─── UI ───────────────────────────────────────────────────────────────────

    // Dim — fades in behind the card. Light themes use a softer black scrim
    // so the wallpaper still reads through; dark themes can afford more.
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, launcherRoot.open ? (Theme.isLight ? 0.20 : 0.30) : 0)
        Behavior on color { ColorAnimation { duration: 380 } }
        visible: color.a > 0.001
        MouseArea { anchors.fill: parent; onClicked: launcherRoot.open = false }
    }

    // ── Launcher card ────────────────────────────────────────────────────────
    // Starts at island position (top-center, y=8) and morphs to screen center.

    // Drop shadow layer (rendered behind card)
    MultiEffect {
        source: card
        anchors.fill: card
        shadowEnabled: true
        shadowColor: Theme.shadowColor
        blurMax: Theme.elev3Max
        shadowBlur: 1.0
        shadowOpacity: Theme.elev3Op
        shadowVerticalOffset: Theme.elev3Off
        shadowHorizontalOffset: 0
        z: card.z - 1
        opacity: launcherRoot.open ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    }

    Rectangle {
        id: card

        // Final open height (used to compute target y before animation ends)
        property int openH: s(70) + (searchInput.text.length > 0 ? s(54) : 0) + Math.min(filteredModel.count, 9) * s(54)

        width:  launcherRoot.open ? s(660) : s(230)
        height: launcherRoot.open ? openH  : s(40)
        radius: launcherRoot.open ? s(24)  : s(20)

        // Horizontal: always centered (mirrors island x = (Screen.width - width) / 2)
        x: Math.round((parent.width - width) / 2)
        // Vertical: island top position → screen center
        y: launcherRoot.open ? Math.round((parent.height - openH) / 2) : s(8)

        Behavior on width  { NumberAnimation { duration: 360; easing.type: Easing.OutExpo } }
        Behavior on height { NumberAnimation { duration: 360; easing.type: Easing.OutExpo } }
        Behavior on radius { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on y      { NumberAnimation { duration: 360; easing.type: Easing.OutExpo } }

        opacity: launcherRoot.open ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        color: Qt.rgba(theme.base.r, theme.base.g, theme.base.b, 0.97)

        Rectangle {
            anchors.fill: parent; radius: parent.radius; color: "transparent"
            border.width: 1; border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.35)
        }

        // Content fades in after card expands
        Item {
            anchors { fill: parent; margins: s(16); topMargin: s(14) }
            opacity: launcherRoot.open ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 180 } }
            clip: true

            Column {
                width: parent.width
                spacing: 0

                // ── Search bar ───────────────────────────────────────────────
                Row {
                    width: parent.width; height: s(40)
                    spacing: s(10)

                    Text {
                        text: ""; font.family: "Iosevka Nerd Font"; font.pixelSize: s(20)
                        color: theme.subtext0; anchors.verticalCenter: parent.verticalCenter
                    }

                    Item {
                        width: parent.width - s(30) - s(10); height: parent.height

                        Text {
                            visible: searchInput.text.length === 0
                            text: "Search apps or web..."
                            font.family: "Ubuntu"; font.pixelSize: s(15)
                            color: Qt.rgba(theme.subtext0.r, theme.subtext0.g, theme.subtext0.b, 0.7)
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        TextInput {
                            id: searchInput
                            anchors.fill: parent
                            font.family: "Ubuntu"; font.pixelSize: s(15); font.weight: Font.Bold
                            color: theme.text
                            verticalAlignment: TextInput.AlignVCenter
                            selectionColor: Qt.rgba(theme.mauve.r, theme.mauve.g, theme.mauve.b, 0.35)

                            onTextChanged: launcherRoot.filterApps(text)

                            Keys.onUpPressed: function(event) {
                                if (webSearchSelected) {
                                    webSearchSelected = false
                                    if (filteredModel.count > 0) appList.currentIndex = filteredModel.count - 1
                                } else {
                                    appList.decrementCurrentIndex()
                                }
                                event.accepted = true
                            }
                            Keys.onDownPressed: function(event) {
                                if (!webSearchSelected && searchInput.text.length > 0 &&
                                        (filteredModel.count === 0 || appList.currentIndex >= filteredModel.count - 1)) {
                                    webSearchSelected = true
                                } else if (!webSearchSelected) {
                                    appList.incrementCurrentIndex()
                                }
                                event.accepted = true
                            }
                            Keys.onReturnPressed: function(event) {
                                if (webSearchSelected || (filteredModel.count === 0 && searchInput.text.length > 0)) {
                                    launcherRoot.openWebSearch()
                                } else {
                                    launcherRoot.launchApp(appList.currentIndex)
                                }
                                event.accepted = true
                            }
                            Keys.onEscapePressed: function(event) { launcherRoot.open = false; event.accepted = true }
                        }
                    }
                }

                // Divider
                Rectangle {
                    width: parent.width; height: 1
                    color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.35)
                }

                // ── Results list ─────────────────────────────────────────────
                ListView {
                    id: appList
                    width: parent.width
                    height: Math.min(filteredModel.count, 9) * s(54)
                    clip: true
                    model: filteredModel
                    currentIndex: 0
                    boundsBehavior: Flickable.StopAtBounds
                    Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                    // Ensure keyboard nav keeps selected item visible
                    onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                    delegate: Rectangle {
                        width: appList.width; height: s(54)
                        radius: s(12)
                        color: appList.currentIndex === index
                            ? Qt.rgba(theme.surface0.r, theme.surface0.g, theme.surface0.b, 0.85)
                            : "transparent"
                        Behavior on color { ColorAnimation { duration: 100 } }

                        Row {
                            anchors { left: parent.left; right: parent.right; margins: s(10); verticalCenter: parent.verticalCenter }
                            spacing: s(10)

                            // Icon with letter fallback
                            Item {
                                width: s(32); height: s(32); anchors.verticalCenter: parent.verticalCenter

                                Image {
                                    id: appIcon; anchors.fill: parent
                                    source: model.icon ? "file://" + model.icon : ""
                                    fillMode: Image.PreserveAspectFit; asynchronous: true; smooth: true
                                }
                                Rectangle {
                                    visible: appIcon.status !== Image.Ready
                                    anchors.fill: parent; radius: s(8)
                                    color: Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.7)
                                    Text {
                                        anchors.centerIn: parent
                                        text: model.name.charAt(0).toUpperCase()
                                        font.family: "Ubuntu"; font.pixelSize: s(14); font.weight: Font.Black
                                        color: theme.subtext0
                                    }
                                }
                            }

                            Text {
                                width: parent.width - s(32) - s(10)
                                anchors.verticalCenter: parent.verticalCenter
                                text: model.name
                                font.family: "Ubuntu"; font.pixelSize: s(14); font.weight: Font.DemiBold
                                color: appList.currentIndex === index ? theme.text : theme.subtext0
                                elide: Text.ElideRight
                                Behavior on color { ColorAnimation { duration: 100 } }
                            }
                        }

                        MouseArea {
                            id: rowHover; anchors.fill: parent
                            onClicked: launcherRoot.launchApp(index)
                        }
                    }
                }

                // ── Web search row ───────────────────────────────────────────
                Rectangle {
                    visible: searchInput.text.length > 0
                    width: parent.width; height: s(54)
                    radius: s(12)
                    color: webSearchSelected
                        ? Qt.rgba(theme.surface0.r, theme.surface0.g, theme.surface0.b, 0.85)
                        : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }

                    Rectangle {
                        visible: filteredModel.count > 0
                        anchors { top: parent.top; left: parent.left; right: parent.right }
                        height: 1
                        color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.2)
                    }

                    Row {
                        anchors { left: parent.left; right: parent.right; margins: s(10); verticalCenter: parent.verticalCenter }
                        spacing: s(10)

                        Text {
                            text: "󰖟"; font.family: "Iosevka Nerd Font"; font.pixelSize: s(20)
                            color: webSearchSelected ? theme.mauve : theme.subtext0
                            anchors.verticalCenter: parent.verticalCenter
                            Behavior on color { ColorAnimation { duration: 100 } }
                        }

                        Text {
                            width: parent.width - s(32) - s(10)
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Search web for \"" + searchInput.text + "\""
                            font.family: "Ubuntu"; font.pixelSize: s(14); font.weight: Font.DemiBold
                            color: webSearchSelected ? theme.text : theme.subtext0
                            elide: Text.ElideRight
                            Behavior on color { ColorAnimation { duration: 100 } }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: launcherRoot.openWebSearch()
                        onEntered: launcherRoot.webSearchSelected = true
                        onExited:  launcherRoot.webSearchSelected = false
                    }
                }
            }
        }
    }
}
