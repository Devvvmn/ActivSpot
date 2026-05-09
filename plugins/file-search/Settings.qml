import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null

  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  property bool valueShowHidden: cfg.showHidden ?? defaults.showHidden
  property int valueMaxResults: cfg.maxResults ?? defaults.maxResults
  property string valueFileOpener: cfg.fileOpener ?? defaults.fileOpener
  property string valueFdCommand: cfg.fdCommand ?? defaults.fdCommand
  property string valueSearchDirectory: cfg.searchDirectory ?? defaults.searchDirectory

  spacing: Style.marginL

  Component.onCompleted: {
    Logger.d("FileSearch", "Settings UI loaded");
  }

  ColumnLayout {
    spacing: Style.marginM
    Layout.fillWidth: true

    // Show Hidden Files Toggle
    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginM

      ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        NText {
          text: pluginApi?.tr("settings.showHidden.label")
          font.pointSize: Style.fontSizeL
          font.weight: Font.Medium
          color: Color.mOnSurface
          Layout.fillWidth: true
        }
      }

      NToggle {
        checked: root.valueShowHidden
        onToggled: root.valueShowHidden = checked
      }
    }

    // File Opener Input
    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.fileOpener.label")
      description: pluginApi?.tr("settings.fileOpener.description")
      placeholderText: pluginApi?.tr("settings.fileOpener.placeholder")
      text: root.valueFileOpener
      onTextChanged: root.valueFileOpener = text
    }

    // Search Directory Input
    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.searchDirectory.label")
      description: pluginApi?.tr("settings.searchDirectory.description")
      placeholderText: pluginApi?.tr("settings.searchDirectory.placeholder")
      text: root.valueSearchDirectory
      onTextChanged: root.valueSearchDirectory = text
    }

    // fd Command Path Input
    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.fdCommand.label")
      description: pluginApi?.tr("settings.fdCommand.description")
      placeholderText: pluginApi?.tr("settings.fdCommand.placeholder")
      text: root.valueFdCommand
      onTextChanged: root.valueFdCommand = text
    }
  }

    // Max Results Slider
    ColumnLayout {
      Layout.fillWidth: true
      spacing: Style.marginS

      RowLayout {
        Layout.fillWidth: true

        NText {
          text: pluginApi?.tr("settings.maxResults.label")
          font.pointSize: Style.fontSizeL
          font.weight: Font.Medium
          color: Color.mOnSurface
          Layout.fillWidth: true
        }

        NText {
          text: root.valueMaxResults === 0 ? pluginApi?.tr("settings.maxResults.unlimited") : root.valueMaxResults.toString()
          font.pointSize: Style.fontSizeM
          font.weight: Font.Medium
          color: Color.mPrimary
        }
      }

      NText {
        text: pluginApi?.tr("settings.maxResults.description")
        font.pointSize: Style.fontSizeS
        color: Color.mOnSurfaceVariant
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
      }

      NSlider {
        Layout.fillWidth: true
        from: 0
        to: 1000
        stepSize: 10
        value: root.valueMaxResults
        onMoved: root.valueMaxResults = Math.round(value)
      }
    }

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("FileSearch", "Cannot save settings: pluginApi is null");
      return;
    }

    pluginApi.pluginSettings.showHidden = root.valueShowHidden;
    pluginApi.pluginSettings.maxResults = root.valueMaxResults;
    pluginApi.pluginSettings.fileOpener = root.valueFileOpener;
    pluginApi.pluginSettings.searchDirectory = root.valueSearchDirectory;
    pluginApi.pluginSettings.fdCommand = root.valueFdCommand;
    pluginApi.saveSettings();

    Logger.d("FileSearch", "Settings saved successfully");
  }
}
