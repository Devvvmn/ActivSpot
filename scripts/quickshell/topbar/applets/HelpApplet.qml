import QtQuick
import QtQuick.Effects
import Quickshell

Rectangle {
    id: root
    property var bar
    property bool editMode: false

    property bool isHovered: helpMouse.containsMouse

    radius: bar.s(14)
    border.width: 0
    color: "transparent"

    implicitWidth:  targetW
    implicitHeight: bar.barHeight
    clip: true

    property real targetW: bar.showHelpIcon ? bar.barHeight : 0
    visible: targetW > 0 || opacity > 0
    opacity: bar.showHelpIcon ? 1.0 : 0.0

    Behavior on targetW  { NumberAnimation { duration: 240; easing.type: Easing.OutQuint } }
    Behavior on opacity  { NumberAnimation { duration: 180 } }

    scale: helpMouse.pressed ? 0.95 : (isHovered ? 1.04 : 1.0)
    Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }

    Text {
        anchors.centerIn: parent
        text: "󰋗"
        font.family: "Iosevka Nerd Font"
        font.pixelSize: bar.s(22)
        color: root.isHovered ? bar.teal : bar.adaptiveText
        Behavior on color { ColorAnimation { duration: 200 } }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.55)
            shadowBlur: 0.5
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 1
        }
    }

    MouseArea {
        id: helpMouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: !root.editMode
        onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle guide"])
    }
}
