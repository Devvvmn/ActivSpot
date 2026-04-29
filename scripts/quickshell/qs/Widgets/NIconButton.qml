import QtQuick
import qs.Commons
import qs.Services.UI

// ActivSpot compat for Noctalia NIconButton.
// Renders as a pill-shaped icon button matching ActivSpot's capsule style.
Item {
    id: root

    // Noctalia NIconButton API
    property real baseSize:   Style.baseWidgetSize
    property bool applyUiScale: true

    property string icon: ""
    property var    tooltipText
    property string tooltipDirection: "auto"
    property bool   allowClickWhenDisabled: false
    property bool   handleWheel: false
    property bool   hovering: false

    property color colorBg:          Color.smartAlpha(Color.mSurfaceVariant)
    property color colorFg:          Color.mPrimary
    property color colorBgHover:     Color.mHover
    property color colorFgHover:     Color.mOnHover
    property color colorBorder:      Color.mOutline
    property color colorBorderHover: Color.mOutline
    property real  customRadius: -1

    // Border / color aliases for backwards compat
    property alias border: pill.border
    property alias radius: pill.radius
    property alias color:  pill.color

    signal entered
    signal exited
    signal clicked
    signal rightClicked
    signal middleClicked
    signal wheel(int angleDelta)

    readonly property real buttonSize: applyUiScale
        ? Style.toOdd(baseSize * Style.uiScaleRatio)
        : Style.toOdd(baseSize)

    implicitWidth:  buttonSize
    implicitHeight: buttonSize

    opacity: enabled ? 1.0 : 0.6

    Rectangle {
        id: pill
        anchors.centerIn: parent
        width:  root.buttonSize
        height: root.buttonSize
        radius: root.customRadius >= 0
            ? root.customRadius
            : Style.iRadiusL
        color:        root.enabled && root.hovering ? root.colorBgHover  : root.colorBg
        border.color: root.enabled && root.hovering ? root.colorBorderHover : root.colorBorder
        border.width: Style.borderS

        Behavior on color        { ColorAnimation { duration: Style.animationFast; easing.type: Easing.InOutQuad } }
        Behavior on border.color { ColorAnimation { duration: Style.animationFast; easing.type: Easing.InOutQuad } }

        NIcon {
            id: iconItem
            icon: root.icon
            pointSize: Style.toOdd(pill.width * 0.48)
            applyUiScale: root.applyUiScale
            color: root.enabled && root.hovering ? root.colorFgHover : root.colorFg
            anchors.centerIn: parent

            Behavior on color { ColorAnimation { duration: Style.animationFast; easing.type: Easing.InOutQuad } }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: true
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        hoverEnabled: true

        onEntered: {
            root.hovering = root.enabled
            root.entered()
        }
        onExited: {
            root.hovering = false
            root.exited()
        }
        onClicked: mouse => {
            if (!root.enabled && !root.allowClickWhenDisabled) return
            if (mouse.button === Qt.LeftButton)        root.clicked()
            else if (mouse.button === Qt.RightButton)  root.rightClicked()
            else if (mouse.button === Qt.MiddleButton) root.middleClicked()
        }
        onWheel: wheel => {
            if (root.handleWheel) root.wheel(wheel.angleDelta.y)
            wheel.accepted = false
        }
    }
}
