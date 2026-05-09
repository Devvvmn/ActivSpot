import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  property var pluginApi: null

  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  // Edit copies of settings
  property string editAqiScale: cfg.aqiScale ?? defaults.aqiScale ?? "us"
  property bool editUseNoctaliaLocation: cfg.useNoctaliaLocation ?? defaults.useNoctaliaLocation ?? true
  property string editCustomLatitude: cfg.customLatitude ?? defaults.customLatitude ?? ""
  property string editCustomLongitude: cfg.customLongitude ?? defaults.customLongitude ?? ""
  property int editRefreshInterval: cfg.refreshInterval ?? defaults.refreshInterval ?? 30
  property bool editBoldText: cfg.boldText ?? defaults.boldText ?? true
  property string editDataSource: cfg.dataSource ?? defaults.dataSource ?? "open-meteo"
  property string editAqicnToken: cfg.aqicnToken ?? defaults.aqicnToken ?? ""

  spacing: Style.marginM

  // --- Data Source ---
  RowLayout {
    Layout.fillWidth: true
    spacing: Style.marginM

    ColumnLayout {
      Layout.fillWidth: true
      spacing: Style.marginXS

      NText {
        text: pluginApi?.tr("settings.dataSource")
        pointSize: Style.fontSizeM
        color: Color.mOnSurface
      }

      NText {
        text: pluginApi?.tr("settings.dataSourceDesc")
        pointSize: Style.fontSizeS
        color: Color.mOnSurfaceVariant
      }
    }

    NComboBox {
      Layout.preferredWidth: 260 * Style.uiScaleRatio
      Layout.preferredHeight: Style.baseWidgetSize
      model: [
        { key: "open-meteo", name: pluginApi?.tr("settings.dataSourceOpenMeteo") },
        { key: "aqicn", name: pluginApi?.tr("settings.dataSourceAqicn") }
      ]
      currentKey: root.editDataSource
      onSelected: key => {
        root.editDataSource = key
        if (key === "aqicn") root.editAqiScale = "us"
      }
    }
  }

  // --- AQICN Token ---
  NTextInput {
    Layout.fillWidth: true
    visible: root.editDataSource === "aqicn"
    label: pluginApi?.tr("settings.aqicnToken")
    description: pluginApi?.tr("settings.aqicnTokenDesc")
    placeholderText: pluginApi?.tr("settings.aqicnTokenPlaceholder")
    text: root.editAqicnToken
    onTextChanged: root.editAqicnToken = text
  }

  // --- AQI Scale ---
  RowLayout {
    Layout.fillWidth: true
    spacing: Style.marginM

    ColumnLayout {
      Layout.fillWidth: true
      spacing: Style.marginXS

      NText {
        text: pluginApi?.tr("settings.aqiScale")
        pointSize: Style.fontSizeM
        color: Color.mOnSurface
      }

      NText {
        text: pluginApi?.tr("settings.aqiScaleDesc")
        pointSize: Style.fontSizeS
        color: Color.mOnSurfaceVariant
      }
    }

    NComboBox {
      Layout.preferredWidth: 180 * Style.uiScaleRatio
      Layout.preferredHeight: Style.baseWidgetSize
      enabled: root.editDataSource !== "aqicn"
      model: [
        { key: "us", name: pluginApi?.tr("settings.aqiScaleUs") },
        { key: "eu", name: pluginApi?.tr("settings.aqiScaleEu") }
      ]
      currentKey: root.editAqiScale
      onSelected: key => {
        root.editAqiScale = key
      }
    }
  }

  // --- Location ---
  Item {
    Layout.fillWidth: true
    Layout.preferredHeight: locationToggle.implicitHeight
    NToggle {
      id: locationToggle
      anchors.fill: parent
      label: pluginApi?.tr("settings.useNoctaliaLocation")
      description: pluginApi?.tr("settings.useNoctaliaLocationDesc")
      checked: root.editUseNoctaliaLocation
      onToggled: checked => root.editUseNoctaliaLocation = checked
    }
  }

  NTextInput {
    Layout.fillWidth: true
    visible: !root.editUseNoctaliaLocation
    label: pluginApi?.tr("settings.customLatitude")
    description: pluginApi?.tr("settings.customLocationDesc")
    placeholderText: "41.3851"
    text: root.editCustomLatitude
    onTextChanged: root.editCustomLatitude = text
  }

  NTextInput {
    Layout.fillWidth: true
    visible: !root.editUseNoctaliaLocation
    label: pluginApi?.tr("settings.customLongitude")
    placeholderText: "2.1734"
    text: root.editCustomLongitude
    onTextChanged: root.editCustomLongitude = text
  }

  // --- Refresh Interval ---
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      label: pluginApi?.tr("settings.refreshInterval")
      description: pluginApi?.tr("settings.refreshIntervalDesc") + root.editRefreshInterval
    }

    NSlider {
      Layout.fillWidth: true
      from: 5
      to: 120
      stepSize: 5
      value: root.editRefreshInterval
      onValueChanged: root.editRefreshInterval = value
    }
  }

  // --- Appearance ---
  Item {
    Layout.fillWidth: true
    Layout.preferredHeight: boldToggle.implicitHeight
    NToggle {
      id: boldToggle
      anchors.fill: parent
      label: pluginApi?.tr("settings.boldText")
      description: pluginApi?.tr("settings.boldTextDesc")
      checked: root.editBoldText
      onToggled: checked => root.editBoldText = checked
    }
  }

  // Required — called by the shell when user saves
  function saveSettings() {
    if (!pluginApi) {
      Logger.e("Air Quality", "Cannot save: pluginApi is null")
      return
    }

    var locationChanged = pluginApi.pluginSettings.useNoctaliaLocation !== root.editUseNoctaliaLocation
        || pluginApi.pluginSettings.customLatitude !== root.editCustomLatitude
        || pluginApi.pluginSettings.customLongitude !== root.editCustomLongitude
    var scaleChanged = pluginApi.pluginSettings.aqiScale !== root.editAqiScale
    var dataSourceChanged = pluginApi.pluginSettings.dataSource !== root.editDataSource
        || pluginApi.pluginSettings.aqicnToken !== root.editAqicnToken

    pluginApi.pluginSettings.aqiScale = root.editAqiScale
    pluginApi.pluginSettings.dataSource = root.editDataSource
    pluginApi.pluginSettings.aqicnToken = root.editAqicnToken
    pluginApi.pluginSettings.useNoctaliaLocation = root.editUseNoctaliaLocation
    pluginApi.pluginSettings.customLatitude = root.editCustomLatitude
    pluginApi.pluginSettings.customLongitude = root.editCustomLongitude
    pluginApi.pluginSettings.refreshInterval = root.editRefreshInterval
    pluginApi.pluginSettings.boldText = root.editBoldText

    pluginApi.saveSettings()

    // Only refresh if location, scale, or data source changed
    if (locationChanged || scaleChanged || dataSourceChanged) {
      root.pluginApi.mainInstance?.refresh()
    }

    Logger.i("Air Quality", "Settings saved")
  }
}
