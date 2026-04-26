import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

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

    // Full registry (must match BarZone.appletDefs)
    readonly property var registry: [
        { id: "help",    label: "Help",        icon: "󰋗" },
        { id: "ws",      label: "Workspaces",  icon: "󰕰" },
        { id: "kb",      label: "Keyboard",    icon: "󰌌" },
        { id: "wifi",    label: "Network",     icon: "󰤨" },
        { id: "bt",      label: "Bluetooth",   icon: "󰂱" },
        { id: "battery", label: "Battery",     icon: "󰁹" },
        { id: "tray",    label: "System Tray", icon: "󱒔" },
    ]

    function allPlaced() { return leftOrder.concat(rightOrder) }

    // Load current layout from file on open
    Process {
        id: layoutReader; running: true
        command: ["bash", "-c", "cat ~/.cache/quickshell/topbar_layout.json 2>/dev/null || echo '{}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let d = JSON.parse(this.text.trim())
                    if (d.left  && Array.isArray(d.left))  root.leftOrder  = d.left
                    if (d.right && Array.isArray(d.right)) root.rightOrder = d.right
                    root._ordersLoaded = true
                } catch(e) { root._ordersLoaded = true }
            }
        }
    }

    // Write updated layout back to TopBar: update JSON then ping /tmp/qs_bar_reload
    function pushOrder() {
        let payload = JSON.stringify({ left: root.leftOrder, right: root.rightOrder })
        Quickshell.execDetached(["bash", "-c",
            "mkdir -p ~/.cache/quickshell && " +
            "printf '%s' \"$1\" > ~/.cache/quickshell/topbar_layout.json && " +
            "printf '1' > /tmp/qs_bar_reload",
            "qs_picker", payload
        ])
    }

    function addApplet(id) {
        let r = root.rightOrder.slice()
        if (r.indexOf(id) < 0) { r.push(id); root.rightOrder = r; root.pushOrder() }
    }

    function removeApplet(id) {
        root.leftOrder  = root.leftOrder.filter(x => x !== id)
        root.rightOrder = root.rightOrder.filter(x => x !== id)
        root.pushOrder()
    }

    // ── UI ─────────────────────────────────────────────────────────────
    anchors.fill: parent
    anchors.margins: island.s(18)
    anchors.bottomMargin: island.s(60)  // leave room for nav bar

    ColumnLayout {
        anchors.fill: parent
        spacing: island.s(14)

        // Title + Done button
        RowLayout {
            Layout.fillWidth: true
            spacing: island.s(8)

            Text {
                text: "Bar Applets"
                font.family: "JetBrains Mono"
                font.pixelSize: island.s(16)
                font.weight: Font.Bold
                color: island.text
                Layout.fillWidth: true
            }

            Rectangle {
                width: doneText.implicitWidth + island.s(24)
                height: island.s(32)
                radius: island.s(10)
                color: doneMouse.containsMouse
                    ? Qt.rgba(island.mauve.r, island.mauve.g, island.mauve.b, 0.25)
                    : Qt.rgba(island.surface1.r, island.surface1.g, island.surface1.b, 0.5)
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    id: doneText
                    anchors.centerIn: parent
                    text: "Done"
                    font.family: "JetBrains Mono"
                    font.pixelSize: island.s(13)
                    font.weight: Font.Bold
                    color: island.mauve
                }

                MouseArea {
                    id: doneMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: island.exitEditBarMode()
                }
            }
        }

        // Section label
        Text {
            text: "Available applets"
            font.family: "JetBrains Mono"
            font.pixelSize: island.s(11)
            color: island.subtext0
            Layout.topMargin: island.s(2)
        }

        // Applet grid
        Flow {
            id: appletGrid
            Layout.fillWidth: true
            spacing: island.s(8)

            Repeater {
                model: root.registry
                delegate: Rectangle {
                    id: appletCard
                    required property var modelData
                    property bool placed: root.allPlaced().indexOf(modelData.id) >= 0
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
                            font.family: "Iosevka Nerd Font"
                            font.pixelSize: island.s(15)
                            color: appletCard.placed ? island.mauve : island.subtext0
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.label
                            font.family: "JetBrains Mono"
                            font.pixelSize: island.s(12)
                            font.weight: Font.Medium
                            color: appletCard.placed ? island.text : island.subtext0
                        }
                        // +/− badge
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: appletCard.placed ? "−" : "+"
                            font.family: "JetBrains Mono"
                            font.pixelSize: island.s(14)
                            font.weight: Font.Black
                            color: appletCard.placed ? island.red : island.green
                        }
                    }

                    MouseArea {
                        id: cardMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            if (appletCard.placed) root.removeApplet(modelData.id)
                            else                   root.addApplet(modelData.id)
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
