import QtQuick
import Quickshell
import Quickshell.Io
import themes

// Wallpaper-level recent-notifications feed. Reads the shell's history cache
// (~/.cache/quickshell/notifications.json: [{appName,title,body,icon,timestamp}],
// newest first) and watches it via single-shot inotifywait. Never name a
// property `data` on an Item.
Item {
    id: root

    property var screen: null
    property string pluginDir: ""

    property var items: []
    property double nowTs: Date.now()
    readonly property color shadow: Qt.rgba(0, 0, 0, 0.6)
    readonly property int maxItems: 4

    function _rel(ts) {
        const d = Math.max(0, (root.nowTs - ts) / 1000)
        if (d < 60)    return "now"
        if (d < 3600)  return Math.floor(d / 60) + "m"
        if (d < 86400) return Math.floor(d / 3600) + "h"
        return Math.floor(d / 86400) + "d"
    }

    Process {
        id: reader
        running: false
        command: ["bash", "-c", "cat ~/.cache/quickshell/notifications.json 2>/dev/null || echo '[]'"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const arr = JSON.parse(this.text || "[]")
                    root.items = Array.isArray(arr) ? arr.slice(0, root.maxItems) : []
                } catch (e) { root.items = [] }
                root.nowTs = Date.now()
            }
        }
    }
    function _load() { reader.running = false; reader.running = true }

    Process {
        id: watcher
        running: true
        command: ["bash", "-c",
            "inotifywait -qq -e close_write,moved_to ~/.cache/quickshell/notifications.json 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: { root._load(); watcher.running = false; watcher.running = true }
        }
    }

    Component.onCompleted: _load()
    // refresh relative timestamps periodically
    Timer { interval: 30000; running: true; repeat: true; onTriggered: root.nowTs = Date.now() }

    implicitWidth: 380
    implicitHeight: Math.max(1, col.height)
    opacity: root.items.length > 0 ? 1.0 : 0.0
    Behavior on opacity { NumberAnimation { duration: 300 } }

    Column {
        id: col
        width: parent.width
        spacing: 8

        Repeater {
            model: root.items
            delegate: Row {
                width: col.width
                spacing: 10

                // app icon
                Rectangle {
                    width: 34; height: 34; radius: 9
                    anchors.verticalCenter: parent.verticalCenter
                    color: Qt.rgba(Theme.base.r, Theme.base.g, Theme.base.b, 0.7)
                    border.width: 1
                    border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.12)
                    clip: true
                    Image {
                        anchors.centerIn: parent
                        width: 22; height: 22
                        source: modelData.icon || ""
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        visible: (modelData.icon || "").length > 0
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: (modelData.icon || "").length === 0
                        text: (modelData.appName || "?").substring(0, 1).toUpperCase()
                        color: Theme.accent; font.pixelSize: 16; font.weight: Font.Bold
                    }
                }

                Column {
                    width: parent.width - 34 - 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1

                    Row {
                        width: parent.width
                        spacing: 6
                        Text {
                            width: parent.width - timeText.width - 6
                            text: modelData.title || modelData.appName || ""
                            color: Theme.text
                            font.pixelSize: 14; font.weight: Font.Bold
                            elide: Text.ElideRight
                            style: Text.Raised; styleColor: root.shadow
                        }
                        Text {
                            id: timeText
                            text: root._rel(modelData.timestamp || root.nowTs)
                            color: Theme.subtext0
                            font.pixelSize: 11; font.weight: Font.Medium
                        }
                    }
                    Text {
                        width: parent.width
                        text: modelData.body || ""
                        visible: (modelData.body || "").length > 0
                        color: Theme.subtext0
                        font.pixelSize: 12
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        style: Text.Raised; styleColor: root.shadow
                    }
                }
            }
        }
    }
}
