import QtQuick
import themes

// Wallpaper-level large clock + date. Self-contained (JS Date). Host owns
// position/scale. Raised text shadow for legibility on any wallpaper.
// Never name a property `data` on an Item.
Item {
    id: root

    property var screen: null
    property string pluginDir: ""

    property var now: new Date()
    readonly property bool motion: !Theme.reduceMotion
    readonly property color shadow: Qt.rgba(0, 0, 0, 0.6)

    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }

    function _p(n) { return n < 10 ? "0" + n : "" + n }
    readonly property string hh: _p(now.getHours())
    readonly property string mm: _p(now.getMinutes())
    readonly property bool tick: now.getSeconds() % 2 === 0

    readonly property var _days:   ["SUNDAY","MONDAY","TUESDAY","WEDNESDAY","THURSDAY","FRIDAY","SATURDAY"]
    readonly property var _months: ["January","February","March","April","May","June",
                                    "July","August","September","October","November","December"]
    readonly property string dateStr:
        _days[now.getDay()] + " · " + now.getDate() + " " + _months[now.getMonth()]

    implicitWidth: col.width
    implicitHeight: col.height

    Column {
        id: col
        spacing: 2

        Row {
            id: timeRow
            spacing: 0
            Text {
                text: root.hh
                color: Theme.text
                font.pixelSize: 110
                font.weight: Font.Bold
                font.letterSpacing: -2
                style: Text.Raised; styleColor: root.shadow
            }
            Text {
                text: ":"
                color: Theme.accent
                font.pixelSize: 110
                font.weight: Font.Bold
                opacity: root.tick ? 1.0 : 0.25
                Behavior on opacity { NumberAnimation { duration: root.motion ? 220 : 0 } }
                style: Text.Raised; styleColor: root.shadow
            }
            Text {
                id: minText
                text: root.mm
                color: Theme.text
                font.pixelSize: 110
                font.weight: Font.Bold
                font.letterSpacing: -2
                style: Text.Raised; styleColor: root.shadow
                // gentle roll on minute change
                property real _dy: 0
                transform: Translate { y: minText._dy }
                onTextChanged: if (root.motion) rollAnim.restart()
                NumberAnimation { id: rollAnim; target: minText; property: "_dy"
                                  from: 14; to: 0; duration: 380; easing.type: Easing.OutCubic }
            }
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 6
            text: root.dateStr
            color: Theme.accent
            font.pixelSize: 18
            font.weight: Font.DemiBold
            font.letterSpacing: 4
            style: Text.Raised; styleColor: root.shadow
        }
    }
}
