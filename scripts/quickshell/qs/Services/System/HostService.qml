pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string osPretty: "Linux"
    property string osLogo:   ""      // path to distro logo SVG; empty = no logo
    property string hostname:  ""
    property string username:  ""

    Process {
        running: true
        command: ["bash", "-c",
            "grep '^PRETTY_NAME=' /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '\"'"]
        stdout: SplitParser {
            onRead: line => { if (line.trim()) root.osPretty = line.trim() }
        }
    }
}
