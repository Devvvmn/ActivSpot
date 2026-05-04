pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Tracks whether the focused window in Hyprland is in real fullscreen
// (`fullscreen >= 2`). Polled once a second via `hyprctl activewindow -j`.
//
// Consumed by the Dynamic Island and the Top Bar so they can hide their
// surfaces when a fullscreen game / video is active. The Dynamic Island
// has an `alwaysOnTop` override that ignores this signal.
Singleton {
    id: root

    property bool active: false

    Process {
        id: poller
        command: ["bash", "-c", "hyprctl activewindow -j 2>/dev/null | grep -oE '\"fullscreen\"\\s*:\\s*[0-9]+' | head -1 | grep -oE '[0-9]+$'"]
        stdout: StdioCollector {
            onStreamFinished: {
                var v = parseInt(this.text.trim() || "0", 10);
                root.active = (isFinite(v) && v >= 2);
            }
        }
    }

    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: poller.running = true
    }
}
