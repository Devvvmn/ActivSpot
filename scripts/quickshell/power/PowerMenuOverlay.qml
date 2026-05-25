import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../"
import "./"

Item {
    id: root

    MatugenColors { id: _theme }
    Scaler { id: scaler; currentWidth: Screen.width }
    function s(v) { return scaler.s(v) }

    property real showAnim: 0
    NumberAnimation on showAnim {
        from: 0; to: 1; duration: 320; easing.type: Easing.OutQuart; running: true
    }

    function close() {
        Quickshell.execDetached(["sh", "-c", "echo 'close' > /tmp/qs_widget_state"])
    }

    function triggerAction(cmd) {
        Quickshell.execDetached(["sh", "-c", cmd])
        close()
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.78 * root.showAnim)
    }

    MouseArea { anchors.fill: parent; onClicked: root.close() }

    // Clock
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: btnRow.top
        anchors.bottomMargin: s(56)
        spacing: s(6)
        opacity: root.showAnim
        scale: 0.93 + 0.07 * root.showAnim
        transformOrigin: Item.Bottom

        Timer {
            interval: 1000; running: true; repeat: true
            onTriggered: {
                clockLabel.text = Qt.formatTime(new Date(), "hh:mm")
                dateLabel.text = Qt.formatDate(new Date(), "dddd, MMMM d")
            }
        }

        Text {
            id: clockLabel
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(new Date(), "hh:mm")
            font.family: "Inter"
            font.weight: Font.Thin
            font.pixelSize: s(80)
            font.letterSpacing: s(-1)
            color: "white"
        }

        Text {
            id: dateLabel
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDate(new Date(), "dddd, MMMM d")
            font.family: "Inter"
            font.weight: Font.Light
            font.pixelSize: s(15)
            color: Qt.rgba(1, 1, 1, 0.45)
        }
    }

    // Action buttons
    Row {
        id: btnRow
        anchors.centerIn: parent
        anchors.verticalCenterOffset: s(30)
        spacing: s(20)

        opacity: root.showAnim
        scale: 0.93 + 0.07 * root.showAnim
        transformOrigin: Item.Center

        Repeater {
            model: [
                { label: "Sleep",     iconFile: "icons/sleep.svg",   cmd: "bash ~/.config/hypr/scripts/lock.sh & systemctl suspend", colorKey: "blue"  },
                { label: "Restart",   iconFile: "icons/restart.svg", cmd: "systemctl reboot",                                       colorKey: "peach" },
                { label: "Shut Down", iconFile: "icons/power.svg",   cmd: "systemctl poweroff -i",                                  colorKey: "red"   },
                { label: "Log Out",   iconFile: "icons/logout.svg",  cmd: "loginctl terminate-user $USER",                          colorKey: "mauve" }
            ]
            delegate: PowerButton {
                label:       modelData.label
                iconSource:  Qt.resolvedUrl(modelData.iconFile)
                accentColor: _theme[modelData.colorKey] || _theme.blue
                btnSize:     s(110)
                iconSize:    s(36)
                onClicked:   root.triggerAction(modelData.cmd)
            }
        }
    }

    // Cancel
    Rectangle {
        id: cancelBtn
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: btnRow.bottom
        anchors.topMargin: s(32)
        width: s(200)
        height: s(44)
        radius: height / 2
        color: cancelMa.pressed ? Qt.rgba(1, 1, 1, 0.28) : Qt.rgba(1, 1, 1, 0.12)
        border.color: Qt.rgba(1, 1, 1, 0.18)
        border.width: 1
        opacity: root.showAnim

        Behavior on color { ColorAnimation { duration: 100 } }

        Text {
            anchors.centerIn: parent
            text: "Cancel"
            font.family: "Inter"
            font.weight: Font.Medium
            font.pixelSize: s(15)
            color: "white"
        }

        MouseArea { id: cancelMa; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.close() }
    }
}
