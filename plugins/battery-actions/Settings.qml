import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import Quickshell.Io

ColumnLayout {
    id: root

    property var pluginApi: null

    property string editPluggedInScript: pluginApi?.pluginSettings?.pluggedInScript || ""
    property string editOnBatteryScript: pluginApi?.pluginSettings?.onBatteryScript || ""

    spacing: Style.marginL

    NTextInput {
        Layout.fillWidth: true
        fontFamily: Settings.data.ui.fontFixed
        label: tr("settings.plugged_in_label")
        description: tr("settings.plugged_in_desc")
        placeholderText: "command1; command2; /path/to/script; ..."
        text: root.editPluggedInScript
        onTextChanged: root.editPluggedInScript = text
    }
    NTextInput {
        Layout.fillWidth: true
        fontFamily: Settings.data.ui.fontFixed
        label: tr("settings.on_battery_label")
        description: tr("settings.on_battery_desc")
        placeholderText: "command1; command2; /path/to/script; ..."
        text: root.editOnBatteryScript
        onTextChanged: root.editOnBatteryScript = text
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginS
        NLabel {
            label: tr("settings.env_vars_title")
        }

        NLabel {
            description: `$BAT_PERCENTAGE: ${tr("settings.env_vars_percentage")}`
        }
        NLabel {
            description: `$BAT_STATE: ${tr("settings.env_vars_state")}`
        }
        NLabel {
            description: `$BAT_RATE: ${tr("settings.env_vars_rate")}`
        }
        NLabel {
            description: `$BAT_PATH: ${tr("settings.env_vars_path")}`
        }
    }

    function tr(key) {
        return pluginApi?.tr(key);
    }

    function saveSettings() {
        pluginApi.pluginSettings.pluggedInScript = root.editPluggedInScript;
        pluginApi.pluginSettings.onBatteryScript = root.editOnBatteryScript;
        pluginApi.saveSettings();
    }
}
