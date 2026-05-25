import QtQuick
import QtQuick.Effects
import Quickshell

Item {
    id: root

    property string label: ""
    property string iconSource: ""
    property color accentColor: "#ffffff"
    property real btnSize: 110
    property real iconSize: 36

    signal clicked()

    width: btnSize
    height: btnSize + labelText.implicitHeight + s(10)

    function s(v) { return Math.round(v * Math.max(0.5, Math.min(2.2, Screen.width / 1920.0))) }

    Rectangle {
        id: btn
        width: root.btnSize
        height: root.btnSize
        radius: s(28)
        color: ma.pressed
            ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.45)
            : ma.containsMouse
                ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.28)
                : Qt.rgba(1, 1, 1, 0.10)
        border.color: ma.containsMouse
            ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.55)
            : Qt.rgba(1, 1, 1, 0.18)
        border.width: 1

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }

        scale: ma.pressed ? 0.93 : 1.0
        Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutQuad } }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: ma.containsMouse
            shadowColor: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.4)
            shadowBlur: 0.8
            shadowVerticalOffset: 8
            shadowHorizontalOffset: 0
        }

        Image {
            id: icon
            anchors.centerIn: parent
            width: root.iconSize
            height: root.iconSize
            source: root.iconSource
            smooth: true
            antialiasing: true

            layer.enabled: true
            layer.effect: MultiEffect {
                colorization: ma.containsMouse ? 1.0 : 0.0
                colorizationColor: root.accentColor
                Behavior on colorization { NumberAnimation { duration: 150 } }
            }

            opacity: ma.containsMouse ? 1.0 : 0.80
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.clicked()
        }
    }

    Text {
        id: labelText
        anchors.top: btn.bottom
        anchors.topMargin: s(10)
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.label
        font.family: "Inter"
        font.weight: Font.Medium
        font.pixelSize: s(13)
        color: Qt.rgba(1, 1, 1, 0.70)
    }
}
