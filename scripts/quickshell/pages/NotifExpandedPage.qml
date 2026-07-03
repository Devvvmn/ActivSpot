import QtQuick
import QtQuick.Layouts
import "../themes"

Item {
    id: root
    property var island

    property real _entryY: island.s(22)

    NumberAnimation {
        running: true
        target: root; property: "_entryY"
        from: island.s(22); to: 0
        duration: 620; easing.type: Easing.OutExpo
    }

    readonly property var _actions: (island.notifData && island.notifData.actions) ? island.notifData.actions : []
    readonly property bool _hasReply: island.notifData ? island.notifData.hasReply === true : false

    Item {
        anchors.fill: parent
        anchors.margins: island.s(14)
        transform: Translate { y: root._entryY }

        ColumnLayout {
            anchors.fill: parent
            spacing: island.s(8)

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: island.s(14)

            // Accent bar
            Rectangle {
                Layout.preferredWidth: island.s(3); Layout.fillHeight: true; radius: island.s(2)
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: Qt.rgba(island.notifAccent.r, island.notifAccent.g, island.notifAccent.b, 0.9) }
                    GradientStop { position: 1.0; color: Qt.rgba(island.notifAccent.r, island.notifAccent.g, island.notifAccent.b, 0.3) }
                }
                opacity: island.notifPulse * 0.9 + 0.1
            }

            // App icon — splats in with a spring (liquid entry)
            Rectangle {
                Layout.preferredWidth: island.s(40); Layout.preferredHeight: island.s(40); Layout.alignment: Qt.AlignVCenter
                radius: island.s(10)
                color: Qt.rgba(island.notifAccent.r, island.notifAccent.g, island.notifAccent.b, 0.12)
                border.width: 1; border.color: Qt.rgba(island.notifAccent.r, island.notifAccent.g, island.notifAccent.b, 0.25)
                SpringAnimation on scale {
                    from: 0.3; to: 1.0; spring: 4.2; damping: 0.3
                    running: !Theme.reduceMotion
                }
                Image {
                    id: notifIconImg; anchors.fill: parent; anchors.margins: island.s(5)
                    fillMode: Image.PreserveAspectFit; asynchronous: true

                    property string iconName: island.notifData ? (island.notifData.icon || "") : ""
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
                        // Content-image heuristic: avatars are small squares; a wide
                        // or large source (screenshot, photo) earns a preview strip.
                        if (status === Image.Ready && iconIsPath) {
                            if (sourceSize.width >= 300 ||
                                (sourceSize.height > 0 && sourceSize.width / sourceSize.height >= 1.4))
                                island.notifHasImage = true
                        }
                    }
                }
                Text {
                    anchors.centerIn: parent; text: "󰵙"
                    font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(20); color: island.notifAccent
                    visible: notifIconImg.status !== Image.Ready
                }
            }

            // Text content
            ColumnLayout {
                Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter; spacing: island.s(3)
                RowLayout {
                    Layout.fillWidth: true; spacing: island.s(6)
                    Rectangle {
                        width: island.s(6); height: island.s(6); radius: island.s(3)
                        color: island.notifAccent; opacity: island.notifPulse; Layout.alignment: Qt.AlignVCenter
                    }
                    Text {
                        text: island.notifData ? (island.notifData.appName || "System") : ""
                        font.family: Theme.fontUI; font.pixelSize: island.s(11); font.weight: Font.Medium
                        color: island.notifAccent; opacity: 0.85; elide: Text.ElideRight; Layout.fillWidth: true
                    }
                }
                Text {
                    text: island.notifData ? (island.notifData.title || "") : ""
                    font.family: Theme.fontUI; font.pixelSize: island.s(14); font.weight: Font.DemiBold
                    color: island.text; wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight; Layout.fillWidth: true
                }
                Text {
                    text: island.notifData ? (island.notifData.body || "") : ""
                    font.family: Theme.fontUI; font.pixelSize: island.s(12); font.weight: Font.Normal
                    color: island.subtext0; wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight
                    Layout.fillWidth: true; visible: text !== ""
                }
            }

            // Dismiss button
            Rectangle {
                Layout.preferredWidth: island.s(22); Layout.preferredHeight: island.s(22); Layout.alignment: Qt.AlignTop
                radius: island.s(11)
                color: notifDismissMouse.containsMouse
                    ? Qt.rgba(island.notifAccent.r, island.notifAccent.g, island.notifAccent.b, 0.2)
                    : Qt.rgba(island.surface0.r, island.surface0.g, island.surface0.b, 0.5)
                border.width: 1
                border.color: Qt.rgba(island.notifAccent.r, island.notifAccent.g, island.notifAccent.b, notifDismissMouse.containsMouse ? 0.5 : 0.15)
                Behavior on color { ColorAnimation { duration: 180 } }
                Text { anchors.centerIn: parent; text: "󰅖"; font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(11); color: island.subtext0 }
                MouseArea {
                    id: notifDismissMouse; anchors.fill: parent; hoverEnabled: true
                    onClicked: { island.dismissNotif(); mouse.accepted = true }
                }
            }
        }

        // ── Content image preview (screenshots / photos) ─────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: island.s(17)
            Layout.preferredHeight: island.s(60)
            radius: island.s(10); clip: true
            color: Qt.rgba(island.surface0.r, island.surface0.g, island.surface0.b, 0.4)
            visible: island.notifHasImage
            Image {
                anchors.fill: parent
                source: island.notifHasImage && notifIconImg.iconIsPath ? notifIconImg.iconName : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }

        // ── Action chips + reply toggle ──────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: island.s(17)   // align under text (accent bar + icon)
            spacing: island.s(8)
            visible: root._actions.length > 0 || root._hasReply

            // Reply chip first — the headline action
            Rectangle {
                visible: root._hasReply
                implicitWidth: replyChipLabel.implicitWidth + island.s(24)
                implicitHeight: island.s(28)
                radius: height / 2
                color: replyChipMa.containsMouse || island.notifReplyOpen
                    ? Qt.rgba(island.mauve.r, island.mauve.g, island.mauve.b, 0.28)
                    : Qt.rgba(island.mauve.r, island.mauve.g, island.mauve.b, 0.14)
                border.width: 1
                border.color: Qt.rgba(island.mauve.r, island.mauve.g, island.mauve.b, 0.4)
                Behavior on color { ColorAnimation { duration: 150 } }
                Text {
                    id: replyChipLabel; anchors.centerIn: parent
                    text: "󰑚  Reply"
                    font.family: Theme.fontUI; font.pixelSize: island.s(11); font.weight: Font.Medium
                    color: island.mauve
                }
                MouseArea {
                    id: replyChipMa; anchors.fill: parent; hoverEnabled: true
                    onClicked: island.notifReplyOpen = !island.notifReplyOpen
                }
            }

            Repeater {
                model: root._actions
                delegate: Rectangle {
                    // Hide "default" — it's the whole-banner click action, not a chip
                    visible: modelData.k !== "default"
                    implicitWidth: chipLabel.implicitWidth + island.s(24)
                    implicitHeight: island.s(28)
                    radius: height / 2
                    color: chipMa.containsMouse
                        ? Qt.rgba(island.notifAccent.r, island.notifAccent.g, island.notifAccent.b, 0.24)
                        : Qt.rgba(island.surface0.r, island.surface0.g, island.surface0.b, 0.55)
                    border.width: 1
                    border.color: Qt.rgba(island.notifAccent.r, island.notifAccent.g, island.notifAccent.b, chipMa.containsMouse ? 0.5 : 0.18)
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Text {
                        id: chipLabel; anchors.centerIn: parent
                        text: modelData.t || modelData.k
                        font.family: Theme.fontUI; font.pixelSize: island.s(11); font.weight: Font.Medium
                        color: island.text
                    }
                    MouseArea {
                        id: chipMa; anchors.fill: parent; hoverEnabled: true
                        onClicked: island.notifInvokeAction(modelData.k)
                    }
                }
            }

            Item { Layout.fillWidth: true }   // left-pack the chips
        }

        // ── Inline reply field ───────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: island.s(17)
            Layout.bottomMargin: island.s(2)
            implicitHeight: island.s(38)
            radius: island.s(12)
            visible: island.notifReplyOpen
            color: Qt.rgba(island.surface0.r, island.surface0.g, island.surface0.b, 0.6)
            border.width: 1
            border.color: replyField.activeFocus
                ? Qt.rgba(island.mauve.r, island.mauve.g, island.mauve.b, 0.55)
                : Qt.rgba(island.text.r, island.text.g, island.text.b, 0.1)
            Behavior on border.color { ColorAnimation { duration: 150 } }

            onVisibleChanged: if (visible) replyField.forceActiveFocus()

            TextInput {
                id: replyField
                anchors.fill: parent
                anchors.leftMargin: island.s(14)
                anchors.rightMargin: sendBtn.width + island.s(16)
                verticalAlignment: TextInput.AlignVCenter
                font.family: Theme.fontUI; font.pixelSize: island.s(12)
                color: island.text
                clip: true
                onAccepted: { island.notifSendReply(text); text = "" }
                Keys.onEscapePressed: (event) => { island.notifReplyOpen = false; event.accepted = true }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Write a reply…"
                    font.family: Theme.fontUI; font.pixelSize: island.s(12)
                    color: island.subtext0; opacity: 0.6
                    visible: replyField.text === "" && !replyField.activeFocus
                }
            }

            Rectangle {
                id: sendBtn
                anchors.right: parent.right; anchors.rightMargin: island.s(5)
                anchors.verticalCenter: parent.verticalCenter
                width: island.s(28); height: island.s(28); radius: height / 2
                color: replyField.text.trim() !== ""
                    ? Qt.rgba(island.mauve.r, island.mauve.g, island.mauve.b, sendMa.containsMouse ? 0.9 : 0.7)
                    : Qt.rgba(island.surface0.r, island.surface0.g, island.surface0.b, 0.5)
                Behavior on color { ColorAnimation { duration: 150 } }
                Text {
                    anchors.centerIn: parent; text: "󰒊"
                    font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(13)
                    color: replyField.text.trim() !== "" ? island.base : island.subtext0
                }
                MouseArea {
                    id: sendMa; anchors.fill: parent; hoverEnabled: true
                    onClicked: { island.notifSendReply(replyField.text); replyField.text = "" }
                }
            }
        }

        }
    }
}
