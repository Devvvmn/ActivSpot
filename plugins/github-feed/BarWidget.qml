import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets
import qs.Services.UI
import qs.Services.System

NIconButton {
    id: root

    property var pluginApi: null
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""
    property int sectionWidgetIndex: -1
    property int sectionWidgetsCount: 0

    readonly property var mainInstance: pluginApi?.mainInstance
    readonly property var events: mainInstance?.events || []
    readonly property bool isLoading: mainInstance?.isLoading || false
    readonly property bool hasError: mainInstance?.hasError || false
    readonly property bool colorizationEnabled: mainInstance?.colorizationEnabled ?? false
    readonly property string colorizationIcon: mainInstance?.colorizationIcon ?? "Primary"
    readonly property string colorizationBadge: mainInstance?.colorizationBadge ?? "Primary"
    readonly property string colorizationBadgeText: mainInstance?.colorizationBadgeText ?? "Primary"
    readonly property bool showNotificationBadge: mainInstance?.showNotificationBadge ?? true
    readonly property bool hasUsername: (pluginApi?.pluginSettings?.username || "") !== ""

    function getThemeColor(type) {
        switch (type) {
            case "Primary": return Color.mPrimary
            case "Secondary": return Color.mSecondary
            case "Tertiary": return Color.mTertiary
            case "Error": return Color.mError
            default: return Color.mOnSurface
        }
    }

    icon: "brand-github"
    tooltipText: buildTooltip()
    tooltipDirection: BarService.getTooltipDirection()
    baseSize: Style.capsuleHeight
    applyUiScale: false
    customRadius: Style.radiusL
    colorBg: Style.capsuleColor
    colorFg: {
        if (hasError) return Color.mError
        if (!hasUsername) return Color.mOnSurfaceVariant
        if (colorizationEnabled && colorizationIcon !== "None") return getThemeColor(colorizationIcon)
        return Color.mOnSurface
    }
    colorBgHover: Color.mHover
    colorFgHover: Color.mOnHover
    colorBorder: "transparent"
    colorBorderHover: "transparent"

    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    Rectangle {
        id: badge
        visible: showNotificationBadge && (mainInstance?.notificationCount > 0)
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: 2
        anchors.topMargin: 2
        z: 2
        height: 14 * Style.uiScaleRatio
        width: Math.max(height, badgeText.implicitWidth + 6 * Style.uiScaleRatio)
        radius: height / 2
        color: (colorizationEnabled && colorizationBadge !== "None") ? getThemeColor(colorizationBadge) : Color.mError
        border.color: Color.mSurface
        border.width: 1

        NText {
            id: badgeText
            anchors.centerIn: parent
            text: {
                var count = mainInstance?.notificationCount || 0
                return count > 99 ? "99+" : count.toString()
            }
            pointSize: Style.fontSizeXS * 0.8
            font.weight: Font.Bold
            color: (colorizationEnabled && colorizationBadgeText !== "None") ? getThemeColor(colorizationBadgeText) : Color.mOnError
        }
    }

    onClicked: {
        if (!hasUsername) {
            ToastService.showNotice("Please configure your GitHub username in settings")
            return
        }

        pluginApi.openPanel(root.screen, this)
    }

    onRightClicked: {
        if (mainInstance && hasUsername) {
            mainInstance.fetchFromGitHub()
            ToastService.showNotice("Refreshing GitHub feed...")
        }
    }

    function buildTooltip() {
        if (!hasUsername) {
            return "GitHub Feed\nClick to configure"
        }

        if (hasError) {
            return "GitHub Feed\nError: " + (mainInstance?.errorMessage || "Unknown error")
        }

        if (isLoading) {
            return "GitHub Feed\nLoading..."
        }

        var username = pluginApi?.pluginSettings?.username || ""
        var tooltip = "GitHub Feed - @" + username + "\n"

        var notifCount = mainInstance?.notificationCount || 0
        if (notifCount > 0) {
            tooltip += notifCount + (notifCount === 1 ? " unread notification\n" : " unread notifications\n")
        }

        tooltip += events.length + " events"

        if (mainInstance?.lastFetchTimestamp) {
            var age = Math.floor(Date.now() / 1000) - mainInstance.lastFetchTimestamp
            var minutes = Math.floor(age / 60)
            if (minutes < 1) {
                tooltip += "\nUpdated just now"
            } else if (minutes < 60) {
                tooltip += "\nUpdated " + minutes + "m ago"
            } else {
                tooltip += "\nUpdated " + Math.floor(minutes / 60) + "h ago"
            }
        }

        tooltip += "\n\nRight-click to refresh"

        return tooltip
    }

    Component.onCompleted: {
        Logger.i("GitHubFeed", "BarWidget initialized")
    }
}
