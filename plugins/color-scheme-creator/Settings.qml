import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null

  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
  property string iconColor: cfg.iconColor ?? defaults.iconColor ?? "none"

  spacing: Style.marginL


  ColumnLayout {
    spacing: Style.marginM
    Layout.fillWidth: true


    NColorChoice {
      label: pluginApi?.tr("settings.iconColor.label")
      description: pluginApi?.tr("settings.iconColor.desc")
      currentKey: root.iconColor
      onSelected: key => root.iconColor = key
    }
  }

  function saveSettings() {
    if (!pluginApi) {
      return;
    }
    pluginApi.pluginSettings.iconColor = root.iconColor;
    pluginApi.saveSettings();
  }
}
