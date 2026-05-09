pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    // ── Context menu state ─────────────────────────────────────────────────
    property bool menuVisible: false
    property var  menuModel:   []
    property real menuX:       0
    property real menuY:       42
    property var  _menu:       null
    property var  _screen:     null

    function showContextMenu(menu, anchor, screen) {
        if (!menu || !anchor) return
        root._menu    = menu
        root._screen  = screen ?? null
        root.menuModel = menu.model || []
        let pt = anchor.mapToGlobal(0, anchor.height)
        root.menuX = pt.x
        root.menuY = pt.y
        root.menuVisible = true
    }

    function closeContextMenu(screen) {
        root.menuVisible = false
        root._menu = null
    }

    function _trigger(action) {
        root.menuVisible = false
        if (root._menu) root._menu.triggered(action)
        root._menu = null
    }

    // ── Plugin panel state ─────────────────────────────────────────────────
    // Single global slot — one plugin panel can be open at a time.
    property bool   panelVisible:    false
    property url    panelSource:     ""
    property var    panelProps:      ({})
    property var    _panelScreen:    null
    property var    _panelAnchor:    null
    property string _panelPluginId:  ""
    property real   panelAnchorX:    0
    property real   panelAnchorY:    0
    property real   panelAnchorH:    0

    // Bumped after every openPanel so the overlay Loader can re-instantiate
    // even when the same plugin opens its panel again.
    property int    _panelEpoch:     0

    function openPluginPanel(pluginId, source, props, screen, anchor) {
        if (!source) return false
        // If the same plugin's panel is already open, treat as close (toggle parity).
        if (root.panelVisible && root._panelPluginId === pluginId) {
            root._closePluginPanel()
            return true
        }
        root._panelPluginId = pluginId
        root._panelScreen   = screen ?? null
        root._panelAnchor   = anchor ?? null
        if (anchor && anchor.mapToGlobal) {
            let pt = anchor.mapToGlobal(0, 0)
            root.panelAnchorX = pt.x
            root.panelAnchorY = pt.y
            root.panelAnchorH = anchor.height || 0
        } else {
            root.panelAnchorX = 0
            root.panelAnchorY = 0
            root.panelAnchorH = 0
        }
        root.panelProps     = props ?? ({})
        root.panelSource    = source
        root._panelEpoch   += 1
        root.panelVisible   = true
        return true
    }

    // Returns true if the panel for this pluginId was open and is now closed.
    function closePluginPanel(pluginId) {
        if (!root.panelVisible) return false
        if (pluginId && root._panelPluginId !== pluginId) return false
        root._closePluginPanel()
        return true
    }

    function isPanelOpenFor(pluginId) {
        return root.panelVisible && root._panelPluginId === pluginId
    }

    function _closePluginPanel() {
        root.panelVisible    = false
        root.panelSource     = ""
        root.panelProps      = ({})
        root._panelScreen    = null
        root._panelAnchor    = null
        root._panelPluginId  = ""
    }

    // Legacy aliases — Noctalia plugins call these on PanelService directly
    // in some paths. Map them to the plugin-panel slot.
    function closePanel(screen) { return root.closePluginPanel("") }
    function openPanel(component, screen, anchor) { /* unused */ }
}
