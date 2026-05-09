import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root

    property var pluginApi: null
    property var cfg: pluginApi?.pluginSettings || ({})
    property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
    readonly property string systemLocale: Qt.locale().name.replace("_", "-")
    readonly property string configuredLocale: cfg.locale ?? defaults.locale ?? ""

    property string selectedSource: cfg.source ?? defaults.source ?? "bing"
    property string localeText: configuredLocale && configuredLocale.trim().length > 0
                              ? configuredLocale
                              : systemLocale

    spacing: Style.marginL

    NComboBox {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.source.label")
        model: [
            {
                "key": "bing",
                "name": pluginApi.tr("settings.source.options.bing")
            },
            {
                "key": "nasa",
                "name": pluginApi.tr("settings.source.options.nasa")
            }
        ]
        currentKey: root.selectedSource
        onSelected: key => root.selectedSource = key
        defaultValue: "bing"
    }

    Loader {
        Layout.fillWidth: true
        active: root.selectedSource === "bing"
        sourceComponent: ColumnLayout {
            spacing: Style.marginS

            NTextInput {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.locale.label")
                text: root.localeText
                onTextChanged: {
                    if (text !== root.localeText) {
                        root.localeText = text;
                    }
                }
            }
        }
    }

    Item {
        Layout.fillHeight: true
    }

    function saveSettings() {
        if (!pluginApi) {
            return;
        }

        pluginApi.pluginSettings.source = root.selectedSource;
        pluginApi.pluginSettings.locale = root.localeText;
        pluginApi.saveSettings();

        pluginApi.mainInstance?.checkAndFetchWallpaper();
    }
}
