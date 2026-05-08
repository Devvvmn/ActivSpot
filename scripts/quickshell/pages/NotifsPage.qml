import QtQuick
import QtQuick.Layouts
import "../themes"

Item {
    id: root
    property var island

    Item {
        anchors.fill: parent
        anchors.margins: island.s(20)
        anchors.bottomMargin: island.s(68)

        ColumnLayout {
            anchors.fill: parent
            spacing: island.s(8)

            // ── Header: title | DND toggle | clear ──────────────
            RowLayout {
                Layout.fillWidth: true; spacing: island.s(6)

                Text {
                    text: "NOTIFICATIONS"
                    font.family: "JetBrains Mono"; font.pixelSize: island.s(11); font.weight: Font.Black; font.letterSpacing: 1.5
                    color: island.mauve; Layout.fillWidth: true
                }

                Item {
                    implicitHeight: island.s(44)
                    implicitWidth: dndLabel.implicitWidth + island.s(16)

                    Rectangle {
                        anchors.centerIn: parent
                        height: island.s(22); width: parent.implicitWidth; radius: island.s(11)
                        color: island.dndEnabled
                            ? Qt.rgba(island.mauve.r, island.mauve.g, island.mauve.b, 0.22)
                            : (dndMouse.containsMouse
                                ? Qt.rgba(island.surface1.r, island.surface1.g, island.surface1.b, 0.7)
                                : Qt.rgba(island.surface0.r, island.surface0.g, island.surface0.b, 0.5))
                        border.width: 1
                        border.color: island.dndEnabled
                            ? Qt.rgba(island.mauve.r, island.mauve.g, island.mauve.b, 0.5)
                            : Qt.rgba(island.text.r, island.text.g, island.text.b, 0.08)
                        Behavior on color { ColorAnimation { duration: 180 } }
                        Behavior on border.color { ColorAnimation { duration: 180 } }
                        Text {
                            id: dndLabel; anchors.centerIn: parent
                            text: island.dndEnabled ? "󰂛  DND" : "󰂚  DND"
                            font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(11)
                            color: island.dndEnabled ? island.mauve : island.subtext0
                            Behavior on color { ColorAnimation { duration: 180 } }
                        }
                    }
                    MouseArea {
                        id: dndMouse; anchors.fill: parent; hoverEnabled: true
                        onClicked: {
                            island.dndEnabled = !island.dndEnabled
                            island.exec("mkdir -p ~/.cache && echo '" + (island.dndEnabled ? "1" : "0") + "' > ~/.cache/qs_dnd")
                        }
                    }
                }

                Item {
                    visible: island.notifHistory.count > 0
                    implicitHeight: island.s(44)
                    implicitWidth: clearAllLabel.implicitWidth + island.s(14)

                    Rectangle {
                        anchors.centerIn: parent
                        height: island.s(22); width: parent.implicitWidth; radius: island.s(11)
                        color: clearAllMouse.containsMouse
                            ? Qt.rgba(island.surface1.r, island.surface1.g, island.surface1.b, 0.8)
                            : Qt.rgba(island.surface0.r, island.surface0.g, island.surface0.b, 0.5)
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Text { id: clearAllLabel; anchors.centerIn: parent; text: "Clear"; font.family: Theme.fontUI; font.pixelSize: island.s(11); color: island.subtext0 }
                    }
                    MouseArea {
                        id: clearAllMouse; anchors.fill: parent; hoverEnabled: true
                        onClicked: { island.notifHistory.clear(); island.saveNotifHistory() }
                    }
                }
            }

            // ── Empty state ─────────────────────────────────────
            Item {
                Layout.fillWidth: true; Layout.fillHeight: true
                visible: island.notifHistory.count === 0
                ColumnLayout {
                    anchors.centerIn: parent; spacing: island.s(10)
                    Text { Layout.alignment: Qt.AlignHCenter; text: "󰂚"; font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(40); color: island.surface2 }
                    Text { Layout.alignment: Qt.AlignHCenter; text: "No notifications"; font.family: Theme.fontUI; font.pixelSize: island.s(13); color: island.subtext0; opacity: 0.6 }
                }
            }

            // ── Notification history list ───────────────────────
            ListView {
                Layout.fillWidth: true; Layout.fillHeight: true
                model: island.notifHistory
                visible: island.notifHistory.count > 0
                spacing: island.s(5); clip: true

                add:        Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 280; easing.type: Easing.OutCubic } }
                remove:     Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 200; easing.type: Easing.InCubic } }
                displaced:  Transition { NumberAnimation { property: "y"; duration: 260; easing.type: Easing.OutExpo } }

                delegate: Rectangle {
                    id: notifDelegate
                    width: ListView.view.width; height: island.s(56); radius: island.s(12)
                    color: Theme.surfaceIdle
                    border.width: 1; border.color: Theme.withAlpha(island.text, 0.07)

                    property color accentColor: island.appAccentColor(model.appName)

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: island.s(8); anchors.rightMargin: island.s(8)
                        spacing: island.s(8)

                        Rectangle {
                            width: island.s(3); Layout.fillHeight: true
                            Layout.topMargin: island.s(12); Layout.bottomMargin: island.s(12)
                            radius: island.s(2); color: notifDelegate.accentColor; opacity: 0.75
                        }

                        Rectangle {
                            Layout.preferredWidth: island.s(34); Layout.preferredHeight: island.s(34)
                            radius: island.s(9); clip: true; Layout.alignment: Qt.AlignVCenter
                            color: Qt.rgba(notifDelegate.accentColor.r, notifDelegate.accentColor.g, notifDelegate.accentColor.b, 0.12)
                            Image {
                                id: histIcon; anchors.fill: parent; anchors.margins: island.s(4)
                                source: {
                                    let ic = model.icon || ""
                                    if (ic === "") return ""
                                    if (ic.startsWith("/") || ic.startsWith("file://") || ic.startsWith("http")) return ic
                                    return "image://theme/" + ic
                                }
                                fillMode: Image.PreserveAspectFit; asynchronous: true
                            }
                            Text { anchors.centerIn: parent; text: "󰵙"; font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(16); color: notifDelegate.accentColor; visible: histIcon.status !== Image.Ready }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter; spacing: island.s(1)
                            Text {
                                text: (model.appName || "System") + (model.title ? "  ·  " + model.title : "")
                                font.family: Theme.fontUI; font.pixelSize: island.s(12); font.weight: Font.DemiBold
                                color: island.text; Layout.fillWidth: true; elide: Text.ElideRight
                            }
                            Text {
                                text: model.body || ""
                                font.family: Theme.fontUI; font.pixelSize: island.s(12); font.weight: Font.Normal
                                color: island.subtext0; Layout.fillWidth: true; elide: Text.ElideRight; visible: text !== ""
                            }
                        }

                        Item {
                            Layout.preferredWidth: island.s(44); Layout.preferredHeight: island.s(44)
                            Layout.alignment: Qt.AlignVCenter

                            Rectangle {
                                anchors.centerIn: parent
                                width: island.s(22); height: island.s(22); radius: island.s(11)
                                color: histDismissMouse.containsMouse
                                    ? Qt.rgba(island.surface1.r, island.surface1.g, island.surface1.b, 0.8)
                                    : "transparent"
                                Behavior on color { ColorAnimation { duration: 120 } }
                                Text { anchors.centerIn: parent; text: "󰅖"; font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(11); color: island.subtext0 }
                            }
                            MouseArea {
                                id: histDismissMouse; anchors.fill: parent; hoverEnabled: true
                                onClicked: { island.notifHistory.remove(index); island.saveNotifHistory() }
                            }
                        }
                    }
                }
            }
        }
    }
}
