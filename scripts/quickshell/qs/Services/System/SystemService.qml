pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property string hostname: "localhost"
    readonly property string username: ""
    readonly property string distro:   "Linux"
    readonly property string kernel:   ""
    readonly property real   uptime:   0
    readonly property real   cpuUsage: 0
    readonly property real   memUsed:  0
    readonly property real   memTotal: 0
}
