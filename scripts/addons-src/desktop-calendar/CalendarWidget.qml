import QtQuick
import themes

// Wallpaper-level month calendar. Root is a plain Item (the desktopWidget
// contract) — the host wraps it in a Bottom-layer click-through PanelWindow.
// We anchor ourselves to the top-right of the full-screen `desktopRoot`.
Item {
    id: root

    // Provided by PluginDesktopHost (declare even if unused).
    property var screen: null
    property string pluginDir: ""

    // ── Date model ────────────────────────────────────────────────────────────
    property var now: new Date()
    readonly property int year:  now.getFullYear()
    readonly property int month: now.getMonth()          // 0-based
    readonly property int today: now.getDate()

    // Monday-first weekday of the 1st (JS getDay: 0=Sun … 6=Sat → 0=Mon … 6=Sun)
    readonly property int firstWeekday: {
        const d = new Date(year, month, 1).getDay()
        return (d + 6) % 7
    }
    readonly property int daysInMonth: new Date(year, month + 1, 0).getDate()

    readonly property var monthNames: ["January","February","March","April","May","June",
                                       "July","August","September","October","November","December"]
    readonly property var dayLabels: ["Mo","Tu","We","Th","Fr","Sa","Su"]

    // Tick over at local midnight so `today` stays correct without polling.
    Timer {
        interval: 60000; running: true; repeat: true
        onTriggered: root.now = new Date()
    }

    // Host (PluginDesktopHost) owns position + scale — do NOT anchor to screen.
    // We only declare our content size; the host reads implicitWidth/Height.
    implicitWidth: card.width
    implicitHeight: card.height

    Rectangle {
        id: card
        width: 312
        height: header.height + grid.height + 3 * pad
        radius: Theme.radXl
        color: Qt.rgba(Theme.base.r, Theme.base.g, Theme.base.b, 0.78)
        border.width: 1
        border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08)

        readonly property int pad: 18

        // Header: "June 2026"
        Column {
            id: header
            x: card.pad
            y: card.pad
            width: parent.width - 2 * card.pad
            spacing: 2

            Text {
                text: root.monthNames[root.month]
                color: Theme.accent
                font.pixelSize: 22
                font.weight: Font.DemiBold
            }
            Text {
                text: root.year
                color: Theme.subtext0
                font.pixelSize: 13
                font.weight: Font.Medium
            }
        }

        // Weekday labels + day grid
        Grid {
            id: grid
            x: card.pad
            y: header.y + header.height + card.pad
            width: parent.width - 2 * card.pad
            columns: 7
            rowSpacing: 4
            columnSpacing: 0

            readonly property real cell: width / 7

            // Weekday header row
            Repeater {
                model: root.dayLabels
                delegate: Item {
                    width: grid.cell; height: grid.cell * 0.7
                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        color: Theme.subtext0
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        opacity: 0.7
                    }
                }
            }

            // Leading blanks + day numbers
            Repeater {
                model: root.firstWeekday + root.daysInMonth
                delegate: Item {
                    width: grid.cell; height: grid.cell
                    readonly property int dayNum: index - root.firstWeekday + 1
                    readonly property bool isDay: dayNum >= 1
                    readonly property bool isToday: isDay && dayNum === root.today

                    Rectangle {
                        anchors.centerIn: parent
                        width: grid.cell * 0.82
                        height: width
                        radius: width / 2
                        visible: isToday
                        color: Theme.accent
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: isDay
                        text: dayNum
                        color: isToday ? Theme.base : Theme.text
                        font.pixelSize: 13
                        font.weight: isToday ? Font.Bold : Font.Normal
                    }
                }
            }
        }
    }
}
