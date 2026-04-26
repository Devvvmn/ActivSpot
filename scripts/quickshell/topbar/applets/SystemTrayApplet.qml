import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

Rectangle {
    id: root
    property var bar
    property bool editMode: false

    radius: bar.s(14)
    border.width: 0
    color: "transparent"

    property real targetW: trayRepeater.count > 0 ? (trayRow.width + bar.s(24)) : 0
    implicitWidth:  targetW
    implicitHeight: bar.barHeight
    visible: targetW > 0
    opacity: targetW > 0 ? 1 : 0
    clip: true

    Behavior on targetW  { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
    Behavior on opacity  { NumberAnimation { duration: 300 } }

    Row {
        id: trayRow
        anchors.centerIn: parent
        spacing: bar.s(10)

        Repeater {
            id: trayRepeater
            model: SystemTray.items
            delegate: Image {
                id: trayIcon
                required property var modelData
                source: modelData.icon || ""
                fillMode: Image.PreserveAspectFit
                sourceSize: Qt.size(bar.s(18), bar.s(18))
                width:  bar.s(18)
                height: bar.s(18)
                anchors.verticalCenter: parent.verticalCenter

                property bool isHovered: trayMouse.containsMouse
                opacity: isHovered ? 1.0 : 0.8
                scale:   isHovered ? 1.15 : 1.0

                Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                Behavior on scale   { NumberAnimation { duration: 250; easing.type: Easing.OutBack  } }

                QsMenuAnchor {
                    id: menuAnchor
                    anchor.window: bar
                    anchor.item:   trayIcon
                    anchor.edges:   Edges.Bottom
                    anchor.gravity: Edges.Bottom | Edges.Right
                    menu: modelData.menu
                }

                MouseArea {
                    id: trayMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: !root.editMode
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.LeftButton) {
                            modelData.activate();
                        } else if (mouse.button === Qt.MiddleButton) {
                            modelData.secondaryActivate();
                        } else if (mouse.button === Qt.RightButton) {
                            if (modelData.menu) menuAnchor.open();
                        }
                    }
                }
            }
        }
    }
}
