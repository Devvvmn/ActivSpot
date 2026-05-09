import QtQuick
import Quickshell.Io
import qs.Commons

// Start the BatteryThresholdService to restore a previously set charge
// threshold when the plugin is loaded. This is needed as FW may reset
// the charge threshold when the device is fully powered off.
Item {
    property var pluginApi: null

    Component.onCompleted: {
        if (pluginApi) {
            service.start(pluginApi);
        }
    }

    property var service: BatteryThresholdService {
        id: service
    }

    IpcHandler {
        target: "plugin:battery-threshold"
        function togglePanel() {
            pluginApi?.withCurrentScreen(s => pluginApi.togglePanel(s));
        }
        function set(value: string) {
            var numValue = parseInt(value);
            if (numValue >= service.batteryMinThresh && numValue <= service.batteryMaxThresh) {
                service.setThreshold(numValue);
            }
        }
    }
}
