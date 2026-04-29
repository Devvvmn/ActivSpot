import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Widgets
import qs.Commons
import qs.Widgets
import qs.Services.UI

Item {
    id: root

    property var pluginApi: null

    readonly property var geometryPlaceholder: panelContainer
    readonly property bool allowAttach: true

    property real contentPreferredWidth: 500 * Style.uiScaleRatio
    property real contentPreferredHeight: 340 * Style.uiScaleRatio

    anchors.fill: parent

    // Shared column width reference (content area minus outer margins, table inner margins, and column spacing)
    readonly property real tableContentWidth: panelContainer.width - 2 * Style.marginL - 2 * Style.marginS - 2 * Style.marginS

    Rectangle {
        id: panelContainer
        anchors.fill: parent
        color: "transparent"

        ColumnLayout {
            anchors {
                fill: parent
                margins: Style.marginL
            }
            spacing: Style.marginL

            RowLayout {
                visible: pluginApi.pluginSettings.closeButton ?? pluginApi.manifest.metadata.defaultSettings.closeButton
                NText {
                    Layout.fillWidth: true
                    text: pluginApi?.tr("panel.title")
                    pointSize: Style.fontSizeXL
                    font.weight: Font.Bold
                    color: Color.mOnSurface
                    horizontalAlignment: Text.AlignHCenter
                }
                NIconButton {
                    icon: "close"
                    onClicked: {
                        pluginApi.closePanel(pluginApi.panelOpenScreen)
                    }
                }
            }

            // Header
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Style.marginS
                spacing: Style.marginS

                NText {
                    Layout.preferredWidth: 0.4 * root.tableContentWidth
                    text: pluginApi?.tr("panel.name")
                    pointSize: Style.fontSizeL
                    font.weight: Font.Bold
                    color: Color.mOnSurface
                    horizontalAlignment: Text.AlignLeft
                }
                NText {
                    Layout.preferredWidth: 0.3 * root.tableContentWidth
                    text: pluginApi?.tr("panel.oldVer")
                    pointSize: Style.fontSizeL
                    font.weight: Font.Bold
                    color: Color.mOnSurface
                    horizontalAlignment: Text.AlignHCenter
                }
                NText {
                    Layout.preferredWidth: 0.3 * root.tableContentWidth
                    text: pluginApi?.tr("panel.newVer")
                    pointSize: Style.fontSizeL
                    font.weight: Font.Bold
                    color: Color.mOnSurface
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            // Table
            ClippingRectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Color.mSurfaceVariant
                radius: Style.radiusL

                NListView {
                    id: tableView
                    anchors.fill: parent
                    anchors.margins: Style.marginS
                    model: root.pluginApi?.mainInstance?.updates ?? []
                    clip: true
                    spacing: Style.marginXS

                    delegate: RowLayout {
                        required property var modelData
                        width: tableView.width
                        spacing: Style.marginS

                        NText { // Name
                            Layout.preferredWidth: 0.4 * root.tableContentWidth
                            text: modelData.name
                            pointSize: Style.fontSizeM
                            color: (modelData.source == "flatpak") ? Color.mTertiary : (modelData.source == "system") ? Color.mSecondary : Color.mPrimary
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }
                        NText { // Old Version
                            Layout.preferredWidth: 0.3 * root.tableContentWidth
                            text: modelData.oldVer
                            pointSize: Style.fontSizeM
                            color: (modelData.source == "flatpak") ? Color.mTertiary : (modelData.source == "system") ? Color.mSecondary : Color.mPrimary
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }
                        NText { // New Version
                            Layout.preferredWidth: 0.3 * root.tableContentWidth
                            text: modelData.newVer
                            pointSize: Style.fontSizeM
                            font.weight: (pluginApi.pluginSettings.boldVerPanel ?? pluginApi.manifest.metadata.defaultSettings.boldVerPanel) ? Font.Bold : Font.Normal
                            color: (modelData.source == "flatpak") ? Color.mTertiary : (modelData.source == "system") ? Color.mSecondary : Color.mPrimary
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }
                    }
                }
            }

            // Footer
            RowLayout {
                spacing: Style.marginL
                NButton {
                    Layout.fillWidth: true
                    text: pluginApi?.tr("panel.refresh")
                    onClicked: {
                        Logger.d("Arch Updater", "Refreshing from panel...")
                        root.pluginApi.mainInstance.refresh()
                    }
                }
                NButton {
                    Layout.fillWidth: true
                    text: pluginApi?.tr("panel.update")
                    onClicked: {
                        Logger.d("Arch Updater", "Updating from panel...")
                        root.pluginApi.mainInstance.update()
                        pluginApi.closePanel(pluginApi.panelOpenScreen)
                    }
                }
                NIconButton {
                    icon: "settings"
                    onClicked: {
                        Logger.d("Arch Updater", "Opening settings from panel...")
                        BarService.openPluginSettings(pluginApi.panelOpenScreen, pluginApi.manifest)
                        pluginApi.closePanel(pluginApi.panelOpenScreen)
                    }
                }
            }
        }
    }
}
