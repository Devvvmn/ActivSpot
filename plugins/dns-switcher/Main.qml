import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.System
import qs.Services.UI

Item {
    id: root
    property var pluginApi: null

    property string currentDnsIp: ""
    property string currentDnsName: pluginApi?.tr("status.checking") || "Checking..."
    property string activeProviderId: ""
    property bool isCustomDns: false
    property bool isChanging: false
    property string lastError: ""

    readonly property var defaultProviders: [
        { id: "google", label: "Google", ip: "8.8.8.8 8.8.4.4" },
        { id: "cloudflare", label: "Cloudflare", ip: "1.1.1.1 1.0.0.1" },
        { id: "opendns", label: "OpenDNS", ip: "208.67.222.222 208.67.220.220" },
        { id: "adguard", label: "AdGuard", ip: "94.140.14.14 94.140.15.15" },
        { id: "quad9", label: "Quad9", ip: "9.9.9.9 149.112.112.112" }
    ]
    property var customProviders: []

    readonly property var ipLookup: ({
        "8.8.8.8": "google", "8.8.4.4": "google",
        "1.1.1.1": "cloudflare", "1.0.0.1": "cloudflare",
        "208.67.222.222": "opendns", "208.67.220.220": "opendns",
        "94.140.14.14": "adguard", "94.140.15.15": "adguard",
        "9.9.9.9": "quad9", "149.112.112.112": "quad9"
    })

    readonly property var idToLabel: ({
        "google": "Google",
        "cloudflare": "Cloudflare",
        "opendns": "OpenDNS",
        "adguard": "AdGuard",
        "quad9": "Quad9"
    })

    readonly property var ipRegex: /^(\d{1,3}\.){3}\d{1,3}$/

    function isValidIp(ip) {
        if (!ipRegex.test(ip)) return false;
        var parts = ip.split(".");
        for (var i = 0; i < parts.length; i++) {
            var num = parseInt(parts[i], 10);
            if (num < 0 || num > 255) return false;
        }
        return true;
    }

    function validateDnsInput(ipString) {
        var trimmed = ipString.trim();
        var parts = trimmed.split(/\s+/);
        if (parts.length < 1 || parts.length > 2) return false;
        for (var i = 0; i < parts.length; i++) {
            if (!isValidIp(parts[i])) return false;
        }
        return true;
    }

    function loadCustomServers() {
        if (!pluginApi) return;
        try {
            var json = pluginApi.pluginSettings.savedServers || "[]";
            customProviders = JSON.parse(json);
        } catch (e) {
            customProviders = [];
        }
    }

    function addCustomServer(name, ip) {
        var trimmedName = (name || "").trim();
        var trimmedIp = (ip || "").trim();

        if (!trimmedName || !trimmedIp) return false;
        if (!validateDnsInput(trimmedIp)) return false;

        var list = customProviders.slice();
        list.push({ label: trimmedName, ip: trimmedIp, isCustom: true });
        customProviders = list;
        saveCustomServers();
        return true;
    }

    function removeCustomServer(index) {
        if (index < 0 || index >= customProviders.length) return;
        var list = customProviders.slice();
        list.splice(index, 1);
        customProviders = list;
        saveCustomServers();
    }

    function saveCustomServers() {
        if (pluginApi) {
            pluginApi.pluginSettings.savedServers = JSON.stringify(customProviders);
            pluginApi.saveSettings();
        }
    }

    Component.onCompleted: loadCustomServers()

    function updateDnsState(rawIp) {
        var trimmed = rawIp.trim();
        currentDnsIp = trimmed;

        // Check default providers via exact match
        var parts = trimmed.split(/[\s,]+/);
        for (var i = 0; i < parts.length; i++) {
            var id = ipLookup[parts[i]];
            if (id) {
                activeProviderId = id;
                currentDnsName = idToLabel[id];
                isCustomDns = true;
                return;
            }
        }

        // Check custom providers via exact match
        for (var j = 0; j < customProviders.length; j++) {
            var srv = customProviders[j];
            var srvIps = srv.ip.split(/\s+/);
            for (var k = 0; k < srvIps.length; k++) {
                if (parts.indexOf(srvIps[k]) !== -1) {
                    activeProviderId = "custom_" + j;
                    currentDnsName = srv.label;
                    isCustomDns = true;
                    return;
                }
            }
        }

        // ISP default
        if (trimmed === "" || trimmed.startsWith("192.168.") || trimmed.startsWith("127.")) {
            activeProviderId = "default";
            currentDnsName = pluginApi?.tr("status.default") || "Default (ISP)";
            isCustomDns = false;
            return;
        }

        // Unknown custom IP
        activeProviderId = "unknown";
        currentDnsName = pluginApi?.tr("status.custom", { ip: trimmed }) || "Custom (" + trimmed + ")";
        isCustomDns = true;
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!root.isChanging) {
                checkProcess.running = true;
            }
        }
    }

    Process {
        id: checkProcess
        command: ["sh", "-c", "nmcli -f IP4.DNS dev show | head -n 1 | awk '{print $2}'"]
        stdout: StdioCollector {
            onTextChanged: {
                root.updateDnsState(text);
            }
        }
    }

    function setDns(payload) {
        if (isChanging) return;

        var dnsIp = payload;
        var preset = defaultProviders.find(function(p) { return p.id === payload; });
        if (preset) {
            dnsIp = preset.ip;
        }
        if (payload === "default") {
            dnsIp = "";
        }

        // Validate non-default IPs
        if (dnsIp !== "" && !validateDnsInput(dnsIp)) {
            console.warn("DNS Switcher: Invalid DNS IP rejected:", dnsIp);
            lastError = pluginApi?.tr("error.invalid_ip") || "Invalid IP address";
            return;
        }

        isChanging = true;
        lastError = "";
        currentDnsName = pluginApi?.tr("status.switching") || "Switching...";

        // Sanitize: escape any remaining special characters as a safety net
        var safeIp = dnsIp.replace(/[^0-9. ]/g, "");

        var cmd;
        if (safeIp === "") {
            cmd = "CON=$(nmcli -t -f NAME connection show --active | head -n 1); " +
                  "if [ -z \"$CON\" ]; then exit 1; fi; " +
                  "nmcli con mod \"$CON\" ipv4.dns \"\" ipv4.ignore-auto-dns no; " +
                  "nmcli con up \"$CON\"";
        } else {
            cmd = "CON=$(nmcli -t -f NAME connection show --active | head -n 1); " +
                  "if [ -z \"$CON\" ]; then exit 1; fi; " +
                  "nmcli con mod \"$CON\" ipv4.dns \"" + safeIp + "\" ipv4.ignore-auto-dns yes; " +
                  "nmcli con up \"$CON\"";
        }

        changeProcess.command = ["pkexec", "sh", "-c", cmd];
        changeProcess.running = true;
    }

    Process {
        id: changeProcess
        stdout: StdioCollector {}
        stderr: StdioCollector {
            id: changeStderr
        }
        onExited: function(code) {
            root.isChanging = false;
            if (code !== 0) {
                root.lastError = pluginApi?.tr("error.apply_failed") || "Failed to apply DNS";
                console.warn("DNS Switcher: Apply failed with code", code, changeStderr.text);
            }
            checkProcess.running = true;
        }
    }
}
