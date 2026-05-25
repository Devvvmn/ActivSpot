import QtQuick
import QtQuick.Effects
import Quickshell

Item {
    id: slider
    height: s(72)

    property string label: ""
    property string icon: ""
    property color accentColor: "#ffffff"

    signal activated()

    function s(v) { return Math.round(v * Math.max(0.5, Math.min(2.2, Screen.width / 1920.0))) }

    property real knobX: 0
    property real knobSize: height - s(8)
    property real maxKnobX: Math.max(1, width - knobSize - s(8))
    property bool isActivated: false
    property real progress: Math.min(1.0, knobX / maxKnobX)

    // Track — frosted glass look: thin white border, very low fill
    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: Qt.rgba(1, 1, 1, 0.10)
        border.color: Qt.rgba(1, 1, 1, 0.22)
        border.width: 1
        clip: true

        // Accent fill behind knob
        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: slider.knobX + slider.knobSize + slider.s(4)
            radius: parent.radius
            color: slider.accentColor
            opacity: slider.progress * 0.22
        }

        // "slide to X" label — centered, fades as knob advances
        Text {
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: slider.knobSize * 0.32
            text: "slide to " + slider.label
            font.family: "Inter"
            font.weight: Font.Medium
            font.pixelSize: slider.s(15)
            font.letterSpacing: 0.1
            color: Qt.rgba(1, 1, 1, 0.60)
            opacity: 1.0 - Math.min(1.0, slider.progress * 2.5)
        }

        // Knob
        Rectangle {
            id: knob
            width: slider.knobSize
            height: slider.knobSize
            radius: height / 2
            x: slider.knobX + slider.s(4)
            anchors.verticalCenter: parent.verticalCenter
            color: "white"

            scale: dragArea.pressed ? 0.91 : 1.0
            Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }

            Behavior on x {
                enabled: !dragArea.pressed
                NumberAnimation { duration: 460; easing.type: Easing.OutBack; easing.overshoot: 0.6 }
            }

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(0, 0, 0, 0.45)
                shadowBlur: 0.7
                shadowVerticalOffset: 4
                shadowHorizontalOffset: 0
            }

            // Icon — accent colored, Nerd Font
            Text {
                anchors.centerIn: parent
                font.family: "Iosevka Nerd Font"
                font.pixelSize: slider.s(20)
                color: slider.accentColor
                text: slider.icon
            }
        }

        MouseArea {
            id: dragArea
            anchors.fill: parent
            cursorShape: slider.isActivated ? Qt.ArrowCursor : Qt.PointingHandCursor

            property real startMouseX: 0
            property real startKnobX: 0

            onPressed: (mouse) => {
                if (slider.isActivated) return
                startMouseX = mouse.x
                startKnobX = slider.knobX
            }
            onPositionChanged: (mouse) => {
                if (!pressed || slider.isActivated) return
                let nx = Math.max(0, Math.min(slider.maxKnobX, startKnobX + (mouse.x - startMouseX)))
                slider.knobX = nx
                if (nx >= slider.maxKnobX * 0.88) {
                    slider.isActivated = true
                    slider.knobX = slider.maxKnobX
                    fireTimer.start()
                }
            }
            onReleased: {
                if (!slider.isActivated) slider.knobX = 0
            }
        }
    }

    Timer { id: fireTimer; interval: 260; onTriggered: slider.activated() }
}
