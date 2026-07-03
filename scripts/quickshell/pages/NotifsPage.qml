import QtQuick
import QtQuick.Layouts
import "../themes"

Item {
    id: root
    property var island

    readonly property bool _open: island.expanded && island.currentPage === "notifs"

    // ── App grouping: consecutive same-app cards collapse into a stack ──
    // Keyed by appName; reassigned (not mutated) so bindings re-evaluate.
    property var expandedGroups: ({})
    function toggleGroup(app) {
        let g = Object.assign({}, expandedGroups)
        if (g[app]) delete g[app]; else g[app] = true
        expandedGroups = g
    }

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
                // spacing lives inside the delegate (bottom padding) — ListView
                // spacing would still apply to collapsed zero-height group rows
                spacing: 0; clip: true

                // Opacity-only transitions. Position (y) animations here are a trap:
                // when a second insert/group-toggle lands mid-flight, the running
                // transition keeps its stale target and cards freeze short of their
                // real position. Height/position changes now snap; fades stay.
                add: Transition {
                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 260; easing.type: Easing.OutCubic }
                }
                remove: Transition {
                    NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 160; easing.type: Easing.InCubic }
                }

                delegate: Item {
                    id: notifDelegate
                    width: ListView.view.width

                    // Per-card inline reply state
                    property bool replyOpen: false
                    // Captured here — inside the nested actions Repeater, `model.id`
                    // would resolve to the action row, not the notification.
                    readonly property int  _notifId:   model.id || 0
                    readonly property bool isLive:     model.live === true
                    // Captured at delegate level — the nested Repeater's model binding
                    // referencing `model.actions` directly throws TypeError during
                    // delegate teardown (context property already gone).
                    readonly property var  _acts:      model.actions !== undefined ? model.actions : null
                    readonly property bool hasActions: _acts !== null && _acts.count > 0
                    readonly property bool canReply:   model.hasReply === true && _notifId > 0

                    // ── Grouping: consecutive same-app runs collapse under the head ──
                    readonly property bool isGroupHead: index === 0 ||
                        (island.notifHistory.count > index - 1 && island.notifHistory.get(index - 1)
                            ? island.notifHistory.get(index - 1).appName !== model.appName : true)
                    readonly property int groupSize: {
                        let c = 1
                        for (let i = index + 1; i < island.notifHistory.count; i++) {
                            if (island.notifHistory.get(i).appName === model.appName) c++
                            else break
                        }
                        return c
                    }
                    readonly property bool groupExpanded: root.expandedGroups[model.appName] === true
                    readonly property bool rowVisible: isGroupHead || groupExpanded

                    // NO Behavior on height — animating delegate height desyncs
                    // ListView's item positioning and cards overlap.
                    // +s(5) = inter-card gap (delegate-owned, see ListView.spacing note)
                    height: rowVisible ? textCol.implicitHeight + island.s(22) + island.s(5) : 0
                    visible: rowVisible

                    property color accentColor: island.appAccentColor(model.appName)
                    property bool  hovered:     cardMouse.containsMouse

                    property real _entryX: island.s(36)
                    transform: Translate { x: notifDelegate._entryX }

                    Connections {
                        target: root
                        function on_OpenChanged() {
                            if (root._open) {
                                notifDelegate._entryX = island.s(36)
                                staggerTimer.interval = index * 80
                                staggerTimer.restart()
                            }
                        }
                    }
                    Timer {
                        id: staggerTimer
                        onTriggered: entryXAnim.restart()
                    }
                    NumberAnimation {
                        id: entryXAnim
                        target: notifDelegate; property: "_entryX"
                        from: island.s(36); to: 0
                        duration: 720; easing.type: Easing.OutExpo
                    }

                    scale: cardMouse.pressed ? 0.982 : 1.0
                    Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutQuad } }

                    // Declared FIRST = bottom of the stack: buttons/chips on top get
                    // their clicks natively; everything else lands here and is
                    // ACCEPTED — otherwise it falls through the card into the
                    // island's click-outside-to-close MouseArea and collapses it.
                    MouseArea {
                        id: cardMouse; anchors.fill: parent; hoverEnabled: true
                        onClicked: {
                            // Whole head card toggles its collapsed stack
                            if (notifDelegate.isGroupHead && notifDelegate.groupSize > 1)
                                root.toggleGroup(model.appName)
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.bottomMargin: island.s(5)   // delegate-owned inter-card gap
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
                            id: textCol
                            anchors.left:  iconBg.right;      anchors.leftMargin:  island.s(9)
                            anchors.right: dismissArea.left;  anchors.rightMargin: island.s(4)
                            anchors.top: parent.top;          anchors.topMargin:   island.s(11)
                            spacing: island.s(3)

                            // App name + timestamp + group stack badge
                            Row {
                                spacing: island.s(5)
                                Text {
                                    text: model.appName || "System"
                                    font.family: Theme.fontUI; font.pixelSize: island.s(11)
                                    font.weight: Font.DemiBold   // Font.SemiBold doesn't exist in QML → undefined-to-int warning
                                    color: notifDelegate.accentColor
                                }
                                Text {
                                    text: "· " + root.relativeTime(model.timestamp || 0)
                                    visible: root.relativeTime(model.timestamp || 0) !== ""
                                    font.family: "JetBrains Mono"; font.pixelSize: island.s(10)
                                    color: island.subtext0; opacity: 0.45
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                // "+N" — collapsed stack of same-app notifications
                                Rectangle {
                                    visible: notifDelegate.isGroupHead && notifDelegate.groupSize > 1
                                    width: grpLabel.implicitWidth + island.s(12)
                                    height: island.s(16); radius: island.s(8)
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: notifDelegate.groupExpanded
                                        ? Qt.rgba(notifDelegate.accentColor.r, notifDelegate.accentColor.g, notifDelegate.accentColor.b, 0.28)
                                        : Qt.rgba(notifDelegate.accentColor.r, notifDelegate.accentColor.g, notifDelegate.accentColor.b, 0.14)
                                    border.width: 1
                                    border.color: Qt.rgba(notifDelegate.accentColor.r, notifDelegate.accentColor.g, notifDelegate.accentColor.b, 0.35)
                                    Behavior on color { ColorAnimation { duration: 140 } }
                                    Text {
                                        id: grpLabel; anchors.centerIn: parent
                                        text: notifDelegate.groupExpanded ? "▴" : "+" + (notifDelegate.groupSize - 1)
                                        font.family: "JetBrains Mono"; font.pixelSize: island.s(9)
                                        font.weight: Font.Bold
                                        color: notifDelegate.accentColor
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.margins: -island.s(4)   // easier hit target
                                        onClicked: root.toggleGroup(model.appName)
                                    }
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

                            // Content image thumbnail (screenshots / photos, not avatars)
                            Rectangle {
                                width: parent.width; height: island.s(48)
                                radius: island.s(8); clip: true
                                color: Qt.rgba(island.surface0.r, island.surface0.g, island.surface0.b, 0.4)
                                visible: notifIcon.status === Image.Ready && notifIcon.iconIsPath &&
                                         (notifIcon.sourceSize.width >= 300 ||
                                          (notifIcon.sourceSize.height > 0 && notifIcon.sourceSize.width / notifIcon.sourceSize.height >= 1.4))
                                Image {
                                    anchors.fill: parent
                                    source: parent.visible ? notifIcon.iconName : ""
                                    fillMode: Image.PreserveAspectCrop; asynchronous: true
                                }
                            }

                            // Spacer above chips — chips only make sense while the
                            // notification is still live in the server process
                            Item {
                                width: 1; height: island.s(4)
                                visible: (notifDelegate.hasActions || notifDelegate.canReply) && notifDelegate.isLive
                            }

                            // Action chips + reply toggle
                            Row {
                                spacing: island.s(6)
                                visible: (notifDelegate.hasActions || notifDelegate.canReply) && notifDelegate.isLive

                                Rectangle {
                                    visible: notifDelegate.canReply
                                    width: histReplyLabel.implicitWidth + island.s(18)
                                    height: island.s(22); radius: height / 2
                                    color: histReplyMa.containsMouse || notifDelegate.replyOpen
                                        ? Qt.rgba(island.mauve.r, island.mauve.g, island.mauve.b, 0.26)
                                        : Qt.rgba(island.mauve.r, island.mauve.g, island.mauve.b, 0.12)
                                    border.width: 1
                                    border.color: Qt.rgba(island.mauve.r, island.mauve.g, island.mauve.b, 0.35)
                                    Behavior on color { ColorAnimation { duration: 140 } }
                                    Text {
                                        id: histReplyLabel; anchors.centerIn: parent
                                        text: "󰑚 Reply"
                                        font.family: Theme.fontUI; font.pixelSize: island.s(10); font.weight: Font.Medium
                                        color: island.mauve
                                    }
                                    MouseArea {
                                        id: histReplyMa; anchors.fill: parent; hoverEnabled: true
                                        onClicked: notifDelegate.replyOpen = !notifDelegate.replyOpen
                                    }
                                }

                                Repeater {
                                    model: notifDelegate.hasActions ? notifDelegate._acts : null
                                    delegate: Rectangle {
                                        visible: (model.k || "") !== "default"
                                        width: histChipLabel.implicitWidth + island.s(18)
                                        height: island.s(22); radius: height / 2
                                        color: histChipMa.containsMouse
                                            ? Qt.rgba(notifDelegate.accentColor.r, notifDelegate.accentColor.g, notifDelegate.accentColor.b, 0.22)
                                            : Qt.rgba(island.surface0.r, island.surface0.g, island.surface0.b, 0.55)
                                        border.width: 1
                                        border.color: Qt.rgba(notifDelegate.accentColor.r, notifDelegate.accentColor.g, notifDelegate.accentColor.b,
                                                              histChipMa.containsMouse ? 0.45 : 0.16)
                                        Behavior on color { ColorAnimation { duration: 140 } }
                                        Text {
                                            id: histChipLabel; anchors.centerIn: parent
                                            text: model.t || model.k || ""
                                            font.family: Theme.fontUI; font.pixelSize: island.s(10); font.weight: Font.Medium
                                            color: island.text
                                        }
                                        MouseArea {
                                            id: histChipMa; anchors.fill: parent; hoverEnabled: true
                                            onClicked: island.notifActionById(notifDelegate._notifId, model.k)
                                        }
                                    }
                                }
                            }

                            // Inline reply field (per card)
                            Rectangle {
                                width: parent.width
                                height: notifDelegate.replyOpen ? island.s(32) : 0
                                visible: notifDelegate.replyOpen
                                radius: island.s(10)
                                color: Qt.rgba(island.surface0.r, island.surface0.g, island.surface0.b, 0.6)
                                border.width: 1
                                border.color: histReplyField.activeFocus
                                    ? Qt.rgba(island.mauve.r, island.mauve.g, island.mauve.b, 0.5)
                                    : Qt.rgba(island.text.r, island.text.g, island.text.b, 0.1)

                                onVisibleChanged: if (visible) histReplyField.forceActiveFocus()

                                TextInput {
                                    id: histReplyField
                                    anchors.fill: parent
                                    anchors.leftMargin: island.s(10)
                                    anchors.rightMargin: histSendBtn.width + island.s(12)
                                    verticalAlignment: TextInput.AlignVCenter
                                    font.family: Theme.fontUI; font.pixelSize: island.s(11)
                                    color: island.text; clip: true
                                    onAccepted: {
                                        island.notifReplyById(notifDelegate._notifId, text)
                                        text = ""; notifDelegate.replyOpen = false
                                    }
                                    Keys.onEscapePressed: (event) => { notifDelegate.replyOpen = false; event.accepted = true }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "Write a reply…"
                                        font.family: Theme.fontUI; font.pixelSize: island.s(11)
                                        color: island.subtext0; opacity: 0.6
                                        visible: histReplyField.text === "" && !histReplyField.activeFocus
                                    }
                                }
                                Rectangle {
                                    id: histSendBtn
                                    anchors.right: parent.right; anchors.rightMargin: island.s(4)
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: island.s(24); height: island.s(24); radius: height / 2
                                    color: histReplyField.text.trim() !== ""
                                        ? Qt.rgba(island.mauve.r, island.mauve.g, island.mauve.b, histSendMa.containsMouse ? 0.9 : 0.7)
                                        : Qt.rgba(island.surface0.r, island.surface0.g, island.surface0.b, 0.5)
                                    Behavior on color { ColorAnimation { duration: 140 } }
                                    Text {
                                        anchors.centerIn: parent; text: "󰒊"
                                        font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(11)
                                        color: histReplyField.text.trim() !== "" ? island.base : island.subtext0
                                    }
                                    MouseArea {
                                        id: histSendMa; anchors.fill: parent; hoverEnabled: true
                                        onClicked: {
                                            island.notifReplyById(notifDelegate._notifId, histReplyField.text)
                                            histReplyField.text = ""; notifDelegate.replyOpen = false
                                        }
                                    }
                                }
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

                }
            }
        }
    }
}
