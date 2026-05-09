import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services.UI
import qs.Widgets
import qs.Modules.DesktopWidgets

DraggableDesktopWidget {
  id: root
  property var pluginApi: null

  implicitWidth: Math.round(240 * widgetScale)
  implicitHeight: Math.round(140 * widgetScale)
  width: implicitWidth
  height: implicitHeight

  readonly property var mainInstance: pluginApi?.mainInstance
  readonly property bool hasData: mainInstance?.hasData ?? false
  readonly property int aqi: hasData ? mainInstance.getAqi() : 0
  readonly property string aqiColor: hasData ? mainInstance.getAqiColor(aqi) : Color.mOnSurfaceVariant

  ColumnLayout {
    anchors {
      fill: parent
      margins: Style.marginL * root.widgetScale
    }
    spacing: Style.marginS * root.widgetScale

    // AQI number
    NText {
      Layout.alignment: Qt.AlignHCenter
      text: root.hasData ? root.aqi.toString() : "--"
      pointSize: Style.fontSizeXXL * 2
      font.weight: Font.Bold
      color: root.aqiColor
    }

    // Level label
    NText {
      Layout.alignment: Qt.AlignHCenter
      text: root.hasData ? pluginApi?.tr(root.mainInstance.getAqiLevel(root.aqi)) : pluginApi?.tr("desktop.noData")
      pointSize: Style.fontSizeM
      color: root.aqiColor
    }

    // City name
    NText {
      Layout.alignment: Qt.AlignHCenter
      visible: root.hasData
      text: root.mainInstance?.getLocationName() ?? ""
      pointSize: Style.fontSizeS
      color: Color.mOnSurfaceVariant
    }

    // PM2.5 / PM10 row
    RowLayout {
      Layout.alignment: Qt.AlignHCenter
      visible: root.hasData
      spacing: Style.marginL * root.widgetScale

      NText {
        text: pluginApi?.tr("pollutants.pm25Short", { value: root.hasData ? Math.round(root.mainInstance.pm25 * 10) / 10 : "--" })
        pointSize: Style.fontSizeS
        color: Color.mOnSurfaceVariant
      }

      NText {
        text: pluginApi?.tr("pollutants.pm10Short", { value: root.hasData ? Math.round(root.mainInstance.pm10 * 10) / 10 : "--" })
        pointSize: Style.fontSizeS
        color: Color.mOnSurfaceVariant
      }
    }
  }

  // Hover tip overlay
  Rectangle {
    id: hoverTip
    width: root.width - (Style.marginL * root.widgetScale)
    height: root.height - (Style.marginL * root.widgetScale)
    anchors.centerIn: parent
    radius: Style.radiusL
    color: Color.mShadow
    visible: false
    opacity: 0

    Behavior on opacity {
      NumberAnimation {
        duration: 200
        easing.type: Easing.InOutQuad
      }
    }

    NText {
      anchors.centerIn: parent
      text: pluginApi?.tr("desktop.tipLeft") + "\n" + pluginApi?.tr("desktop.tipMiddle") + "\n" + pluginApi?.tr("desktop.tipRight")
      pointSize: Style.fontSizeS
      color: Color.mOnSurface
      horizontalAlignment: Text.AlignHCenter
    }
  }

  Timer {
    id: hoverTimer
    interval: 1500
    repeat: false
    onTriggered: {
      hoverTip.visible = true
      hoverTip.opacity = 0.85
    }
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
    hoverEnabled: true

    onClicked: mouse => {
      if (mouse.button === Qt.LeftButton) {
        if (pluginApi) pluginApi.togglePanel(null, root)
      } else if (mouse.button === Qt.MiddleButton) {
        root.mainInstance?.refresh()
      } else if (mouse.button === Qt.RightButton) {
        BarService.openPluginSettings(null, pluginApi.manifest)
      }
    }

    onEntered: {
      hoverTimer.restart()
    }

    onExited: {
      hoverTimer.stop()
      hoverTip.opacity = 0
      hoverTip.visible = false
    }
  }
}
