import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null

  property int editRefreshInterval:
    pluginApi?.pluginSettings?.refreshInterval ||
    pluginApi?.manifest?.metadata?.defaultSettings?.refreshInterval ||
    5000

  property string editConnectedColor:
    pluginApi?.pluginSettings?.connectedColor ||
    pluginApi?.manifest?.metadata?.defaultSettings?.connectedColor ||
    "primary"

  property string editDisconnectedColor:
    pluginApi?.pluginSettings?.disconnectedColor ||
    pluginApi?.manifest?.metadata?.defaultSettings?.disconnectedColor ||
    "none"

  spacing: Style.marginM

  NText {
    text: pluginApi?.tr("settings.title")
    font.pointSize: Style.fontSizeXL
    font.bold: true
  }

  NText {
    text: pluginApi?.tr("settings.description")
    color: Color.mSecondary
    Layout.fillWidth: true
    wrapMode: Text.Wrap
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginM
    Layout.bottomMargin: Style.marginM
  }

  NColorChoice {
    label: pluginApi?.tr("settings.connected-color")
    description: pluginApi?.tr("settings.connected-color-desc")
    currentKey: root.editConnectedColor
    onSelected: key => root.editConnectedColor = key
  }

  NColorChoice {
    label: pluginApi?.tr("settings.disconnected-color")
    description: pluginApi?.tr("settings.disconnected-color-desc")
    currentKey: root.editDisconnectedColor
    onSelected: key => root.editDisconnectedColor = key
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginM
    Layout.bottomMargin: Style.marginM
  }

  NLabel {
    label: pluginApi?.tr("settings.refresh-interval")
    description: pluginApi?.tr("settings.refresh-interval-desc") + " (" + root.editRefreshInterval + " ms)"
  }

  NSlider {
    Layout.fillWidth: true
    from: 1000
    to: 60000
    stepSize: 1000
    value: root.editRefreshInterval
    onValueChanged: root.editRefreshInterval = value
  }

  function saveSettings() {
    if (!pluginApi) return

    pluginApi.pluginSettings.refreshInterval = root.editRefreshInterval
    pluginApi.pluginSettings.connectedColor = root.editConnectedColor
    pluginApi.pluginSettings.disconnectedColor = root.editDisconnectedColor

    pluginApi.saveSettings()
    Logger.i("CloudflareWarp", "Settings saved")
  }
}
