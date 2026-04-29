import QtQuick
import Quickshell

Rectangle {
    id: root
    property var bar
    property bool editMode: false

    radius: bar.s(16)
    border.width: 1
    border.color: bar.pillBorderColor
    color: bar.pillColor
    Behavior on color        { ColorAnimation { duration: 520; easing.type: Easing.InOutCubic } }
    Behavior on border.color { ColorAnimation { duration: 520; easing.type: Easing.InOutCubic } }

    property real targetW: bar.wsModel.count > 0 ? (wsRow.width + bar.s(16)) : 0
    implicitWidth:  targetW
    implicitHeight: bar.barHeight
    visible: targetW > 0
    opacity: bar.wsModel.count > 0 ? 1 : 0
    clip: true

    Behavior on opacity { NumberAnimation { duration: 300 } }

    Row {
        id: wsRow
        anchors.centerIn: parent
        spacing: bar.s(3)

        Repeater {
            model: bar.wsModel
            delegate: Rectangle {
                id: wsPill
                required property var model
                property bool isHovered: wsMouse.containsMouse
                property string stateLabel: model.wsState
                property string wsName:     model.wsId
                property bool isActive:   stateLabel === "active"
                property bool isOccupied: stateLabel === "occupied" || isActive

                width:  bar.s(34)
                height: bar.s(24)
                radius: width / 2

                color: isOccupied
                    ? Qt.rgba(bar.mauve.r, bar.mauve.g, bar.mauve.b, isActive ? 0.32 : 0.24)
                    : (isHovered
                        ? Qt.rgba(bar.text.r, bar.text.g, bar.text.b, 0.18)
                        : Qt.rgba(bar.text.r, bar.text.g, bar.text.b, 0.10))

                border.width: 1
                border.color: Qt.rgba(bar.mauve.r, bar.mauve.g, bar.mauve.b, isActive ? 0.85 : 0.0)
                Behavior on border.color { ColorAnimation { duration: 220; easing.type: Easing.OutCubic } }

                scale: isHovered && !isActive ? 1.08 : 1.0
                Behavior on color  { ColorAnimation  { duration: 200 } }
                Behavior on scale  { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

                Text {
                    anchors.centerIn: parent
                    text: wsName
                    font.family: "JetBrains Mono"
                    font.pixelSize: bar.s(11)
                    font.weight: Font.Bold
                    color: wsPill.isOccupied ? bar.mauve : bar.subtext0
                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                MouseArea {
                    id: wsMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: !root.editMode
                    onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh " + wsName])
                }
            }
        }
    }
}
