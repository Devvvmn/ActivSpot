import QtQuick
import QtQuick.Layouts
import "../themes"

Item {
    id: root
    property var island

    function relativeTime(ts) {
        if (!ts || ts === 0) return ""
        const diff = Math.floor((Date.now() - ts) / 1000)
        if (diff < 60)    return "now"
        if (diff < 3600)  return Math.floor(diff / 60)   + "m"
        if (diff < 86400) return Math.floor(diff / 3600) + "h"
        return Math.floor(diff / 86400) + "d"
    }

    Item {
        anchors.fill: parent
        anchors.margins: island.s(20)
        anchors.bottomMargin: island.s(68)

        ColumnLayout {
            anchors.fill: parent
            spacing: island.s(9)

            // ── Header ──────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: island.s(6)

                Text {
                    text: "NOTIFICATIONS"
                    font.family: "JetBrains Mono"; font.pixelSize: island.s(11)
                    font.weight: Font.Black; font.letterSpacing: 1.5
                    color: island.mauve
                }

                Rectangle {
                    visible: island.notifHistory.count > 0
                    implicitWidth: cntText.implicitWidth + island.s(10)
                    implicitHeight: island.s(16); radius: island.s(8)
                    color: Qt.rgba(island.mauve.r, island.mauve.g, island.mauve.b, 0.18)
                    border.width: 1
                    border.color: Qt.rgba(island.mauve.r, island.mauve.g, island.mauve.b, 0.30)
                    Behavior on implicitWidth { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }
                    Text {
                        id: cntText; anchors.centerIn: parent
                        text: island.notifHistory.count.toString()
                        font.family: "JetBrains Mono"; font.pixelSize: island.s(10)
                        font.weight: Font.Bold; color: island.mauve
                    }
                }

                Item { Layout.fillWidth: true }

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
                        Behavior on color       { ColorAnimation { duration: 180 } }
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
                    implicitWidth: clearLabel.implicitWidth + island.s(14)
                    Rectangle {
                        anchors.centerIn: parent
                        height: island.s(22); width: parent.implicitWidth; radius: island.s(11)
                        color: clearMouse.containsMouse
                            ? Qt.rgba(island.surface1.r, island.surface1.g, island.surface1.b, 0.8)
                            : Qt.rgba(island.surface0.r, island.surface0.g, island.surface0.b, 0.5)
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Text {
                            id: clearLabel; anchors.centerIn: parent; text: "Clear"
                            font.family: Theme.fontUI; font.pixelSize: island.s(11); color: island.subtext0
                        }
                    }
                    MouseArea {
                        id: clearMouse; anchors.fill: parent; hoverEnabled: true
                        onClicked: { island.notifHistory.clear(); island.saveNotifHistory() }
                    }
                }
            }

            // ── Empty state ─────────────────────────────────────────
            Item {
                Layout.fillWidth: true; Layout.fillHeight: true
                visible: island.notifHistory.count === 0

                ColumnLayout {
                    anchors.centerIn: parent; spacing: island.s(8)

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: island.s(52); height: island.s(52); radius: island.s(16)
                        color: Qt.rgba(island.surface0.r, island.surface0.g, island.surface0.b, 0.6)
                        border.width: 1
                        border.color: Qt.rgba(island.text.r, island.text.g, island.text.b, 0.07)
                        Text {
                            anchors.centerIn: parent; text: "󰂚"
                            font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(24)
                            color: island.surface2; opacity: 0.85
                        }
                        SequentialAnimation on scale {
                            running: !Theme.reduceMotion; loops: Animation.Infinite
                            NumberAnimation { from: 1.0; to: 1.04; duration: 2200; easing.type: Easing.InOutSine }
                            NumberAnimation { from: 1.04; to: 1.0; duration: 2200; easing.type: Easing.InOutSine }
                        }
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter; text: "All clear"
                        font.family: Theme.fontUI; font.pixelSize: island.s(14)
                        font.weight: Font.DemiBold; color: island.subtext0; opacity: 0.65
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter; text: "No notifications"
                        font.family: Theme.fontUI; font.pixelSize: island.s(11)
                        color: island.subtext0; opacity: 0.35
                    }
                }
            }

            // ── Notification list ────────────────────────────────────
            ListView {
                Layout.fillWidth: true; Layout.fillHeight: true
                model: island.notifHistory
                visible: island.notifHistory.count > 0
                spacing: island.s(5); clip: true

                add: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 260; easing.type: Easing.OutCubic }
                        NumberAnimation { property: "y"; from: -island.s(8); duration: 260; easing.type: Easing.OutCubic }
                    }
                }
                remove: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 180; easing.type: Easing.InCubic }
                        NumberAnimation { property: "x"; to: island.s(20); duration: 180; easing.type: Easing.InCubic }
                    }
                }
                displaced: Transition {
                    NumberAnimation { property: "y"; duration: 240; easing.type: Easing.OutExpo }
                }

                delegate: Item {
                    id: notifDelegate
                    width: ListView.view.width
                    readonly property bool hasBody: (model.body || "") !== ""
                    height: island.s(hasBody ? 72 : 56)
                    Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }

                    property color accentColor: island.appAccentColor(model.appName)
                    property bool  hovered:     cardMouse.containsMouse

                    scale: cardMouse.pressed ? 0.982 : 1.0
                    Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutQuad } }

                    Rectangle {
                        anchors.fill: parent
                        radius: island.s(14)
                        color: notifDelegate.hovered ? Theme.surfaceHover : Theme.surfaceIdle
                        border.width: 1
                        border.color: notifDelegate.hovered
                            ? Qt.rgba(notifDelegate.accentColor.r, notifDelegate.accentColor.g, notifDelegate.accentColor.b, 0.30)
                            : Theme.withAlpha(island.text, 0.06)
                        Behavior on color       { ColorAnimation { duration: 140 } }
                        Behavior on border.color { ColorAnimation { duration: 140 } }

                        // Left accent bar — gradient top to bottom
                        Rectangle {
                            x: 0; y: island.s(10)
                            width: island.s(3); height: parent.height - island.s(20)
                            radius: island.s(2)
                            gradient: Gradient {
                                orientation: Gradient.Vertical
                                GradientStop { position: 0.0; color: Qt.rgba(notifDelegate.accentColor.r, notifDelegate.accentColor.g, notifDelegate.accentColor.b, 0.90) }
                                GradientStop { position: 1.0; color: Qt.rgba(notifDelegate.accentColor.r, notifDelegate.accentColor.g, notifDelegate.accentColor.b, 0.22) }
                            }
                        }

                        // App icon
                        Rectangle {
                            id: iconBg
                            x: island.s(10); anchors.verticalCenter: parent.verticalCenter
                            width: island.s(36); height: island.s(36); radius: island.s(10)
                            color: Qt.rgba(notifDelegate.accentColor.r, notifDelegate.accentColor.g, notifDelegate.accentColor.b, 0.13)
                            border.width: 1
                            border.color: Qt.rgba(notifDelegate.accentColor.r, notifDelegate.accentColor.g, notifDelegate.accentColor.b, 0.28)

                            Image {
                                id: notifIcon
                                anchors.fill: parent; anchors.margins: island.s(5)
                                fillMode: Image.PreserveAspectFit; asynchronous: true

                                property string iconName: model.icon || ""
                                readonly property bool iconIsPath: iconName !== "" && (
                                    iconName.startsWith("/") || iconName.startsWith("file://") || iconName.startsWith("http"))
                                property int iconTry: 0
                                onIconNameChanged: iconTry = 0

                                source: {
                                    if (iconName === "") return ""
                                    if (iconIsPath)     return iconName
                                    switch (iconTry) {
                                    case 0: return "image://theme/" + iconName
                                    case 1: return "file:///var/lib/flatpak/exports/share/icons/hicolor/128x128/apps/" + iconName + ".png"
                                    case 2: return "file:///var/lib/flatpak/exports/share/icons/hicolor/256x256/apps/"  + iconName + ".png"
                                    case 3: return "file:///var/lib/flatpak/exports/share/icons/hicolor/scalable/apps/" + iconName + ".svg"
                                    default: return ""
                                    }
                                }
                                onStatusChanged: {
                                    if (status === Image.Error && !iconIsPath && iconTry < 3) iconTry++
                                }
                            }
                            Text {
                                anchors.centerIn: parent; text: "󰵙"
                                font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(16)
                                color: notifDelegate.accentColor
                                visible: notifIcon.status !== Image.Ready
                            }
                        }

                        // Text block
                        Column {
                            anchors.left:  iconBg.right;      anchors.leftMargin:  island.s(9)
                            anchors.right: dismissArea.left;  anchors.rightMargin: island.s(4)
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: island.s(3)

                            // App name + timestamp
                            Row {
                                spacing: island.s(5)
                                Text {
                                    text: model.appName || "System"
                                    font.family: Theme.fontUI; font.pixelSize: island.s(11)
                                    font.weight: Font.SemiBold
                                    color: notifDelegate.accentColor
                                }
                                Text {
                                    text: "· " + root.relativeTime(model.timestamp || 0)
                                    visible: root.relativeTime(model.timestamp || 0) !== ""
                                    font.family: "JetBrains Mono"; font.pixelSize: island.s(10)
                                    color: island.subtext0; opacity: 0.45
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            // Title
                            Text {
                                width: parent.width
                                text: model.title || ""
                                visible: text !== ""
                                font.family: Theme.fontUI; font.pixelSize: island.s(12)
                                font.weight: Font.DemiBold
                                color: island.text; elide: Text.ElideRight
                            }

                            // Body
                            Text {
                                width: parent.width
                                text: model.body || ""
                                visible: text !== ""
                                font.family: Theme.fontUI; font.pixelSize: island.s(11)
                                color: island.subtext0; elide: Text.ElideRight
                            }
                        }

                        // Dismiss
                        Item {
                            id: dismissArea
                            anchors.right: parent.right; anchors.rightMargin: island.s(6)
                            anchors.top: parent.top
                            width: island.s(44); height: island.s(44)

                            Rectangle {
                                anchors.centerIn: parent
                                width: island.s(22); height: island.s(22); radius: island.s(11)
                                color: dismissMouse.containsMouse
                                    ? Qt.rgba(island.surface1.r, island.surface1.g, island.surface1.b, 0.9)
                                    : "transparent"
                                border.width: 1
                                border.color: Qt.rgba(island.text.r, island.text.g, island.text.b,
                                                      dismissMouse.containsMouse ? 0.14 : 0.0)
                                Behavior on color       { ColorAnimation { duration: 110 } }
                                Behavior on border.color { ColorAnimation { duration: 110 } }
                                Text {
                                    anchors.centerIn: parent; text: "󰅖"
                                    font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(10)
                                    color: island.subtext0
                                }
                            }
                            MouseArea {
                                id: dismissMouse; anchors.fill: parent; hoverEnabled: true
                                onClicked: { island.notifHistory.remove(index); island.saveNotifHistory() }
                            }
                        }
                    }

                    MouseArea {
                        id: cardMouse; anchors.fill: parent; hoverEnabled: true
                        propagateComposedEvents: true
                        onClicked: mouse.accepted = false
                    }
                }
            }
        }
    }
}
