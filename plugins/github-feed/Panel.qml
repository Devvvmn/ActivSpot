import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets
import qs.Services.UI

Item {
    id: root

    property var pluginApi: null

    readonly property var geometryPlaceholder: panelContainer
    readonly property bool allowAttach: true

    property real contentPreferredWidth: 420 * Style.uiScaleRatio
    property real contentPreferredHeight: 500 * Style.uiScaleRatio

    anchors.fill: parent

    readonly property var mainInstance: pluginApi?.mainInstance
    readonly property var events: mainInstance?.events || []
    readonly property bool isLoading: mainInstance?.isLoading || false
    readonly property bool hasError: mainInstance?.hasError || false
    readonly property string errorMessage: mainInstance?.errorMessage || ""
    readonly property bool hasUsername: (pluginApi?.pluginSettings?.username || "") !== ""
    readonly property string username: pluginApi?.pluginSettings?.username || ""

    property int currentTab: pluginApi?.pluginSettings?.defaultTab ?? 0

    function formatEventType(event) {
        if (!event || !event.type) return ""

        if (event.isMyRepoEvent) {
            if (event.type === "WatchEvent") return "starred your repo"
            if (event.type === "ForkEvent") return "forked your repo"
            return event.type.replace("Event", "").toLowerCase() + " your repo"
        }

        if (event.isFollowedUserEvent) {
            switch (event.type) {
                case "WatchEvent": return "starred"
                case "ForkEvent": return "forked"
                case "PullRequestEvent":
                    var action = event.payload?.action || "opened"
                    return action + " PR in"
                case "CreateEvent": return "created repo"
                default: return event.type.replace("Event", "").toLowerCase()
            }
        }

        switch (event.type) {
            case "WatchEvent": return "starred"
            case "ForkEvent": return "forked"
            case "PullRequestEvent": return event.payload?.action || "opened PR"
            case "CreateEvent": return "created " + (event.payload?.ref_type || "repo")
            default: return event.type.replace("Event", "").toLowerCase()
        }
    }

    function formatRepoName(repo) {
        return repo?.name || ""
    }

    function getEventDetail(event) {
        if (!event) return ""
        if (event.description) return event.description
        if (event.payload?.pull_request?.title) return event.payload.pull_request.title
        return ""
    }

    function formatRelativeTime(isoString) {
        if (!isoString) return ""

        var date = new Date(isoString)
        var now = new Date()
        var diffMs = now - date
        var diffSec = Math.floor(diffMs / 1000)
        var diffMin = Math.floor(diffSec / 60)
        var diffHour = Math.floor(diffMin / 60)
        var diffDay = Math.floor(diffHour / 24)

        if (diffMin < 1) return "just now"
        if (diffMin < 60) return diffMin + "m ago"
        if (diffHour < 24) return diffHour + "h ago"
        if (diffDay < 30) return diffDay + "d ago"

        return date.toLocaleDateString()
    }

    function getEventUrl(event) {
        if (!event) return ""
        var repo = event.repo?.name || ""
        if (event.type === "PullRequestEvent" && event.payload?.pull_request?.html_url) {
            return event.payload.pull_request.html_url
        }
        return (root.mainInstance?.githubWebUrl || "https://github.com") + "/" + repo
    }

    function getNotificationIcon(type) {
        switch (type) {
            case "Issue": return "circle-dot"
            case "PullRequest": return "git-pull-request"
            case "Release": return "tag"
            case "Discussion": return "messages"
            case "CheckSuite": return "circle-check"
            case "Commit": return "git-commit"
            case "WorkflowRun": return "player-play"
            case "RepositoryInvitation": return "user-plus"
            default: return "bell"
        }
    }

    Rectangle {
        id: panelContainer
        anchors.fill: parent
        color: "transparent"

        ColumnLayout {
            anchors {
                fill: parent
                margins: Style.marginL
            }
            spacing: Style.marginS

            RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginM

                NIcon {
                    icon: "brand-github"
                    pointSize: Style.fontSizeL
                    color: Color.mPrimary
                }

                NText {
                    Layout.fillWidth: true
                    text: "GitHub Activity"
                    pointSize: Style.fontSizeM
                    font.weight: Font.Bold
                    color: Color.mOnSurface
                }

                NIconButton {
                    icon: "refresh"
                    enabled: !root.isLoading && root.hasUsername
                    colorFg: root.isLoading ? Color.mOnSurfaceVariant : Color.mOnSurface

                    onClicked: {
                        if (root.mainInstance) {
                            root.mainInstance.fetchFromGitHub()
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginS

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: activityBtn.implicitHeight
                    color: root.currentTab === 0 ? Color.mPrimary : Color.mSurfaceVariant
                    radius: Style.radiusM

                    NText {
                        id: activityBtn
                        anchors.centerIn: parent
                        text: "Activity"
                        color: root.currentTab === 0 ? Color.mOnPrimary : Color.mOnSurfaceVariant
                        pointSize: Style.fontSizeS
                        font.weight: Font.Medium
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.currentTab = 0
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: notifBtn.implicitHeight
                    color: root.currentTab === 1 ? Color.mPrimary : Color.mSurfaceVariant
                    radius: Style.radiusM

                    NText {
                        id: notifBtn
                        anchors.centerIn: parent
                        text: {
                            var count = root.mainInstance?.notificationCount || 0
                            return count > 0 ? "Notifications (" + count + ")" : "Notifications"
                        }
                        color: root.currentTab === 1 ? Color.mOnPrimary : Color.mOnSurfaceVariant
                        pointSize: Style.fontSizeS
                        font.weight: Font.Medium
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.currentTab = 1
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginS
                visible: root.hasUsername && root.mainInstance?.lastFetchTimestamp > 0

                NText {
                    Layout.fillWidth: true
                    text: {
                        if (!root.mainInstance?.lastFetchTimestamp) return ""
                        var age = Math.floor(Date.now() / 1000) - root.mainInstance.lastFetchTimestamp
                        var minutes = Math.floor(age / 60)
                        if (minutes < 1) return "Updated just now"
                        if (minutes < 60) return "Updated " + minutes + "m ago"
                        var hours = Math.floor(minutes / 60)
                        if (hours < 24) return "Updated " + hours + "h ago"
                        return "Updated " + Math.floor(hours / 24) + "d ago"
                    }
                    pointSize: Style.fontSizeXS
                    color: Color.mOnSurfaceVariant
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Color.mSurfaceVariant
                radius: Style.radiusL

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: Style.marginL
                    visible: !root.hasUsername

                    NIcon {
                        Layout.alignment: Qt.AlignHCenter
                        icon: "user-circle"
                        pointSize: Style.fontSizeXXL * 2
                        color: Color.mOnSurfaceVariant
                    }

                    NText {
                        Layout.alignment: Qt.AlignHCenter
                        text: "No username configured"
                        pointSize: Style.fontSizeM
                        font.weight: Font.Medium
                        color: Color.mOnSurface
                    }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: Style.marginL
                    visible: root.hasError && root.hasUsername

                    NText {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Failed to fetch events"
                        pointSize: Style.fontSizeM
                        color: Color.mOnSurfaceVariant
                    }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: Style.marginL
                    visible: root.isLoading && root.events.length === 0

                    NText {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Loading GitHub events..."
                        pointSize: Style.fontSizeM
                        color: Color.mOnSurfaceVariant
                    }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: Style.marginL
                    visible: !root.isLoading && !root.hasError && root.hasUsername && (
                        (root.currentTab === 0 && root.events.length === 0) ||
                        (root.currentTab === 1 && (!mainInstance?.notificationsList || mainInstance.notificationsList.length === 0))
                    )

                    NText {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.currentTab === 0 ? "No recent activity" : "No notifications"
                        pointSize: Style.fontSizeM
                        color: Color.mOnSurfaceVariant
                    }
                }

                NScrollView {
                    anchors.fill: parent
                    anchors.margins: Style.marginS
                    visible: root.hasUsername && !root.hasError && (
                        (root.currentTab === 0 && root.events.length > 0) ||
                        (root.currentTab === 1 && mainInstance?.notificationsList && mainInstance.notificationsList.length > 0)
                    )

                    ColumnLayout {
                        width: parent.width
                        spacing: 0

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Style.marginS
                            visible: root.currentTab === 0

                        Repeater {
                            model: root.events
                            delegate: Rectangle {
                                id: eventCard
                                Layout.fillWidth: true
                                height: cardContent.implicitHeight + Style.marginM * 2
                                color: cardMouse.containsMouse ? Qt.lighter(Color.mSurface, 1.05) : Color.mSurface
                                radius: Style.radiusM

                                Behavior on color {
                                    ColorAnimation { duration: 100 }
                                }

                                property var event: modelData
                                property string eventDetail: getEventDetail(event)

                                RowLayout {
                                    id: cardContent
                                    anchors {
                                        left: parent.left
                                        right: parent.right
                                        verticalCenter: parent.verticalCenter
                                        margins: Style.marginM
                                    }
                                    spacing: Style.marginM

                                    NImageRounded {
                                        Layout.preferredWidth: 36
                                        Layout.preferredHeight: 36
                                        Layout.alignment: Qt.AlignTop
                                        radius: 18
                                        imagePath: root.mainInstance ? root.mainInstance.getAvatarPath(eventCard.event?.actor?.login) : ""
                                        fallbackIcon: "user"
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 4

                                            NText {
                                                text: eventCard.event?.actor?.login || ""
                                                pointSize: Style.fontSizeS
                                                font.weight: Font.Bold
                                                color: Color.mOnSurface
                                            }

                                            NText {
                                                text: formatEventType(eventCard.event)
                                                pointSize: Style.fontSizeS
                                                color: Color.mOnSurfaceVariant
                                            }

                                            Item { Layout.fillWidth: true }

                                            NText {
                                                text: formatRelativeTime(eventCard.event?.created_at)
                                                pointSize: Style.fontSizeXS
                                                color: Color.mOnSurfaceVariant
                                            }
                                        }

                                        NText {
                                            Layout.fillWidth: true
                                            text: formatRepoName(eventCard.event?.repo)
                                            pointSize: Style.fontSizeS
                                            font.weight: Font.Medium
                                            color: Color.mPrimary
                                            elide: Text.ElideRight
                                        }

                                        NText {
                                            Layout.fillWidth: true
                                            visible: eventCard.eventDetail !== ""
                                            text: eventCard.eventDetail
                                            pointSize: Style.fontSizeXS
                                            color: Color.mOnSurfaceVariant
                                            elide: Text.ElideRight
                                            maximumLineCount: 1
                                        }
                                    }
                                }

                                MouseArea {
                                    id: cardMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor

                                    onClicked: {
                                        var url = getEventUrl(eventCard.event)
                                        if (url) {
                                            Qt.openUrlExternally(url)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Style.marginS
                        visible: root.currentTab === 1

                        Repeater {
                            model: mainInstance?.notificationsList || []
                            delegate: Rectangle {
                                id: notifCard
                                Layout.fillWidth: true
                                height: notifContent.implicitHeight + Style.marginM * 2
                                color: notifMouse.containsMouse ? Qt.lighter(Color.mSurface, 1.05) : Color.mSurface
                                radius: Style.radiusM

                                Behavior on color {
                                    ColorAnimation { duration: 100 }
                                }

                                property var notification: modelData

                                RowLayout {
                                    id: notifContent
                                    anchors {
                                        left: parent.left
                                        right: parent.right
                                        verticalCenter: parent.verticalCenter
                                        margins: Style.marginM
                                    }
                                    spacing: Style.marginM

                                    NIcon {
                                        icon: root.getNotificationIcon(notifCard.notification.type)
                                        pointSize: Style.fontSizeL
                                        color: Color.mPrimary
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 4

                                            NText {
                                                text: notifCard.notification.repo
                                                pointSize: Style.fontSizeS
                                                font.weight: Font.Bold
                                                color: Color.mOnSurface
                                            }

                                            NText {
                                                text: "• " + notifCard.notification.type
                                                pointSize: Style.fontSizeXS
                                                color: Color.mOnSurfaceVariant
                                            }

                                            Item { Layout.fillWidth: true }

                                            NText {
                                                text: formatRelativeTime(notifCard.notification.updated_at)
                                                pointSize: Style.fontSizeXS
                                                color: Color.mOnSurfaceVariant
                                            }
                                        }

                                        NText {
                                            Layout.fillWidth: true
                                            text: notifCard.notification.title
                                            pointSize: Style.fontSizeS
                                            color: Color.mOnSurface
                                            elide: Text.ElideRight
                                            maximumLineCount: 2
                                        }
                                    }
                                }

                                MouseArea {
                                    id: notifMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor

                                    onClicked: {
                                        var url = notifCard.notification.url
                                        if (url) {
                                            Qt.openUrlExternally(url)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

    Component.onCompleted: {
        Logger.i("GitHubFeed", "Panel initialized, currentTab: " + root.currentTab)
    }
}
