import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../themes"
import "../plugins"

// AppletPickerPage — shown inside the island on double-tap.
// Lets the user add/remove topbar applets and exit edit mode.
//
// island.barLeftOrder / island.barRightOrder hold the live orders
// (mirrored from TopBar via IPC file + watcher).
// Changes are pushed back via /tmp/qs_bar_cmd.

Item {
    id: root
    property var island

    // ── Read current applet orders from TopBar's persisted file ────────
    property var leftOrder:  []
    property var rightOrder: []
    property bool _ordersLoaded: false

    readonly property string currentTheme: Theme.themeId

    ThemeRegistry { id: themeRegistry }

    // Built-in applets (must match BarZone.appletDefs)
    readonly property var _builtinRegistry: [
        { id: "help",    label: "Help",        icon: "󰋗" },
        { id: "ws",      label: "Workspaces",  icon: "󰕰" },
        { id: "kb",      label: "Keyboard",    icon: "󰌌" },
        { id: "wifi",    label: "Network",     icon: "󰤨" },
        { id: "bt",      label: "Bluetooth",   icon: "󰂱" },
        { id: "battery", label: "Battery",     icon: "󰁹" },
        { id: "tray",    label: "System Tray", icon: "󱒔" },
        { id: "spacer",    label: "Spacer",      icon: "󱐋" },
        { id: "separator", label: "Separator",   icon: "│" },
    ]

    // Full registry: built-ins + installed plugins
    readonly property var registry: {
        let pluginEntries = PluginLoader.plugins.map(p => ({
            id:    "plugin-" + p.id,
            label: p.name,
            icon:  "󰐱"
        }))
        return _builtinRegistry.concat(pluginEntries)
    }

    function allPlaced() { return leftOrder.concat(rightOrder) }

    // Theme.themeId reflects current settings via the singleton's watcher;
    // writing back to settings.json triggers Theme to re-read.
    function setTheme(id) {
        Quickshell.execDetached(["bash", "-c",
            "jq --arg t \"$1\" '.topbarTheme = $t' ~/.config/hypr/settings.json " +
            "> /tmp/qs_settings_tmp.json && mv /tmp/qs_settings_tmp.json ~/.config/hypr/settings.json",
            "qs_theme", id
        ])
    }

    // Load current layout from file. Re-runs on file change so the picker's
    // placed-state stays in sync with drag reorders happening in the bar.
    Process {
        id: layoutReader; running: true
        command: ["bash", "-c", "cat ~/.cache/quickshell/topbar_layout.json 2>/dev/null || echo '{}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let d = JSON.parse(this.text.trim())
                    root.leftOrder  = (d.left  && Array.isArray(d.left))  ? d.left  : []
                    root.rightOrder = (d.right && Array.isArray(d.right)) ? d.right : []
                    root._ordersLoaded = true
                } catch(e) { root._ordersLoaded = true }
            }
        }
    }

    Process {
        id: layoutWatcher
        running: true
        command: ["bash", "-c",
            "F=~/.cache/quickshell/topbar_layout.json; " +
            "while [ ! -f \"$F\" ]; do sleep 1; done; " +
            "inotifywait -qq -e close_write,modify,moved_to \"$F\" 2>/dev/null"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                layoutReader.running = false
                layoutReader.running = true
                layoutWatcher.running = false
                layoutWatcher.running = true
            }
        }
    }

    // Mutate the persisted layout via jq so we always operate on the latest
    // state — bar drag reorders during the picker session would otherwise be
    // overwritten by stale local copies on next add.
    function mutateLayout(jqExpr, idArg) {
        Quickshell.execDetached(["bash", "-c",
            "F=~/.cache/quickshell/topbar_layout.json; " +
            "mkdir -p ~/.cache/quickshell; " +
            "[ -f \"$F\" ] || printf '{\"left\":[],\"right\":[]}' > \"$F\"; " +
            "jq --arg id \"$1\" '" + jqExpr + "' \"$F\" > \"$F.tmp\" && mv \"$F.tmp\" \"$F\"; " +
            "printf 1 > /tmp/qs_bar_reload",
            "qs_picker", idArg
        ])
    }

    function addApplet(id) {
        // Spacers / separators can repeat — generate a unique id each time.
        // Other applets are deduped: noop if already placed on either side.
        if (id === "spacer" || id === "separator") {
            let unique = id + "-" + Date.now()
            root.mutateLayout(
                ".right = ((.right // []) + [$id])",
                unique
            )
        } else {
            root.mutateLayout(
                "if ((.left // []) + (.right // []) | index($id)) then . " +
                "else .right = ((.right // []) + [$id]) end",
                id
            )
        }
    }

    function removeApplet(id) {
        root.mutateLayout(
            ".left = ((.left // []) | map(select(. != $id))) | " +
            ".right = ((.right // []) | map(select(. != $id)))",
            id
        )
    }

    // ── UI ─────────────────────────────────────────────────────────────
    anchors.fill: parent
    anchors.margins: island.s(18)
    anchors.bottomMargin: island.s(60)  // leave room for nav bar

    // Fixed header — never scrolls
    RowLayout {
        id: header
        anchors { top: parent.top; left: parent.left; right: parent.right }
        spacing: island.s(8)

        Text {
            text: "Bar Applets"
            font.family: "JetBrains Mono"
            font.pixelSize: island.s(16)
            font.weight: Font.Bold
            color: island.text
            Layout.fillWidth: true
        }

        // Collapse — keeps edit mode active, just hides the picker.
        Rectangle {
            width: island.s(32); height: island.s(32)
            radius: island.s(10)
            color: collapseMouse.containsMouse
                ? Qt.rgba(island.subtext0.r, island.subtext0.g, island.subtext0.b, 0.18)
                : Qt.rgba(island.surface1.r,  island.surface1.g,  island.surface1.b,  0.5)
            Behavior on color { ColorAnimation { duration: 150 } }
            Text {
                anchors.centerIn: parent
                text: "▴"
                font.family: "JetBrains Mono"; font.pixelSize: island.s(16); font.weight: Font.Black
                color: island.mauve
            }
            MouseArea { id: collapseMouse; anchors.fill: parent; hoverEnabled: true; onClicked: island.expanded = false }
        }

        Rectangle {
            width: doneText.implicitWidth + island.s(24); height: island.s(32)
            radius: island.s(10)
            color: doneMouse.containsMouse
                ? Qt.rgba(island.mauve.r, island.mauve.g, island.mauve.b, 0.25)
                : Qt.rgba(island.surface1.r, island.surface1.g, island.surface1.b, 0.5)
            Behavior on color { ColorAnimation { duration: 150 } }
            Text {
                id: doneText; anchors.centerIn: parent; text: "Done"
                font.family: "JetBrains Mono"; font.pixelSize: island.s(13); font.weight: Font.Bold
                color: island.mauve
            }
            MouseArea { id: doneMouse; anchors.fill: parent; hoverEnabled: true; onClicked: island.exitEditBarMode() }
        }
    }

    // ── Scrollable body ────────────────────────────────────────────────
    Item {
        id: scrollArea
        anchors {
            top: header.bottom; topMargin: island.s(12)
            left: parent.left; right: parent.right; bottom: parent.bottom
        }
        clip: true

        readonly property bool _scrollVisible: flick.contentHeight > flick.height + 2
        property real _scrollOpacity: 0

        Flickable {
            id: flick
            anchors { fill: parent; rightMargin: scrollArea._scrollVisible ? island.s(10) : 0 }
            contentWidth: width
            contentHeight: innerCol.implicitHeight
            flickableDirection: Flickable.VerticalFlick
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            // Reset scroll position when registry changes (new plugin dropped in)
            onContentHeightChanged: {
                if (contentY > contentHeight - height)
                    contentY = Math.max(0, contentHeight - height)
            }

            Column {
                id: innerCol
                width: flick.width
                spacing: island.s(10)

                // ── Theme label ──────────────────────────────────────────
                Text {
                    text: "Theme"
                    font.family: "JetBrains Mono"
                    font.pixelSize: island.s(11)
                    color: island.subtext0
                }

                Flow {
                    width: parent.width
                    spacing: island.s(8)

                    Repeater {
                        model: themeRegistry.themes
                        delegate: Rectangle {
                            id: themeCard
                            required property var modelData
                            property bool isSelected:  modelData.id === root.currentTheme
                            property bool cardHovered: themeMouse.containsMouse

                            width:  themeRow.implicitWidth + island.s(24)
                            height: island.s(34)
                            radius: island.s(10)

                            color: isSelected
                                ? Qt.rgba(island.mauve.r, island.mauve.g, island.mauve.b, cardHovered ? 0.35 : 0.20)
                                : Qt.rgba(island.surface1.r, island.surface1.g, island.surface1.b, cardHovered ? 0.70 : 0.40)
                            border.width: 1
                            border.color: isSelected
                                ? Qt.rgba(island.mauve.r, island.mauve.g, island.mauve.b, 0.50)
                                : Qt.rgba(island.text.r,  island.text.g,  island.text.b,  0.08)

                            Behavior on color { ColorAnimation { duration: 150 } }
                            scale: themeMouse.pressed ? 0.94 : 1.0
                            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }

                            Row {
                                id: themeRow
                                anchors.centerIn: parent
                                spacing: island.s(6)
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.icon
                                    font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(15)
                                    color: themeCard.isSelected ? island.mauve : island.subtext0
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.label
                                    font.family: "JetBrains Mono"; font.pixelSize: island.s(12); font.weight: Font.Medium
                                    color: themeCard.isSelected ? island.text : island.subtext0
                                }
                            }
                            MouseArea { id: themeMouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.setTheme(modelData.id) }
                        }
                    }
                }

                // ── Applets label ────────────────────────────────────────
                Text {
                    text: "Available applets"
                    font.family: "JetBrains Mono"
                    font.pixelSize: island.s(11)
                    color: island.subtext0
                    topPadding: island.s(2)
                }

                // ── Applet grid ──────────────────────────────────────────
                Flow {
                    id: appletGrid
                    width: parent.width
                    spacing: island.s(8)

                    Repeater {
                        model: root.registry
                        delegate: Rectangle {
                            id: appletCard
                            required property var modelData
                            property bool placed: modelData.id !== "spacer"
                                && modelData.id !== "separator"
                                && root.allPlaced().indexOf(modelData.id) >= 0
                            property bool cardHovered: cardMouse.containsMouse

                            width:  cardRow.implicitWidth + island.s(24)
                            height: island.s(34)
                            radius: island.s(10)

                            color: placed
                                ? Qt.rgba(island.mauve.r, island.mauve.g, island.mauve.b, cardHovered ? 0.35 : 0.2)
                                : Qt.rgba(island.surface1.r, island.surface1.g, island.surface1.b, cardHovered ? 0.7 : 0.4)
                            border.width: 1
                            border.color: placed
                                ? Qt.rgba(island.mauve.r, island.mauve.g, island.mauve.b, 0.5)
                                : Qt.rgba(island.text.r, island.text.g, island.text.b, 0.08)

                            Behavior on color { ColorAnimation { duration: 150 } }
                            scale: cardMouse.pressed ? 0.94 : 1.0
                            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }

                            Row {
                                id: cardRow
                                anchors.centerIn: parent
                                spacing: island.s(6)
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.icon
                                    font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(15)
                                    color: appletCard.placed ? island.mauve : island.subtext0
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.label
                                    font.family: "JetBrains Mono"; font.pixelSize: island.s(12); font.weight: Font.Medium
                                    color: appletCard.placed ? island.text : island.subtext0
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: appletCard.placed ? "−" : "+"
                                    font.family: "JetBrains Mono"; font.pixelSize: island.s(14); font.weight: Font.Black
                                    color: appletCard.placed ? island.red : island.green
                                }
                            }

                            MouseArea {
                                id: cardMouse; anchors.fill: parent; hoverEnabled: true
                                onClicked: {
                                    if (appletCard.placed) root.removeApplet(modelData.id)
                                    else                   root.addApplet(modelData.id)
                                }
                            }
                        }
                    }
                }

                // Bottom padding so last row doesn't sit flush against the fade
                Item { width: 1; height: island.s(4) }
            }
        }

        // Fade scrollbar in on scroll, out after 800ms idle
        Timer {
            id: _scrollFadeTimer
            interval: 800
            onTriggered: scrollArea._scrollOpacity = 0
        }
        Connections {
            target: flick
            function onContentYChanged() {
                scrollArea._scrollOpacity = 1
                _scrollFadeTimer.restart()
            }
        }

        // ── Custom scrollbar ───────────────────────────────────────────
        Item {
            id: scrollTrack
            visible: scrollArea._scrollVisible
            anchors { top: parent.top; bottom: parent.bottom; right: parent.right }
            width: island.s(4)

            opacity: scrollArea._scrollOpacity
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: Qt.rgba(island.mauve.r, island.mauve.g, island.mauve.b, 0.10)
            }

            Rectangle {
                id: scrollThumb
                width: parent.width
                radius: width / 2
                color: Qt.rgba(island.mauve.r, island.mauve.g, island.mauve.b, 0.55)

                readonly property real _ratio:  flick.height / Math.max(flick.contentHeight, 1)
                readonly property real _scroll: flick.contentY / Math.max(flick.contentHeight - flick.height, 1)

                height: Math.max(island.s(24), scrollTrack.height * _ratio)
                y:      _scroll * (scrollTrack.height - height)

                Behavior on height { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
            }
        }

        // ── Bottom fade (hint that there's more below) ─────────────────
        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: island.s(28)
            visible: scrollArea._scrollVisible && (flick.contentY < flick.contentHeight - flick.height - 2)
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 1.0; color: Qt.rgba(island.base.r, island.base.g, island.base.b, 0.85) }
            }
        }
    }
}
