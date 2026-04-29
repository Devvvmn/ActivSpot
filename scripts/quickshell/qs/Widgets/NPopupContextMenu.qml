import QtQuick
import QtQuick.Controls
import qs.Commons

Menu {
    id: root

    property var model: []
    signal triggered(string action)

    background: Rectangle {
        implicitWidth: 190
        color:   Color.mSurfaceContainerHigh
        radius:  Style.radiusS
        border.color: Qt.rgba(Color.mOutline.r, Color.mOutline.g, Color.mOutline.b, 0.5)
        border.width: 1
    }

    Instantiator {
        model: root.model
        delegate: MenuItem {
            required property var modelData
            contentItem: Row {
                spacing: Style.marginS
                leftPadding: Style.marginXS
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: (modelData.icon || "") !== ""
                    text: IconsTabler.icons[modelData.icon] ?? ""
                    font.family: "tabler-icons"
                    font.pointSize: Style.fontSizeM
                    color: Color.mOnSurfaceVariant
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.label || ""
                    font.family: "JetBrains Mono"
                    font.pixelSize: Style.fontSizeM * 1.3
                    color: Color.mOnSurface
                }
            }
            background: Rectangle {
                color: parent.highlighted
                    ? Qt.rgba(Color.mPrimary.r, Color.mPrimary.g, Color.mPrimary.b, 0.18)
                    : "transparent"
                radius: Style.radiusXXS
            }
            onTriggered: root.triggered(modelData.action || "")
        }
        onObjectAdded:   (i, o) => root.insertItem(i, o)
        onObjectRemoved: (i, o) => root.removeItem(o)
    }

    function open() { popup() }
}
