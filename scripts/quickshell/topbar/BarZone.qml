import QtQuick
import QtQuick.Layouts
import "./applets"

// BarZone — ordered container for one side of the top bar (left or right).
//
// Receives:
//   bar          — barWindow reference (provides data + s() scaling)
//   side         — "left" | "right" (controls fill direction)
//   appletOrder  — JS array of applet IDs, e.g. ["help", "ws"] or ["tray","spacer","kb","wifi","bt","battery"]
//   editMode     — set true when entering applet-edit mode (Phase 2)
//
// To register a new applet:
//   1. Create topbar/applets/MyApplet.qml with `property var bar`
//   2. Add a Component entry below (id: myComp; MyApplet { bar: barZone.bar })
//   3. Add a record to appletDefs

Item {
    id: barZone

    property var    bar
    property string side:        "left"
    property var    appletOrder: []
    property bool   editMode:    false

    // ── Applet component registry ──────────────────────────────────────
    // Add new applets here. Each Component binds bar: barZone.bar so
    // applets always get the current bar reference automatically.
    Component { id: helpComp;    HelpApplet       { bar: barZone.bar; editMode: barZone.editMode } }
    Component { id: wsComp;      WorkspacesApplet { bar: barZone.bar; editMode: barZone.editMode } }
    Component { id: kbComp;      KeyboardApplet   { bar: barZone.bar; editMode: barZone.editMode } }
    Component { id: wifiComp;    WifiApplet       { bar: barZone.bar; editMode: barZone.editMode } }
    Component { id: btComp;      BluetoothApplet  { bar: barZone.bar; editMode: barZone.editMode } }
    Component { id: batComp;     BatteryApplet    { bar: barZone.bar; editMode: barZone.editMode } }
    Component { id: trayComp;    SystemTrayApplet { bar: barZone.bar; editMode: barZone.editMode } }
    Component { id: spacerComp;  SpacerApplet     { bar: barZone.bar } }

    // Metadata used by AppletPickerPage (Phase 2) and for new-applet merge logic
    readonly property var appletDefs: [
        { id: "help",    comp: helpComp,   label: "Help",        icon: "󰋗" },
        { id: "ws",      comp: wsComp,     label: "Workspaces",  icon: "󰕰" },
        { id: "kb",      comp: kbComp,     label: "Keyboard",    icon: "󰌌" },
        { id: "wifi",    comp: wifiComp,   label: "Network",     icon: "󰤨" },
        { id: "bt",      comp: btComp,     label: "Bluetooth",   icon: "󰂱" },
        { id: "battery", comp: batComp,    label: "Battery",     icon: "󰁹" },
        { id: "tray",    comp: trayComp,   label: "System Tray", icon: "󱒔" },
        { id: "spacer",  comp: spacerComp, label: "Spacer",      icon: "󱐋" },
    ]

    function compFor(id) {
        for (let d of appletDefs) {
            if (d.id === id) return d.comp
        }
        return null
    }

    // ── Startup slide animation ────────────────────────────────────────
    property bool _showZone: false

    opacity: _showZone ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }

    transform: Translate {
        x: barZone._showZone ? 0
         : (barZone.side === "left" ? barZone.bar.s(-30) : barZone.bar.s(30))
        Behavior on x {
            NumberAnimation { duration: 800; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
        }
    }

    // Right zone waits for data to avoid layout jump; left zone appears immediately
    Timer {
        interval: barZone.side === "right" ? 250 : 10
        running:  barZone.bar
            && barZone.bar.isStartupReady
            && (barZone.side === "left" || barZone.bar.isDataReady)
            && !barZone._showZone
        onTriggered: barZone._showZone = true
    }

    // ── Layout ────────────────────────────────────────────────────────
    RowLayout {
        id: appletRow
        anchors.fill: parent
        spacing: barZone.bar ? barZone.bar.s(4) : 4

        // Left fill spacer — pushes right-zone items to the right edge
        Item { Layout.fillWidth: true; visible: barZone.side === "right" }

        Repeater {
            model: barZone.appletOrder
            delegate: Loader {
                required property string modelData
                Layout.alignment: Qt.AlignVCenter
                sourceComponent: barZone.compFor(modelData)
            }
        }

        // Right fill spacer — keeps left-zone items against the left edge
        Item { Layout.fillWidth: true; visible: barZone.side === "left" }
    }
}
