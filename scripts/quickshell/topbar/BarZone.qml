import QtQuick
import QtQuick.Effects
import "./applets"
import "../themes"
import "../plugins"

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
    property string side:             "left"
    property var    appletOrder:      []
    property bool   editMode:         false
    property bool   showGroupFrames:  true

    // ── Applet component registry ──────────────────────────────────────
    Component { id: helpComp;    HelpApplet       { bar: barZone.bar; editMode: barZone.editMode } }
    Component { id: wsComp;      WorkspacesApplet { bar: barZone.bar; editMode: barZone.editMode } }
    Component { id: kbComp;      KeyboardApplet   { bar: barZone.bar; editMode: barZone.editMode } }
    Component { id: wifiComp;    WifiApplet       { bar: barZone.bar; editMode: barZone.editMode } }
    Component { id: btComp;      BluetoothApplet  { bar: barZone.bar; editMode: barZone.editMode } }
    Component { id: batComp;     BatteryApplet    { bar: barZone.bar; editMode: barZone.editMode } }
    Component { id: trayComp;    SystemTrayApplet { bar: barZone.bar; editMode: barZone.editMode } }
    Component { id: spacerComp;  SpacerApplet     { bar: barZone.bar; editMode: barZone.editMode } }
    Component { id: separatorComp; SeparatorApplet { bar: barZone.bar; editMode: barZone.editMode } }
    Component { id: pluginComp; PluginApplet { bar: barZone.bar; editMode: barZone.editMode } }

    function isSpacer(id)    { return typeof id === "string" && id.indexOf("spacer")    === 0 }
    function isSeparator(id) { return typeof id === "string" && id.indexOf("separator") === 0 }
    function isPlugin(id)    { return typeof id === "string" && id.indexOf("plugin-")   === 0 }

    readonly property var appletDefs: [
        { id: "help",    comp: helpComp,   label: "Help",        icon: "󰋗" },
        { id: "ws",      comp: wsComp,     label: "Workspaces",  icon: "󰕰" },
        { id: "kb",      comp: kbComp,     label: "Keyboard",    icon: "󰌌" },
        { id: "wifi",    comp: wifiComp,   label: "Network",     icon: "󰤨" },
        { id: "bt",      comp: btComp,     label: "Bluetooth",   icon: "󰂱" },
        { id: "battery", comp: batComp,    label: "Battery",     icon: "󰁹" },
        { id: "tray",    comp: trayComp,   label: "System Tray", icon: "󱒔" },
        { id: "spacer",    comp: spacerComp,    label: "Spacer",    icon: "󱐋" },
        { id: "separator", comp: separatorComp, label: "Separator", icon: "│" },
    ]

    function compFor(id) {
        if (isSpacer(id))    return spacerComp
        if (isSeparator(id)) return separatorComp
        if (isPlugin(id))    return pluginComp
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

    // Group bounding boxes — appletOrder split by "spacer", each group gets a frame.
    // Re-evaluates whenever appletOrder or _widths change.
    property var _groupBounds: {
        let sp     = bar ? bar.s(4) : 4
        let pad    = bar ? bar.s(12) : 12
        let minGap = bar ? bar.s(8)  : 8     // min visible distance between adjacent group frames
        let _w     = _widths          // capture dependency
        let raw    = []
        let cur    = []

        for (let i = 0; i <= appletOrder.length; i++) {
            let id = appletOrder[i]
            if (isSpacer(id) || i === appletOrder.length) {
                if (cur.length > 0) {
                    let gx = homeXFor(cur[0])
                    let gw = 0
                    for (let j = 0; j < cur.length; j++) {
                        gw += (_w[cur[j]] || 0)
                        if (j < cur.length - 1) gw += sp
                    }
                    if (gw > 0) raw.push({ gx: gx, gw: gw })
                    cur = []
                }
            } else if (id !== undefined) {
                cur.push(id)
            }
        }

        // Resolve per-side padding so adjacent group frames meet at the
        // spacer midpoint instead of overlapping. Outer edges get full pad.
        let bounds = []
        for (let k = 0; k < raw.length; k++) {
            let g     = raw[k]
            let leftGap  = (k === 0) ? Infinity
                                     : (g.gx - (raw[k - 1].gx + raw[k - 1].gw))
            let rightGap = (k === raw.length - 1) ? Infinity
                                                  : (raw[k + 1].gx - (g.gx + g.gw))
            // Inner pad = clamp to half-(gap - minGap) so frames keep at least
            // `minGap` px of empty space between them; outer edges stay at full pad.
            let lp = (leftGap  === Infinity) ? pad : Math.min(pad, Math.max(0, (leftGap  - minGap) / 2))
            let rp = (rightGap === Infinity) ? pad : Math.min(pad, Math.max(0, (rightGap - minGap) / 2))
            bounds.push({ gx: g.gx, gw: g.gw, lp: lp, rp: rp })
        }
        return bounds
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

    // ── Group background frames (split by spacer, right zone only) ────
    Repeater {
        model: (barZone.showGroupFrames && !barZone.editMode) ? barZone._groupBounds : []
        delegate: Item {
            id: groupFrame
            required property var modelData

            property real _radius: barZone.bar ? barZone.bar.s(16) : 16

            x: modelData.gx - modelData.lp
            y: (barZone.height - height) / 2
            width:  modelData.gw + modelData.lp + modelData.rp
            height: barZone.bar ? barZone.bar.barHeight : 36

            opacity: barZone._showZone ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
            Behavior on x     { NumberAnimation { duration: 160; easing.type: Easing.OutExpo } }
            Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutExpo } }

            // Mocha surface — crust color to compensate for HyprGlass brightening
            Rectangle {
                anchors.fill: parent
                radius: groupFrame._radius
                color: Qt.rgba(barZone.bar.crust.r, barZone.bar.crust.g, barZone.bar.crust.b, 1.0)
                border.width: 1
                border.color: Qt.rgba(barZone.bar.text.r, barZone.bar.text.g, barZone.bar.text.b, 0.10)
                opacity: barZone.bar.glassTheme ? 0 : 1
                visible: opacity > 0.001
                Behavior on opacity { NumberAnimation { duration: 520; easing.type: Easing.InOutCubic } }
            }

            // Glass surface
            GlassSurface {
                anchors.fill: parent
                bar:    barZone.bar
                radius: groupFrame._radius
                opacity: barZone.bar && barZone.bar.glassTheme ? 1 : 0
                visible: opacity > 0.001
                Behavior on opacity { NumberAnimation { duration: 520; easing.type: Easing.InOutCubic } }
            }
        }
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
                onLoaded: {
                    barZone._reportWidth(slotItem.modelData, item.width)
                    if (barZone.isPlugin(slotItem.modelData)) {
                        let pluginId = slotItem.modelData.slice(7) // strip "plugin-"
                        let plugin = PluginLoader.findPlugin(pluginId)
                        item._pluginId = pluginId  // always set so retry can work
                        if (plugin) {
                            item.pluginManifest = plugin
                            item.pluginDir = plugin.pluginDir
                        }
                    }
                }
            }

            // ── Edit mode drag ─────────────────────────────────────────
            DragHandler {
                id: dragger
                enabled: barZone.editMode
                yAxis.minimum: slotItem.homeY
                yAxis.maximum: slotItem.homeY
                target: slotItem

                onActiveChanged: {
                    if (!active) {
                        let isCross = (barZone.side === "left"  && slotItem.x + slotItem.width > barZone.width) ||
                                      (barZone.side === "right" && slotItem.x < 0)
                        if (isCross) {
                            barZone.bar.crossZoneDrop(slotItem.modelData, barZone.side)
                        } else {
                            barZone.snapApplet(slotItem.modelData, slotItem.x + slotItem.width / 2)
                        }
                        slotItem.snapSpring = true
                        snapTimer.restart()
                    }
                }
            }

            // Tap-to-remove for spacers: simpler than dragging a thin line off-zone
            TapHandler {
                enabled: barZone.editMode && barZone.isSpacer(slotItem.modelData) && !dragger.active
                onTapped: barZone.bar.removeApplet(slotItem.modelData)
            }

            // Right-click in edit mode removes any applet (incl. spacers).
            TapHandler {
                enabled: barZone.editMode && !dragger.active
                acceptedButtons: Qt.RightButton
                onTapped: barZone.bar.removeApplet(slotItem.modelData)
            }

            // ── Edit mode overlay: border + grab icon ──────────────────
            Rectangle {
                id: editOverlay
                anchors.fill: parent
                visible: barZone.editMode && !barZone.isSpacer(slotItem.modelData) && !barZone.isSeparator(slotItem.modelData)
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
                    id: wiggleAnim
                    running: barZone.editMode && !dragger.active && !barZone.isSpacer(slotItem.modelData) && !barZone.isSeparator(slotItem.modelData)
                    loops: Animation.Infinite
                    NumberAnimation { to:  1.2; duration: 180 + (slotItem.index * 37) % 80; easing.type: Easing.InOutSine }
                    NumberAnimation { to: -1.2; duration: 180 + (slotItem.index * 37) % 80; easing.type: Easing.InOutSine }
                    onRunningChanged: if (!running) editOverlay.rotation = 0
                }
            }

            // Scale up slightly when dragged
            scale: dragger.active ? 1.08 : 1.0
            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
            z: dragger.active ? 20 : 0
        }
    }
}
