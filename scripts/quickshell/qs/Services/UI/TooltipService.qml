pragma Singleton
import QtQuick
import Quickshell

// Stub: ActivSpot doesn't have a global tooltip service.
// Tooltip display is handled per-widget via standard QML ToolTip.
Singleton {
    function show(item, text, direction) {}
    function hide(item) {}
}
