import QtQuick
import Quickshell
import qs.Commons
import qs.Widgets
import qs.Services.UI

NIconButtonHot {
    id: root

    property ShellScreen screen
    property var pluginApi: null
    property var main: pluginApi?.mainInstance ?? null

    readonly property string status: {
        if (!main || main.haToken === "")
            return "Unconfigured";
        if (main.authFailed)
            return "AuthFailed";
        if (main.authenticated)
            return "Connected";
        if (main.isReconnecting)
            return "Disconnected";
        return "Connecting";
    }

    icon: "smart-home"
    colorFg: {
        switch (status) {
            case "Connected": return Color.mPrimary;
            case "Connecting": return Color.mOnError;
            case "Disconnected": return Color.mError;
            case "AuthFailed": return Color.mError;
            default: return Color.mOnSurfaceVariant;
        }
    }

    tooltipText: {
        switch (status) {
            case "Connected": return pluginApi?.tr("widget.status_connected");
            case "Connecting": return pluginApi?.tr("widget.status_connecting");
            case "Disconnected": return pluginApi?.tr("widget.status_disconnected");
            case "AuthFailed": return pluginApi?.tr("widget.status_auth_failed");
            default: return pluginApi?.tr("widget.status_unconfigured");
        }
    }

    onClicked: {
        if (pluginApi)
            pluginApi.togglePanel(screen);
    }

    onRightClicked: {
        if (pluginApi && pluginApi.manifest)
            BarService.openPluginSettings(screen, pluginApi.manifest);
    }

    SequentialAnimation on opacity {
        running: status === "Connecting"
        loops: Animation.Infinite

        NumberAnimation { to: 0.4; duration: 600; easing.type: Easing.InOutSine }
        NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutSine }
    }
}
