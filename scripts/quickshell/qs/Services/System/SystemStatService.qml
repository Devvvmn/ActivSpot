pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real cpuUsage: 0

    property real _prevTotal: 0
    property real _prevIdle:  0

    Process {
        id: _reader
        running: false
        command: ["bash", "-c", "awk '/^cpu /{t=0; for(i=2;i<=NF;i++) t+=$i; print t, $5+$6}' /proc/stat"]
        stdout: SplitParser {
            onRead: line => {
                let p = line.trim().split(" ")
                if (p.length < 2) return
                let total = parseFloat(p[0])
                let idle  = parseFloat(p[1])
                let dt = total - root._prevTotal
                let di = idle  - root._prevIdle
                if (dt > 0) root.cpuUsage = Math.max(0, Math.min(100, 100 * (1 - di / dt)))
                root._prevTotal = total
                root._prevIdle  = idle
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: { _reader.running = false; _reader.running = true }
    }
}
