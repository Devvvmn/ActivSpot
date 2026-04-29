pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

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

    // Called by the overlay when a menu item is clicked
    function _trigger(action) {
        root.menuVisible = false
        if (root._menu) root._menu.triggered(action)
        root._menu = null
    }

    function closePanel(screen) {}
    function openPanel(component, screen, anchor) {}
}
