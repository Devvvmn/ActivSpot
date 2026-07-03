import QtQuick
import Quickshell
import Quickshell.Wayland
import themes

// Instantiates "desktop widgets" declared via the manifest "desktopWidget" field.
// Unlike "window" plugins (which own their PanelWindow), a desktopWidget plugin
// provides only an Item — the host wraps it in a Bottom-layer PanelWindow so the
// widget renders on the wallpaper level: above the wallpaper daemon (Background)
// but below every app window.
//
// Position + scale + visibility live in the DesktopWidgetStore singleton (shared
// with AppletPickerPage) and are editable while the unified edit mode is active.
// In edit mode each widget gets a drag surface + corner resize handle; otherwise
// the surface is click-through.
//
// Widget contract:
//   • root is an Item (NOT a window) — size via implicitWidth/implicitHeight
//   • do NOT anchor to screen edges; the host positions you via x/y/scale
//   • receives `screen` and `pluginDir` initial properties
Scope {
    id: root

    // ── Edit-mode snap grid ──────────────────────────────────────────────────
    // A single full-screen, click-through Bottom-layer overlay showing a grid of
    // slightly trembling dots while the unified edit mode is active. Purely a
    // visual aid for arranging desktop widgets.
    PanelWindow {
        id: gridWindow
        visible: DesktopWidgetStore.editMode

        color: "transparent"
        WlrLayershell.namespace: "qs-desktop-grid"
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore

        anchors.top: true; anchors.bottom: true
        anchors.left: true; anchors.right: true

        mask: Region {}   // never steal clicks from widgets/desktop

        readonly property bool animate: DesktopWidgetStore.editMode && !Theme.reduceMotion

        Canvas {
            id: gridCanvas
            anchors.fill: parent
            opacity: DesktopWidgetStore.editMode ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }

            readonly property int spacing: 60
            readonly property real amp: 1.8      // jitter amplitude (px)
            property real t: 0

            onPaint: {
                const ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                const a = Theme.accent
                const r = Math.round(a.r * 255), g = Math.round(a.g * 255), b = Math.round(a.b * 255)
                ctx.fillStyle = "rgba(" + r + "," + g + "," + b + ",0.32)"
                const sp = spacing
                for (let gx = sp; gx < width; gx += sp) {
                    for (let gy = sp; gy < height; gy += sp) {
                        const phase = (gx + gy) * 0.013
                        const jx = Math.sin(t + phase) * amp
                        const jy = Math.cos(t * 0.9 + gx * 0.011) * amp
                        ctx.fillRect(gx + jx - 1, gy + jy - 1, 2, 2)
                    }
                }
            }
        }

        // ~30 fps tremble; stops when not editing (or reduceMotion).
        Timer {
            interval: 33
            running: gridWindow.animate && gridCanvas.opacity > 0.01
            repeat: true
            onTriggered: { gridCanvas.t += 0.18; gridCanvas.requestPaint() }
        }

        // Static repaint when motion is reduced but the grid is shown.
        onVisibleChanged: if (visible) gridCanvas.requestPaint()
    }

    Instantiator {
        model: {
            const out = []
            let i = 0
            // Reading DesktopWidgetStore.store here makes the model reactive to
            // instance add/remove — a changed model *count* recreates delegates
            // (unlike changed field values, which Instantiator ignores).
            const store = DesktopWidgetStore.store
            for (const p of PluginLoader.plugins) {
                if (!(p.desktopWidget && p.pluginDir)) continue
                // Base instance (key === plugin id) is always present. Extra
                // instances are stored under "<pid>#<n>" keys.
                const ids = [p.id]
                for (const k in store) {
                    if (k.indexOf(p.id + "#") === 0) ids.push(k)
                }
                for (const instId of ids) {
                    out.push({
                        src: "file://" + p.pluginDir + "/" + p.desktopWidget,
                        dir: p.pluginDir, pid: p.id, instId: instId, idx: i
                    })
                    i++
                }
            }
            return out
        }

        delegate: PanelWindow {
            id: deskWindow
            required property var modelData

            readonly property var saved: DesktopWidgetStore.store[modelData.instId] || ({})
            readonly property bool enabled: saved.enabled !== false
            readonly property bool editMode: DesktopWidgetStore.editMode

            // Drag/scale grab coordination (see DesktopWidgetStore.activeDrag).
            readonly property bool _dragging:      DesktopWidgetStore.activeDrag === modelData.instId
            readonly property bool _otherDragging: DesktopWidgetStore.activeDrag !== "" && !_dragging

            color: "transparent"
            WlrLayershell.namespace: "qs-desktop-widget"
            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore

            anchors.top: true; anchors.bottom: true
            anchors.left: true; anchors.right: true

            // Input mask:
            //   • not editing / disabled / another widget being dragged → no input
            //   • this widget being dragged → full screen, so the cursor can never
            //     leave the input region and drop the pointer grab mid-gesture
            //   • editing, idle → just the widget frame (grab any widget)
            mask: Region {
                item: !(deskWindow.editMode && deskWindow.enabled) ? null
                    : deskWindow._otherDragging ? null
                    : deskWindow._dragging ? fullMask
                    : frame
            }

            // Full-window region used as the input mask during an active gesture.
            Item { id: fullMask; anchors.fill: parent }

            Item {
                id: frame
                visible: deskWindow.enabled
                width: widgetLoader.implicitWidth * scaleF
                height: widgetLoader.implicitHeight * scaleF

                // Position + scale from the store, with a staggered default so
                // first-run widgets don't all stack on the same pixel.
                property real scaleF: deskWindow.saved.scale || 1.0
                x: deskWindow.saved.x !== undefined ? deskWindow.saved.x
                                                    : deskWindow.width - width - 40
                y: deskWindow.saved.y !== undefined ? deskWindow.saved.y
                                                    : 56 + modelData.idx * 40

                function clamp() {
                    x = Math.max(0, Math.min(x, deskWindow.width  - width))
                    y = Math.max(0, Math.min(y, deskWindow.height - height))
                }
                function persist() {
                    DesktopWidgetStore.saveEntry(modelData.instId, { x: x, y: y, scale: scaleF })
                }

                Loader {
                    id: widgetLoader
                    width: widgetLoader.implicitWidth
                    height: widgetLoader.implicitHeight
                    transformOrigin: Item.TopLeft
                    scale: frame.scaleF
                    asynchronous: true
                    source: deskWindow.modelData.src
                    onLoaded: {
                        if (!item) return
                        if (item.hasOwnProperty("screen"))     item.screen = deskWindow.screen
                        if (item.hasOwnProperty("pluginDir"))  item.pluginDir = deskWindow.modelData.dir
                        if (item.hasOwnProperty("instanceId")) item.instanceId = deskWindow.modelData.instId
                    }
                }

                // ── Edit chrome ──────────────────────────────────────────────
                Rectangle {
                    anchors.fill: parent
                    visible: deskWindow.editMode
                    color: "transparent"
                    radius: 16
                    border.width: 2
                    border.color: Theme.accent
                    opacity: 0.9

                    Repeater {
                        model: 4
                        delegate: Rectangle {
                            width: 10; height: 10; radius: 2
                            color: Theme.accent
                            x: (index % 2 === 0) ? -2 : parent.width - 8
                            y: (index < 2) ? -2 : parent.height - 8
                        }
                    }
                }

                // Drag to move. Uses absolute (window) coordinates so moving the
                // frame doesn't feed back into the delta and cause jitter.
                MouseArea {
                    anchors.fill: parent
                    enabled: deskWindow.editMode
                    cursorShape: Qt.SizeAllCursor
                    property real startMx: 0
                    property real startMy: 0
                    property real startX: 0
                    property real startY: 0
                    onPressed: (m) => {
                        DesktopWidgetStore.activeDrag = deskWindow.modelData.instId
                        const p = mapToItem(deskWindow.contentItem, m.x, m.y)
                        startMx = p.x; startMy = p.y; startX = frame.x; startY = frame.y
                    }
                    onPositionChanged: (m) => {
                        if (!pressed) return
                        const p = mapToItem(deskWindow.contentItem, m.x, m.y)
                        frame.x = startX + (p.x - startMx)
                        frame.y = startY + (p.y - startMy)
                    }
                    onReleased: { DesktopWidgetStore.activeDrag = ""; frame.clamp(); frame.persist() }
                    onCanceled: { DesktopWidgetStore.activeDrag = ""; frame.clamp(); frame.persist() }
                }

                // Corner handle to scale
                Rectangle {
                    id: scaleHandle
                    visible: deskWindow.editMode
                    width: 22; height: 22; radius: 11
                    color: Theme.accent
                    border.width: 2
                    border.color: Theme.base
                    x: parent.width - width / 2
                    y: parent.height - height / 2
                    z: 10

                    Text { anchors.centerIn: parent; text: "⤡"; color: Theme.base; font.pixelSize: 12 }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.SizeFDiagCursor
                        property real startScale: 1
                        property real startW: 1
                        property real startX: 0
                        onPressed: (m) => {
                            DesktopWidgetStore.activeDrag = deskWindow.modelData.instId
                            startScale = frame.scaleF
                            startW = frame.width
                            startX = mapToItem(deskWindow.contentItem, m.x, m.y).x
                        }
                        onPositionChanged: (m) => {
                            if (!pressed) return
                            const curX = mapToItem(deskWindow.contentItem, m.x, m.y).x
                            const factor = Math.max(0.4, Math.min(3.0, (startW + (curX - startX)) / Math.max(1, startW)))
                            frame.scaleF = Math.max(0.4, Math.min(3.0, startScale * factor))
                        }
                        onReleased: { DesktopWidgetStore.activeDrag = ""; frame.clamp(); frame.persist() }
                        onCanceled: { DesktopWidgetStore.activeDrag = ""; frame.clamp(); frame.persist() }
                    }
                }
            }
        }
    }
}
