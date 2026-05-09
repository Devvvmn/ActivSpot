pragma Singleton
import QtQuick
import Quickshell

// Stub for Noctalia BarService.
Singleton {
    function getTooltipDirection(screenName) { return "down" }
    function openPluginSettings(screen, manifest) {}

    // Layout direction for capsule pill content. ActivSpot bar is horizontal
    // and content reads left-to-right.
    function getPillDirection(widget) { return true }
}
