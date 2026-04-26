import QtQuick
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

    Behavior on targetW  { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
    Behavior on opacity  { NumberAnimation { duration: 300 } }
    Behavior on color    { ColorAnimation  { duration: 200 } }

    scale: isHovered ? 1.05 : 1.0
    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }

    Text {
        anchors.centerIn: parent
        text: "󰋗"
        font.family: "Iosevka Nerd Font"
        font.pixelSize: bar.s(22)
        color: root.isHovered ? bar.teal : bar.text
        Behavior on color { ColorAnimation { duration: 200 } }
    }

    MouseArea {
        id: helpMouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: !root.editMode
        onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle guide"])
    }
}
