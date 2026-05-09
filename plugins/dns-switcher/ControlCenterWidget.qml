import QtQuick
import Quickshell
import qs.Commons
import qs.Widgets

NIconButton {
    id: root

    property var pluginApi: null
    property var screen: null
    readonly property var mainInstance: pluginApi?.mainInstance

    readonly property var providerIcons: ({
        "google": "brand-google",
        "cloudflare": "cloud",
        "opendns": "world",
        "adguard": "shield-check",
        "quad9": "lock"
    })

    icon: providerIcons[mainInstance?.activeProviderId || ""] || "globe"

    property bool isActive: mainInstance?.isCustomDns || false

    colorBg: isActive ? Color.mPrimary : Color.mSurfaceVariant
    colorFg: isActive ? Color.mOnPrimary : Color.mOnSurface

    tooltipText: mainInstance?.currentDnsName || pluginApi?.tr("plugin.title") || "DNS Switcher"

    onClicked: {
        if (pluginApi) {
            pluginApi.openPanel(root.screen, root);
        }
    }
}
