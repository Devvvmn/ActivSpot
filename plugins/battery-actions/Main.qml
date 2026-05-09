import QtQuick
import Quickshell.Io
import qs.Commons
import Quickshell.Services.UPower

Item {
    id: root
    property var pluginApi: null
    property var battery: UPower.onBattery

    Component.onCompleted: {
        Logger.i("BatteryActions", "Battery Actions loaded.");
    }

    onBatteryChanged: {
        if (battery && pluginApi?.pluginSettings) {
            Logger.i("BatteryActions", "On battery!");
            executor.command = ["sh", "-c", pluginApi.pluginSettings.onBatteryScript];
        } else {
            Logger.i("BatteryActions", "Plugged in!");
            executor.command = ["sh", "-c", pluginApi.pluginSettings.pluggedInScript];
        }
        executor.environment = gatherEnvironment();
        executor.running = true;
    }

    function gatherEnvironment() {
        const bat = UPower.displayDevice;
        if (bat.ready) {
            return {
                BAT_PERCENTAGE: bat.percentage,
                BAT_STATE: UPowerDeviceState.toString(bat.state),
                BAT_RATE: bat.chargeRate,
                BAT_PATH: bat.nativePath
            };
        } else {
            return {};
        }
    }

    Process {
        id: executor
        running: false
        stderr: StdioCollector {
            onStreamFinished: {
                if (text) {
                    Logger.e("BatteryThreshold", `stderr: ${text}`);
                }
            }
        }

        onExited: function (exitCode) {
            if (exitCode !== 0) {
                Logger.e("BatteryThreshold", `Command failed w/ exit code ${exitCode}`);
            }
        }
    }
}
