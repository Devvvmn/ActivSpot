import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
  id: root
  property var pluginApi: null

  readonly property var geometryPlaceholder: panelContainer
  readonly property bool allowAttach: true

  property real contentPreferredWidth: 320 * Style.uiScaleRatio
  property real contentPreferredHeight: panelColumn.implicitHeight + Style.marginXL * 2

  readonly property var mainInstance: pluginApi?.mainInstance
  readonly property bool hasData: mainInstance?.hasData ?? false
  readonly property int aqi: hasData ? mainInstance.getAqi() : 0
  readonly property string aqiColor: hasData ? mainInstance.getAqiColor(aqi) : Color.mOnSurfaceVariant
  readonly property string levelKey: hasData ? mainInstance.getAqiLevel(aqi) : "levels.unknown"

  anchors.fill: parent

  Rectangle {
    id: panelContainer
    anchors.fill: parent
    color: "transparent"

    ColumnLayout {
      id: panelColumn
      anchors {
        left: parent.left
        right: parent.right
        top: parent.top
        margins: Style.marginXL
      }

      // ======== Data content (hidden when no data) ========
      ColumnLayout {
        Layout.fillWidth: true
        visible: root.hasData

        // ======== HERO: giant AQI number ========
        Item { Layout.preferredHeight: Style.marginL }

        NText {
          Layout.alignment: Qt.AlignHCenter
          text: root.hasData ? root.aqi.toString() : "--"
          pointSize: Style.fontSizeXXL * 3.5
          font.weight: Font.Bold
          color: root.aqiColor
        }

        // Level label
        NText {
          Layout.alignment: Qt.AlignHCenter
          text: pluginApi?.tr(root.levelKey)
          pointSize: Style.fontSizeL
          font.weight: Font.DemiBold
          color: root.aqiColor
        }

        Item { Layout.preferredHeight: Style.marginS }

        // Scale label
        NText {
          Layout.alignment: Qt.AlignHCenter
          text: pluginApi?.tr(root.mainInstance?.aqiScale === "eu" ? "scale.eu" : "scale.us")
          pointSize: Style.fontSizeS
          color: Color.mOnSurfaceVariant
        }

        Item { Layout.preferredHeight: Style.marginM }

        // ======== Location pill ========
        Rectangle {
          Layout.alignment: Qt.AlignHCenter
          Layout.preferredWidth: locationText.implicitWidth + Style.marginL * 2
          Layout.preferredHeight: locationText.implicitHeight + Style.marginS * 2
          radius: height / 2
          color: Color.mSurfaceVariant

          NText {
            id: locationText
            anchors.centerIn: parent
            text: {
              var parts = []
              var city = root.mainInstance?.getLocationName() ?? ""
              if (city) parts.push(city)
              var update = root.mainInstance?.lastUpdate ?? ""
              if (update) parts.push(update)
              return parts.join(" · ")
            }
            pointSize: Style.fontSizeS
            color: Color.mOnSurfaceVariant
          }
        }

        Item { Layout.preferredHeight: Style.marginXL }

        // ======== Pollutant rows ========
        Repeater {
          model: root.hasData ? [
            { key: "pm25", value: root.mainInstance.pm25, pollutant: "pm25" },
            { key: "pm10", value: root.mainInstance.pm10, pollutant: "pm10" },
            { key: "ozone", value: root.mainInstance.ozone, pollutant: "ozone" },
            { key: "no2", value: root.mainInstance.no2, pollutant: "no2" },
            { key: "co", value: root.mainInstance.co, pollutant: "co" },
            { key: "so2", value: root.mainInstance.so2, pollutant: "so2" }
          ] : []

          delegate: ColumnLayout {
            required property var modelData
            required property int index
            Layout.fillWidth: true

            // Divider (top, except first)
            Rectangle {
              visible: index > 0
              Layout.fillWidth: true
              height: 1
              color: Color.mOutline
              opacity: 0.3
            }

            // Row content
            RowLayout {
              Layout.fillWidth: true
              Layout.topMargin: Style.marginM
              Layout.bottomMargin: Style.marginM
              spacing: Style.marginS

              // Colored dot
              Rectangle {
                width: 6 * Style.uiScaleRatio
                height: width
                radius: width / 2
                color: root.mainInstance?.getPollutantColor(modelData.pollutant, modelData.value) ?? Color.mOnSurfaceVariant
                Layout.alignment: Qt.AlignVCenter
              }

              // Name
              NText {
                Layout.fillWidth: true
                text: pluginApi?.tr("pollutants." + modelData.key)
                pointSize: Style.fontSizeM
                color: Color.mOnSurface
              }

              // Value
              NText {
                text: Math.round(modelData.value * 10) / 10
                pointSize: Style.fontSizeM
                font.weight: Font.DemiBold
                color: Color.mOnSurface
              }

              // Unit
              NText {
                text: pluginApi?.tr("unit.ugm3")
                pointSize: Style.fontSizeXS
                color: Color.mOnSurfaceVariant
                Layout.alignment: Qt.AlignBaseline
              }
            }
          }
        }
      }

      // ======== No data / loading / error overlay ========
      ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: Style.marginXL * 3
        Layout.bottomMargin: Style.marginXL * 3
        visible: !root.hasData
        spacing: Style.marginM

        NText {
          Layout.alignment: Qt.AlignHCenter
          text: {
            if (root.mainInstance?.loading) return pluginApi?.tr("panel.loading")
            if (root.mainInstance?.errorMessage) return root.mainInstance.errorMessage
            return pluginApi?.tr("panel.noData")
          }
          pointSize: Style.fontSizeL
          color: Color.mOnSurfaceVariant
          horizontalAlignment: Text.AlignHCenter
          wrapMode: Text.WordWrap
          Layout.fillWidth: true
        }
      }

      Item { Layout.preferredHeight: Style.marginXL }

      // ======== Footer ========
      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        NButton {
          Layout.fillWidth: true
          text: pluginApi?.tr("panel.refresh")
          onClicked: {
            Logger.d("Air Quality", "Refreshing from panel...")
            root.mainInstance?.refresh()
          }
        }

        NIconButton {
          icon: "settings"
          onClicked: {
            if (!pluginApi) return
            Logger.d("Air Quality", "Opening settings from panel...")
            BarService.openPluginSettings(pluginApi.panelOpenScreen, pluginApi.manifest)
            pluginApi.closePanel(pluginApi.panelOpenScreen)
          }
        }
      }
    }
  }
}
