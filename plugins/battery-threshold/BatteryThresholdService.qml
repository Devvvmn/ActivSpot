import QtQuick
import Quickshell.Io
import qs.Commons

Item {
    id: root
    visible: false

    property var pluginApi: null
    property int currentThreshold: 0
    property bool isAvailable: false
    property bool isWritable: false
    property int batteryMinThresh: 40
    property int batteryMaxThresh: 100

    property list<string> batteries: []
    property string thresholdFile: `${pluginApi?.pluginSettings?.batteryDevice || service.batteries[0]}/charge_control_end_threshold`

    function start(api) {
        pluginApi = api;
        getBatteries();
        batteryChecker.running = true;
    }

    function refresh() {
        batteryChecker.running = true;
        if (thresholdFileView.path !== "") {
            thresholdFileView.reload();
        }
    }

    function restoreSavedThreshold() {
        if (!pluginApi?.pluginSettings)
            return;
        const saved = pluginApi.pluginSettings.chargeThreshold;
        // Skip if current threshold already matches saved value
        if (currentThreshold === saved)
            return;
        if (saved >= batteryMinThresh && saved <= batteryMaxThresh && isWritable) {
            setThreshold(saved);
        }
    }

    function setThreshold(value) {
        const v = Math.round(value);
        Logger.i("BatteryThreshold", "Restored charge threshold to " + v + "%");

        thresholdWriter.pendingThreshold = v;
        thresholdWriter.command = ["sh", "-c", `echo ${v} > ${thresholdFile}`];
        thresholdWriter.running = true;
    }

    function getBatteries() {
        Logger.i("BatteryThreshold", "Obtaining available batteries...");
        batteryList.running = true;
    }

    onIsWritableChanged: {
        if (isWritable)
            restoreSavedThreshold();
    }

    onThresholdFileChanged: {
        batteryChecker.running = true;
    }

    Process {
        id: batteryChecker
        command: ["test", "-f", root.thresholdFile]
        running: false

        onExited: function (exitCode) {
            if (exitCode === 0 && root.batteries.length != 0) {
                root.isAvailable = true;
                thresholdFileView.path = root.thresholdFile;
                writeAccessChecker.running = true;
            }
        }
    }

    Process {
        id: writeAccessChecker
        command: ["sh", "-c", `test -w ${root.thresholdFile} && echo 1 || echo 0`]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                root.isWritable = text.trim() === "1";
            }
        }
    }

    FileView {
        id: thresholdFileView
        path: root.thresholdFile
        printErrors: false

        onLoaded: {
            const value = parseInt(text().trim());
            // The range exposed by sysfs
            if (!isNaN(value) && value >= 0 && value <= 100) {
                root.currentThreshold = value;
            }
        }
    }

    Process {
        id: thresholdWriter
        property int pendingThreshold: -1

        running: false

        onExited: function (exitCode) {
            if (exitCode === 0) {
                service.refresh();
                if (pluginApi && pluginApi.pluginSettings.chargeThreshold != pendingThreshold) {
                    pluginApi.pluginSettings.chargeThreshold = pendingThreshold;
                    pluginApi.saveSettings();
                }
            } else {
                Logger.w("BatteryThreshold", "Failed to write threshold, exitCode=" + exitCode);
            }
        }
    }

    Process {
        id: batteryList
        command: ["sh", "-c", "find /sys/class/power_supply -exec find {}/ ';' | grep charge_control_end_threshold"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                root.batteries = text.split("\n").slice(0, -1).map(path => path.split("/").slice(0, -1).join("/"));
                Logger.i("BatteryThreshold", `Found batteries: ${root.batteries}`);
            }
        }
    }
}
