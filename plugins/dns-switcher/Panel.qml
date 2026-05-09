import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import qs.Services.UI

Item {
    id: root

    property var pluginApi: null
    readonly property var mainInstance: pluginApi?.mainInstance

    property real contentPreferredWidth: Math.round(360 * Style.uiScaleRatio)
    property real contentPreferredHeight: mainLayout.implicitHeight + (Style.marginL * 2)

    readonly property var geometryPlaceholder: bg
    readonly property bool allowAttach: true

    // State for Adding
    property string newName: ""
    property string newIp: ""
    property bool isAdding: false
    property string validationError: ""

    Rectangle {
        id: bg
        anchors.fill: parent
        color: Color.mSurface
        radius: Style.radiusL
        border.color: Qt.alpha(Color.mOutline, 0.2)
        border.width: 1

        ColumnLayout {
            id: mainLayout
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginM

            NBox {
                Layout.fillWidth: true
                Layout.preferredHeight: headerRow.implicitHeight + Style.marginM

                RowLayout {
                    id: headerRow
                    anchors.fill: parent
                    anchors.margins: Style.marginS
                    spacing: Style.marginS

                    NIcon {
                        icon: "globe"
                        pointSize: Style.fontSizeL
                        color: Color.mPrimary
                    }

                    NText {
                        text: pluginApi?.tr("plugin.title") || "DNS Switcher"
                        pointSize: Style.fontSizeL
                        font.weight: Style.fontWeightBold
                        color: Color.mOnSurface
                        Layout.fillWidth: true
                    }

                    NText {
                        text: mainInstance?.currentDnsName || "..."
                        pointSize: Style.fontSizeS
                        color: (mainInstance?.isChanging) ? Color.mPrimary : Color.mSecondary
                        font.weight: Font.Medium
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: errorText.implicitHeight + Style.marginM
                visible: (mainInstance?.lastError || "") !== ""
                color: Qt.alpha(Color.mError, 0.1)
                radius: Style.radiusS
                border.color: Qt.alpha(Color.mError, 0.3)
                border.width: 1

                NText {
                    id: errorText
                    anchors.fill: parent
                    anchors.margins: Style.marginS
                    text: mainInstance?.lastError || ""
                    color: Color.mError
                    pointSize: Style.fontSizeS
                    wrapMode: Text.WordWrap
                }
            }

            NScrollView {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.round(240 * Style.uiScaleRatio)
                clip: true

                ColumnLayout {
                    width: parent.width
                    spacing: Style.marginS

                    component DnsOption: Rectangle {
                        id: opt
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.round(50 * Style.uiScaleRatio)
                        radius: Style.radiusM

                        property string label: ""
                        property string providerId: ""
                        property string providerIp: ""
                        property bool isCustom: false
                        property int customIndex: -1
                        property bool isActive: (mainInstance?.activeProviderId || "") === providerId
                        property bool isDisabled: mainInstance?.isChanging || false

                        color: isActive ? Color.mPrimary : Color.mSurfaceVariant
                        opacity: isDisabled ? 0.6 : 1.0
                        Behavior on color { ColorAnimation { duration: Style.animationFast } }
                        Behavior on opacity { NumberAnimation { duration: 150 } }

                        Rectangle {
                            anchors.fill: parent
                            radius: opt.radius
                            color: (hoverArea.containsMouse && !opt.isActive && !opt.isDisabled)
                                   ? Color.mHover : "transparent"
                            opacity: (hoverArea.containsMouse && !opt.isActive && !opt.isDisabled)
                                     ? 0.2 : 0
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Style.marginM
                            anchors.rightMargin: Style.marginM
                            spacing: Style.marginM

                            NIcon {
                                icon: opt.isActive ? "check" : "circle"
                                pointSize: Style.fontSizeM
                                color: opt.isActive ? Color.mOnPrimary : Color.mOnSurfaceVariant
                            }

                            NText {
                                text: opt.label
                                pointSize: Style.fontSizeM
                                font.weight: Font.Medium
                                color: opt.isActive ? Color.mOnPrimary : Color.mOnSurface
                                Layout.fillWidth: true
                            }

                            NText {
                                text: opt.providerIp
                                pointSize: Style.fontSizeXS
                                color: opt.isActive
                                       ? Qt.alpha(Color.mOnPrimary, 0.7)
                                       : Color.mOnSurfaceVariant
                                visible: opt.providerIp !== ""
                            }

                            NIconButton {
                                visible: opt.isCustom
                                icon: "trash"
                                colorFg: opt.isActive ? Color.mOnPrimary : Color.mError
                                enabled: !opt.isDisabled
                                onClicked: {
                                    if (mainInstance && opt.customIndex >= 0) {
                                        mainInstance.removeCustomServer(opt.customIndex);
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: hoverArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: opt.isDisabled ? Qt.ForbiddenCursor : Qt.PointingHandCursor
                            onClicked: {
                                if (opt.isDisabled) return;
                                if (mainInstance) {
                                    mainInstance.setDns(opt.isCustom ? opt.providerIp : opt.providerId);
                                }
                                if (pluginApi) {
                                    pluginApi.withCurrentScreen(function(s) {
                                        pluginApi.closePanel(s);
                                    });
                                }
                            }
                        }
                    }

                    DnsOption {
                        label: "Google"
                        providerId: "google"
                        providerIp: "8.8.8.8 8.8.4.4"
                    }
                    DnsOption {
                        label: "Cloudflare"
                        providerId: "cloudflare"
                        providerIp: "1.1.1.1 1.0.0.1"
                    }
                    DnsOption {
                        label: "OpenDNS"
                        providerId: "opendns"
                        providerIp: "208.67.222.222 208.67.220.220"
                    }
                    DnsOption {
                        label: "AdGuard"
                        providerId: "adguard"
                        providerIp: "94.140.14.14 94.140.15.15"
                    }
                    DnsOption {
                        label: "Quad9"
                        providerId: "quad9"
                        providerIp: "9.9.9.9 149.112.112.112"
                    }

                    Repeater {
                        model: mainInstance ? mainInstance.customProviders : []
                        delegate: DnsOption {
                            label: modelData.label
                            providerId: "custom_" + index
                            providerIp: modelData.ip
                            isCustom: true
                            customIndex: index
                        }
                    }
                }
            }

            NButton {
                Layout.fillWidth: true
                text: root.isAdding
                      ? (pluginApi?.tr("panel.cancel") || "Cancel")
                      : (pluginApi?.tr("panel.add_server") || "Add Custom Server")
                icon: root.isAdding ? "x" : "plus"
                backgroundColor: root.isAdding ? Color.mSurfaceVariant : Qt.alpha(Color.mPrimary, 0.15)
                textColor: root.isAdding ? Color.mOnSurface : Color.mPrimary
                enabled: !(mainInstance?.isChanging || false)
                onClicked: {
                    root.isAdding = !root.isAdding;
                    if (!root.isAdding) {
                        root.newName = "";
                        root.newIp = "";
                        root.validationError = "";
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                visible: root.isAdding
                spacing: Style.marginS

                RowLayout {
                    spacing: Style.marginS

                    NTextInput {
                        id: nameInput
                        Layout.fillWidth: true
                        label: pluginApi?.tr("panel.name_placeholder") || "Name"
                        placeholderText: pluginApi?.tr("panel.name_placeholder") || "e.g. My DNS"
                        text: root.newName
                        onTextChanged: {
                            root.newName = text;
                            root.validationError = "";
                        }
                    }

                    NTextInput {
                        id: ipInput
                        Layout.fillWidth: true
                        label: pluginApi?.tr("panel.ip_placeholder") || "IP Address"
                        placeholderText: pluginApi?.tr("panel.ip_placeholder") || "e.g. 1.2.3.4 5.6.7.8"
                        text: root.newIp
                        onTextChanged: {
                            root.newIp = text;
                            root.validationError = "";
                        }
                    }
                }

                NText {
                    Layout.fillWidth: true
                    visible: root.validationError !== ""
                    text: root.validationError
                    color: Color.mError
                    pointSize: Style.fontSizeXS
                    wrapMode: Text.WordWrap
                }

                NButton {
                    Layout.fillWidth: true
                    text: pluginApi?.tr("panel.save") || "Save"
                    icon: "check"
                    enabled: root.newName.trim() !== "" && root.newIp.trim() !== ""
                    onClicked: {
                        if (mainInstance) {
                            var success = mainInstance.addCustomServer(root.newName, root.newIp);
                            if (success) {
                                root.newName = "";
                                root.newIp = "";
                                root.isAdding = false;
                                root.validationError = "";
                            } else {
                                root.validationError = pluginApi?.tr("error.invalid_ip")
                                                       || "Invalid IP address format. Use: x.x.x.x or x.x.x.x x.x.x.x";
                            }
                        }
                    }
                }
            }

            NButton {
                Layout.fillWidth: true
                Layout.topMargin: Style.marginS
                text: pluginApi?.tr("panel.reset") || "Reset to Default (ISP)"
                icon: "refresh"
                backgroundColor: Qt.alpha(Color.mError, 0.15)
                textColor: Color.mError
                enabled: !(mainInstance?.isChanging || false)
                         && (mainInstance?.isCustomDns || false)
                onClicked: {
                    if (mainInstance) {
                        mainInstance.setDns("default");
                    }
                    if (pluginApi) {
                        pluginApi.withCurrentScreen(function(s) {
                            pluginApi.closePanel(s);
                        });
                    }
                }
            }
        }
    }
}
