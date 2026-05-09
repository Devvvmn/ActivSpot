import QtQuick
import "../themes"

// Single digit with vertical flip transition on change.
// Outgoing digit slides up + fades; incoming digit slides in from below.
Item {
    id: root
    property var island
    property string digit: "0"
    property real fontSize: 58
    property color color: island ? island.text : "#fff"
    property int weight: Font.Light
    property real letterSpacing: -1.5

    implicitWidth: measure.implicitWidth
    implicitHeight: measure.implicitHeight
    clip: true

    Text {
        id: measure
        visible: false
        text: "0"
        font.family: Theme.fontDisplay
        font.pixelSize: root.fontSize
        font.weight: root.weight
        font.letterSpacing: root.letterSpacing
    }

    Text {
        id: current
        text: root.digit
        font.family: Theme.fontDisplay
        font.pixelSize: root.fontSize
        font.weight: root.weight
        font.letterSpacing: root.letterSpacing
        color: root.color
        anchors.horizontalCenter: parent.horizontalCenter
        y: 0
        opacity: 1
    }

    Text {
        id: incoming
        font.family: Theme.fontDisplay
        font.pixelSize: root.fontSize
        font.weight: root.weight
        font.letterSpacing: root.letterSpacing
        color: root.color
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.height
        opacity: 0
    }

    onDigitChanged: {
        if (Theme.reduceMotion) return
        if (incoming.text === root.digit) return
        incoming.text = root.digit
        flipAnim.restart()
    }

    ParallelAnimation {
        id: flipAnim
        NumberAnimation { target: current;  property: "y";       from: 0;            to: -root.height;  duration: 280; easing.type: Easing.OutCubic }
        NumberAnimation { target: current;  property: "opacity"; from: 1;            to: 0;             duration: 220; easing.type: Easing.OutCubic }
        NumberAnimation { target: incoming; property: "y";       from: root.height;  to: 0;             duration: 320; easing.type: Easing.OutCubic }
        NumberAnimation { target: incoming; property: "opacity"; from: 0;            to: 1;             duration: 280; easing.type: Easing.OutCubic }
        onFinished: {
            current.text = incoming.text
            current.y = 0
            current.opacity = 1
            incoming.y = root.height
            incoming.opacity = 0
        }
    }
}
