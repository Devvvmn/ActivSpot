import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
  id: root

  property var pluginApi: null
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  readonly property bool pillDirection: BarService.getPillDirection(root)
  readonly property var mainInstance: pluginApi?.mainInstance

  readonly property string connectedColorKey: pluginApi?.pluginSettings?.connectedColor ?? pluginApi?.manifest?.metadata?.defaultSettings?.connectedColor ?? "primary"

  readonly property string disconnectedColorKey: pluginApi?.pluginSettings?.disconnectedColor ?? pluginApi?.manifest?.metadata?.defaultSettings?.disconnectedColor ?? "none"

  readonly property color resolvedIconColor: {
    var key = (mainInstance?.warpConnected ?? false) ? connectedColorKey : disconnectedColorKey;
    var resolved = Color.resolveColorKeyOptional(key);
    // resolveColorKeyOptional ritorna "transparent" per "none" — fallback al colore neutro
    if (!resolved || resolved === "transparent" || resolved.a === 0)
      return mouseArea.containsMouse ? Color.mOnHover : Color.mOnSurface;
    return resolved;
  }

  readonly property real contentWidth: {
    if (!(mainInstance?.warpInstalled ?? false)) {
      return Style.capsuleHeight;
    }
    if ((mainInstance?.warpMode ?? "") !== "") {
      return contentRow.implicitWidth + Style.marginM * 2;
    }
    return Style.capsuleHeight;
  }
  readonly property real contentHeight: Style.capsuleHeight

  implicitWidth: contentWidth
  implicitHeight: contentHeight

  Rectangle {
    id: visualCapsule
    x: Style.pixelAlignCenter(parent.width, width)
    y: Style.pixelAlignCenter(parent.height, height)
    width: root.contentWidth
    height: root.contentHeight
    color: mouseArea.containsMouse ? Color.mHover : Style.capsuleColor
    radius: Style.radiusL

    RowLayout {
      id: contentRow
      anchors.centerIn: parent
      spacing: Style.marginS
      layoutDirection: Qt.LeftToRight

      Item {
        implicitWidth: Style.fontSizeXXL
        implicitHeight: Style.fontSizeXXL

        CloudflareIcon {
          anchors.fill: parent
          pointSize: Style.fontSizeXXL
          applyUiScale: false
          color: root.resolvedIconColor
          opacity: (mainInstance?.isRefreshing ?? false) ? 0.5 : 1.0
        }

        Rectangle {
          visible: !(mainInstance?.warpConnected ?? false)
          anchors.centerIn: parent
          width: parent.width * 1.1
          height: 2
          radius: Style.radiusXXXS
          color: root.resolvedIconColor
          opacity: 0.9
          rotation: -45
        }
      }

      NText {
        visible: (mainInstance?.warpInstalled ?? false) && (mainInstance?.warpMode ?? "") !== ""
        text: mainInstance?.warpMode ?? ""
        pointSize: Style.fontSizeXS
        color: root.resolvedIconColor
        Layout.leftMargin: Style.marginXS
        Layout.rightMargin: Style.marginS
      }
    }
  }

  NPopupContextMenu {
    id: contextMenu

    model: [
      {
        "label": (mainInstance?.warpConnected ?? false) ? pluginApi?.tr("context.disconnect") : pluginApi?.tr("context.connect"),
        "action": "toggle-warp",
        "icon": (mainInstance?.warpConnected ?? false) ? "plug-x" : "plug",
        "enabled": mainInstance?.warpInstalled ?? false
      },
      {
        "label": pluginApi?.tr("actions.widget-settings"),
        "action": "widget-settings",
        "icon": "settings"
      }
    ]

    onTriggered: action => {
      contextMenu.close()
      PanelService.closeContextMenu(screen)

      if (action === "widget-settings") {
        BarService.openPluginSettings(screen, pluginApi.manifest)
      } else if (action === "toggle-warp") {
        mainInstance?.toggleWarp()
      }
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton

    onClicked: mouse => {
      if (mouse.button === Qt.LeftButton) {
        pluginApi?.openPanel(root.screen, root)
      } else if (mouse.button === Qt.RightButton) {
        PanelService.showContextMenu(contextMenu, root, screen)
      }
    }
  }
}
