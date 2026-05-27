import QtQuick
import QtQuick.Effects
import Quickshell

Rectangle {
    id: root
    property var bar
    property var barZone
    property bool editMode: false

    color: "transparent"
    border.width: 0

    implicitHeight: bar.barHeight
    implicitWidth:  icon.implicitWidth + bar.s(16)

    scale: ma.pressed ? 0.95 : (ma.containsMouse ? 1.04 : 1.0)
    Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }

    Text {
        id: icon
        anchors.centerIn: parent
        text: "󰀄"
        font.family: "Iosevka Nerd Font"
        font.pixelSize: bar.s(18)
        color: ma.containsMouse ? bar.mauve : barZone.adaptiveText
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
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        enabled: !root.editMode
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["bash", "-c", "echo 'sysinfo' > /tmp/qs_widget_state"])
    }
}
