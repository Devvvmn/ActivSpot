import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets
import qs.Services.UI

Item {
    id: root

    property var pluginApi: null
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""
    property int sectionWidgetIndex: -1
    property int sectionWidgetsCount: 0

    readonly property var mainInstance: pluginApi?.mainInstance

    readonly property real contentWidth: contentRow.implicitWidth + (Style.marginM * 2)
    readonly property real contentHeight: Style.capsuleHeight

    implicitWidth: contentWidth
    implicitHeight: contentHeight

    readonly property var providerIcons: ({
        "google": "brand-google",
        "cloudflare": "cloud",
        "opendns": "world",
        "adguard": "shield-check",
        "quad9": "lock"
    })

    Rectangle {
        id: visualCapsule
        x: Style.pixelAlignCenter(parent.width, width)
        y: Style.pixelAlignCenter(parent.height, height)
        width: root.contentWidth
        height: root.contentHeight
        color: mouseArea.containsMouse ? Color.mHover : Style.capsuleColor
        radius: height / 2
        border.color: Style.capsuleBorderColor
        border.width: Style.capsuleBorderWidth

        Behavior on color { ColorAnimation { duration: 150 } }

        RowLayout {
            id: contentRow
            anchors.centerIn: parent
            spacing: Style.marginS

            NIcon {
                icon: root.providerIcons[mainInstance?.activeProviderId || ""] || "globe"
                pointSize: Style.fontSizeS
                color: Color.mPrimary
            }

            NText {
                text: mainInstance?.currentDnsName || pluginApi?.tr("plugin.short_title") || "DNS"
                color: mouseArea.containsMouse ? Color.mOnHover : Color.mOnSurface
                pointSize: Style.barFontSize
                font.weight: Font.Medium
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            if (pluginApi) {
                pluginApi.openPanel(root.screen, root);
            }
        }
    }
}
