
import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null

  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  property int delay: cfg.delay ?? defaults.delay 
  property string valueIconColor: cfg.iconColor ?? defaults.iconColor

  spacing: Style.marginL

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      label: pluginApi?.tr("settings.delay.label") 
      description: pluginApi?.tr("settings.delay.description")
    }

    NSlider {
      Layout.fillWidth: true
      from: 1
      to: 36
      stepSize: 5
      value: root.delay
      onValueChanged:{
         root.delay = value
         saveSettings()
       } 
     }
  }

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("CoinFilp", "Cannot save settings: pluginApi is null");
      return;
    }

    pluginApi.pluginSettings.delay = root.delay;
    pluginApi.saveSettings();

  }

  Component.onCompleted: {
    saveSettings() 
  }

}
