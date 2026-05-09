import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
  id: root

  // Injected properties
  property var pluginApi: null
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  // Settings
  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  // Bar layout awareness
  readonly property string screenName: screen?.name ?? ""
  readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
  readonly property bool isBarVertical: barPosition === "left" || barPosition === "right"
  readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
  readonly property real barFontSize: Style.getBarFontSizeForScreen(screenName)

  // Main instance reference
  readonly property var mainInstance: pluginApi?.mainInstance

  // Settings
  readonly property bool boldText: cfg.boldText ?? defaults.boldText ?? true

  // Sizing
  readonly property real contentWidth: capsuleRow.implicitWidth + Style.marginM * 2
  readonly property real contentHeight: capsuleHeight

  implicitWidth: isBarVertical ? capsuleHeight : contentWidth
  implicitHeight: isBarVertical ? contentHeight : capsuleHeight

  // Context menu
  NPopupContextMenu {
    id: contextMenu
    model: [
      { "label": pluginApi?.tr("context.refresh"), "action": "refresh", "icon": "refresh" },
      { "label": pluginApi?.tr("context.settings"), "action": "settings", "icon": "settings" }
    ]
    onTriggered: action => {
      contextMenu.close()
      PanelService.closeContextMenu(screen)
      if (action === "refresh") {
        root.mainInstance?.refresh()
      } else if (action === "settings") {
        if (pluginApi) BarService.openPluginSettings(screen, pluginApi.manifest)
      }
    }
  }

  Rectangle {
    id: visualCapsule
    x: Style.pixelAlignCenter(parent.width, width)
    y: Style.pixelAlignCenter(parent.height, height)
    width: root.contentWidth
    height: root.contentHeight
    color: mouseArea.containsMouse ? Color.mHover : Style.capsuleColor
    radius: Style.radiusL
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    RowLayout {
      id: capsuleRow
      anchors.centerIn: parent
      spacing: Style.marginS

      // Loading spinner
      NIcon {
        visible: root.mainInstance?.loading ?? false
        icon: "loader"
        color: Color.mOnSurface
        applyUiScale: true

        RotationAnimator on rotation {
          from: 0
          to: 360
          duration: 1000
          loops: Animation.Infinite
          running: root.mainInstance?.loading ?? false
        }
      }

      // AQI number colored by level
      NText {
        visible: !(root.mainInstance?.loading ?? false)
        text: root.mainInstance?.hasData ? root.mainInstance.getAqi().toString() : "--"
        color: {
          if (mouseArea.containsMouse) return Color.mOnHover
          if (root.mainInstance?.hasData) return root.mainInstance.getAqiColor(root.mainInstance.getAqi())
          return Color.mOnSurface
        }
        pointSize: root.barFontSize
        applyUiScale: false
        font.weight: root.boldText ? Font.Bold : Font.Normal
      }
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    hoverEnabled: true

    onClicked: mouse => {
      if (mouse.button === Qt.LeftButton) {
        if (pluginApi) pluginApi.togglePanel(root.screen, root)
      } else if (mouse.button === Qt.RightButton) {
        PanelService.showContextMenu(contextMenu, root, screen)
      } else if (mouse.button === Qt.MiddleButton) {
        root.mainInstance?.refresh()
      }
    }

    onEntered: {
      if (!root.mainInstance?.hasData) {
        TooltipService.show(root, pluginApi?.tr("widget.tooltip"), BarService.getTooltipDirection())
        return
      }
      var m = root.mainInstance
      var aqi = m.getAqi()
      var level = pluginApi?.tr(m.getAqiLevel(aqi))
      var city = m.getLocationName()
      var scaleLabel = pluginApi?.tr(m.aqiScale === "eu" ? "scale.eu" : "scale.us")
      var tip = scaleLabel + ": " + aqi + " — " + level
      if (city) tip += "\n" + city
      tip += "\n───────────────"
      tip += "\n" + pluginApi?.tr("pollutants.pm25Value", { value: m.pm25 })
      tip += "\n" + pluginApi?.tr("pollutants.pm10Value", { value: m.pm10 })
      tip += "\n" + pluginApi?.tr("pollutants.ozoneValue", { value: m.ozone })
      tip += "\n" + pluginApi?.tr("pollutants.no2Value", { value: m.no2 })
      tip += "\n" + pluginApi?.tr("pollutants.coValue", { value: m.co })
      tip += "\n" + pluginApi?.tr("pollutants.so2Value", { value: m.so2 })
      if (m.lastUpdate) tip += "\n───────────────\n" + pluginApi?.tr("panel.lastUpdate") + ": " + m.lastUpdate
      TooltipService.show(root, tip, BarService.getTooltipDirection())
    }

    onExited: {
      TooltipService.hide()
    }
  }
}
