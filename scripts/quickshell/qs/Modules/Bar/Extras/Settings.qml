pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    function getBarPositionForScreen(screenName) { return "top" }

    readonly property var data: ({
        colorSchemes: { darkMode: true },
        systemMonitor: { externalMonitor: "kitty --title htop -e htop" }
    })
}
