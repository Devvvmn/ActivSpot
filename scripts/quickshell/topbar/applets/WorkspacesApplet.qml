import QtQuick
import Quickshell

Rectangle {
    id: root
    property var bar
    property bool editMode: false

    radius: bar.s(14)
    border.width: 1
    border.color: Qt.rgba(bar.text.r, bar.text.g, bar.text.b, 0.05)
    color: Qt.rgba(bar.base.r, bar.base.g, bar.base.b, 0.75)

    property real targetW: bar.wsModel.count > 0 ? (wsRow.width + bar.s(20)) : 0
    implicitWidth:  targetW
    implicitHeight: bar.barHeight
    visible: targetW > 0
    opacity: bar.wsModel.count > 0 ? 1 : 0
    clip: true

    Behavior on opacity { NumberAnimation { duration: 300 } }

    Row {
        id: wsRow
        anchors.centerIn: parent
        spacing: bar.s(6)

        Repeater {
            model: bar.wsModel
            delegate: Rectangle {
                id: wsPill
                required property var model
                property bool isHovered: wsMouse.containsMouse
                property string stateLabel: model.wsState
                property string wsName:     model.wsId

                width:  bar.s(32)
                height: bar.s(32)
                radius: bar.s(10)

                color: stateLabel === "active"
                    ? bar.mauve
                    : (isHovered
                        ? Qt.rgba(bar.overlay0.r, bar.overlay0.g, bar.overlay0.b, 0.9)
                        : (stateLabel === "occupied"
                            ? Qt.rgba(bar.surface2.r, bar.surface2.g, bar.surface2.b, 0.9)
                            : "transparent"))

                scale: isHovered && stateLabel !== "active" ? 1.08 : 1.0
                Behavior on color { ColorAnimation { duration: 250 } }
                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

                Text {
                    anchors.centerIn: parent
                    text: wsName
                    font.family: "JetBrains Mono"
                    font.pixelSize: bar.s(14)
                    font.weight: stateLabel === "active"
                        ? Font.Black
                        : (stateLabel === "occupied" ? Font.Bold : Font.Medium)
                    color: stateLabel === "active"
                        ? bar.crust
                        : (isHovered
                            ? bar.crust
                            : (stateLabel === "occupied" ? bar.text : bar.overlay0))
                    Behavior on color { ColorAnimation { duration: 250 } }
                }

                MouseArea {
                    id: wsMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh " + wsName])
                }
            }
        }
    }
}
