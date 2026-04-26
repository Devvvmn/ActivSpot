import QtQuick
import QtQuick.Effects
import "./applets"

// BarZone — ordered, draggable container for one side of the top bar.
//
// Normal mode : applets positioned via homeX (accumulated widths), animated with OutExpo.
// Edit mode   : DragHandler enabled per applet, spring-snap on release, reorders appletOrder.
//
// Adding a new applet type:
//   1. Create topbar/applets/MyApplet.qml with `property var bar`
//   2. Add Component + appletDefs entry here.

Item {
    id: barZone

    property var    bar
    property string side:        "left"
    property var    appletOrder: []
    property bool   editMode:    false

    // ── Applet component registry ──────────────────────────────────────
    Component { id: helpComp;    HelpApplet       { bar: barZone.bar; editMode: barZone.editMode } }
    Component { id: wsComp;      WorkspacesApplet { bar: barZone.bar; editMode: barZone.editMode } }
    Component { id: kbComp;      KeyboardApplet   { bar: barZone.bar; editMode: barZone.editMode } }
    Component { id: wifiComp;    WifiApplet       { bar: barZone.bar; editMode: barZone.editMode } }
    Component { id: btComp;      BluetoothApplet  { bar: barZone.bar; editMode: barZone.editMode } }
    Component { id: batComp;     BatteryApplet    { bar: barZone.bar; editMode: barZone.editMode } }
    Component { id: trayComp;    SystemTrayApplet { bar: barZone.bar; editMode: barZone.editMode } }
    Component { id: spacerComp;  SpacerApplet     { bar: barZone.bar } }

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
        for (let d of appletDefs) { if (d.id === id) return d.comp }
        return null
    }

    // ── Width tracking by applet ID (survives reorder) ─────────────────
    property var _widths: ({})

    function _reportWidth(appletId, w) {
        if (_widths[appletId] === w) return
        let ww = Object.assign({}, _widths)
        ww[appletId] = w
        _widths = ww
    }

    // Total rendered width of all applets in this zone (for right-alignment)
    property real _totalW: {
        let sp = bar ? bar.s(4) : 4
        let tot = 0
        for (let i = 0; i < appletOrder.length; i++) {
            tot += (_widths[appletOrder[i]] || 0)
            if (i < appletOrder.length - 1) tot += sp
        }
        return tot
    }

    // Home x for a given applet ID
    function homeXFor(appletId) {
        let sp    = bar ? bar.s(4) : 4
        let order = appletOrder
        let idx   = order.indexOf(appletId)
        if (idx < 0) return 0

        if (side === "right") {
            // Start from right edge, offset by total width
            let x = barZone.width - _totalW
            for (let i = 0; i < idx; i++) x += (_widths[order[i]] || 0) + sp
            return x
        } else {
            let x = 0
            for (let i = 0; i < idx; i++) x += (_widths[order[i]] || 0) + sp
            return x
        }
    }

    // Reorder appletOrder by inserting appletId at the slot nearest dropCenterX.
    // Calls bar.updateAppletOrder(side, newOrder) — TopBar owns the source of truth.
    function snapApplet(appletId, dropCenterX) {
        let sp    = bar ? bar.s(4) : 4
        let order = appletOrder.filter(id => id !== appletId)

        function slotX(i) {
            if (side === "right") {
                let tot = 0
                for (let j = 0; j < order.length; j++) {
                    tot += (_widths[order[j]] || 0)
                    if (j < order.length - 1) tot += sp
                }
                let x = barZone.width - tot
                for (let j = 0; j < i; j++) x += (_widths[order[j]] || 0) + sp
                return x
            } else {
                let x = 0
                for (let j = 0; j < i; j++) x += (_widths[order[j]] || 0) + sp
                return x
            }
        }

        let best = order.length
        for (let i = 0; i <= order.length; i++) {
            let cx = slotX(i) + (_widths[order[i]] || 0) / 2
            if (dropCenterX <= cx) { best = i; break }
        }

        let newOrder = order.slice()
        newOrder.splice(best, 0, appletId)
        bar.updateAppletOrder(side, newOrder)
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

    Timer {
        interval: barZone.side === "right" ? 250 : 10
        running:  barZone.bar
            && barZone.bar.isStartupReady
            && (barZone.side === "left" || barZone.bar.isDataReady)
            && !barZone._showZone
        onTriggered: barZone._showZone = true
    }

    // ── Edit mode: animated background ring behind zone ────────────────
    Rectangle {
        anchors.fill: parent
        anchors.margins: -barZone.bar.s(4)
        radius: barZone.bar.s(18)
        color: "transparent"
        border.width: 1
        border.color: Qt.rgba(barZone.bar.mauve.r, barZone.bar.mauve.g, barZone.bar.mauve.b, 0.22)
        opacity: barZone.editMode ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 300 } }
    }

    // ── Slot delegates ─────────────────────────────────────────────────
    Repeater {
        id: slotRepeater
        model: barZone.appletOrder

        delegate: Item {
            id: slotItem
            required property string modelData   // applet ID
            required property int    index

            // homeX re-evaluates automatically when _widths / appletOrder / width change
            property real homeX: barZone.homeXFor(modelData)
            property real homeY: (barZone.height - height) / 2

            property bool snapSpring: false
            Timer { id: snapTimer; interval: 600; onTriggered: slotItem.snapSpring = false }

            x: homeX
            y: homeY

            Behavior on x {
                enabled: !dragger.active && !slotItem.snapSpring
                NumberAnimation { duration: 160; easing.type: Easing.OutExpo }
            }
            Behavior on y {
                enabled: !dragger.active && !slotItem.snapSpring
                NumberAnimation { duration: 160; easing.type: Easing.OutExpo }
            }
            SpringAnimation {
                target: slotItem; property: "x"; to: slotItem.homeX
                spring: 4.5; damping: 0.6; running: slotItem.snapSpring
            }

            // Size tracks loaded applet
            width:  appletLoader.item ? appletLoader.item.width  : 0
            height: appletLoader.item ? appletLoader.item.height : (barZone.bar ? barZone.bar.barHeight : 48)

            // Report width changes to zone so homeX recalculates for siblings
            onWidthChanged: barZone._reportWidth(slotItem.modelData, width)

            Loader {
                id: appletLoader
                anchors.centerIn: parent
                sourceComponent: barZone.compFor(modelData)
                onLoaded: barZone._reportWidth(slotItem.modelData, item.width)
            }

            // ── Edit mode drag ─────────────────────────────────────────
            DragHandler {
                id: dragger
                enabled: barZone.editMode && slotItem.modelData !== "spacer"
                xAxis.minimum: 0
                xAxis.maximum: barZone.width - slotItem.width
                yAxis.minimum: slotItem.homeY
                yAxis.maximum: slotItem.homeY
                target: slotItem

                onActiveChanged: {
                    if (!active) {
                        let dropCenter = slotItem.x + slotItem.width / 2
                        barZone.snapApplet(slotItem.modelData, dropCenter)
                        slotItem.snapSpring = true
                        snapTimer.restart()
                    }
                }
            }

            // ── Edit mode overlay: border + grab icon ──────────────────
            Rectangle {
                id: editOverlay
                anchors.fill: parent
                visible: barZone.editMode && slotItem.modelData !== "spacer"
                color: dragger.active
                    ? Qt.rgba(barZone.bar.mauve.r, barZone.bar.mauve.g, barZone.bar.mauve.b, 0.18)
                    : "transparent"
                radius: barZone.bar.s(14)
                border.width: 1
                border.color: Qt.rgba(barZone.bar.mauve.r, barZone.bar.mauve.g, barZone.bar.mauve.b,
                                      dragger.active ? 0.7 : 0.35)
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                // Gentle wiggle in edit mode (iOS-style)
                SequentialAnimation on rotation {
                    running: barZone.editMode && !dragger.active && slotItem.modelData !== "spacer"
                    loops: Animation.Infinite
                    NumberAnimation { to:  1.2; duration: 180 + (slotItem.index * 37) % 80; easing.type: Easing.InOutSine }
                    NumberAnimation { to: -1.2; duration: 180 + (slotItem.index * 37) % 80; easing.type: Easing.InOutSine }
                }
                onRunningChanged: if (!running) rotation = 0
            }

            // Scale up slightly when dragged
            scale: dragger.active ? 1.08 : 1.0
            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
            z: dragger.active ? 20 : 0
        }
    }
}
