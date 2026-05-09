import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  // This is the only object reliably injected into the Settings Window
  property var pluginApi: null
  property var widgetSettings: null

  // Local state - initialize from widgetSettings.data with metadata fallback
  property bool valueShowBackground: widgetSettings?.data?.showBackground ?? widgetSettings?.metadata?.showBackground ?? true
  property bool valueRoundedCorners: widgetSettings?.data?.roundedCorners ?? widgetSettings?.metadata?.roundedCorners ?? true

  spacing: Style.marginM

  Component.onCompleted: {
    Logger.i("Desktop Calendar", "Desktop Widget Settings loaded");
  }

  NToggle {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.showBackground.label")
    description: pluginApi?.tr("settings.showBackground.desc")
    checked: root.valueShowBackground
    onToggled: checked => {
                 root.valueShowBackground = checked;
                 saveSettings();
               }
    defaultValue: widgetMetadata.showBackground
  }

  NToggle {
    Layout.fillWidth: true
    visible: valueShowBackground
    label: pluginApi?.tr("settings.roundedCorners.label")
    description: pluginApi?.tr("settings.roundedCorners.desc")
    checked: valueRoundedCorners
    onToggled: checked => {
                 root.valueRoundedCorners = checked;
                 saveSettings();
               }
    defaultValue: widgetMetadata.roundedCorners
  }

  function saveSettings() {
    if (!widgetSettings || !widgetSettings.data) {
      Logger.e("Desktop Calendar", "Cannot save: widgetSettings is null");
      return;
    }

    widgetSettings.data.showBackground = root.valueShowBackground;
    widgetSettings.data.roundedCorners = root.valueRoundedCorners;

    widgetSettings.save();

    Logger.i("Desktop Calendar", "Settings saved successfully");
  }
}
