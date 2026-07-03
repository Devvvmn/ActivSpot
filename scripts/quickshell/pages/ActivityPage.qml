import QtQuick
import QtQuick.Layouts
import "../themes"

Item {
    id: root
    property var island

    // Ticking "now" for elapsed labels — only while the page is visible
    property double nowTs: Date.now()
    Timer {
        interval: 1000; repeat: true
        running: root.visible && island.expanded && island.currentPage === "activity"
        onTriggered: root.nowTs = Date.now()
    }

    function accentFor(status) {
        if (status === "fail") return island.red
        if (status === "ok")   return island.green
        return island.teal
    }

    Item {
        anchors.fill: parent
        anchors.margins: island.s(20)
        anchors.bottomMargin: island.s(64)

        ColumnLayout {
            anchors.fill: parent
            spacing: island.s(10)

            // ── Header ───────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: island.s(8)

                Text {
                    text: "󰐍"
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: island.s(15)
                    color: island.teal
                }
                Text {
                    text: "Activities"
                    font.family: Theme.fontUI
                    font.pixelSize: island.s(13)
                    font.weight: Font.DemiBold
                    color: island.text
                }
                Text {
                    text: island.laCount
                    font.family: "JetBrains Mono"
                    font.pixelSize: island.s(11)
                    font.weight: Font.Bold
                    color: island.subtext0
                }
                Item { Layout.fillWidth: true }
            }

            // ── Activity list ────────────────────────────────────────────
            ListView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: island.activitiesModel
                spacing: island.s(6)
                clip: true

                delegate: Rectangle {
                    id: card
                    width: list.width
                    height: cardCol.implicitHeight + island.s(16)
                    radius: island.s(12)

                    readonly property color acc: root.accentFor(model.status)
                    readonly property bool  live: model.status === "live"
                    // Captured — inside the actions Repeater `model` is the
                    // actions array context, not this delegate's row
                    readonly property string cardAid: model.aid

                    color: cardMouse.containsMouse
                        ? Qt.rgba(island.surface1.r, island.surface1.g, island.surface1.b, 0.85)
                        : Qt.rgba(island.surface0.r, island.surface0.g, island.surface0.b, 0.70)
                    border.width: 1
                    border.color: Qt.rgba(acc.r, acc.g, acc.b, live ? 0.22 : 0.45)
                    Behavior on color        { ColorAnimation { duration: 120 } }
                    Behavior on border.color { ColorAnimation { duration: 200 } }

                    MouseArea {
                        id: cardMouse
                        anchors.fill: parent
                        hoverEnabled: true
                    }

                    ColumnLayout {
                        id: cardCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: island.s(12)
                        anchors.rightMargin: island.s(12)
                        spacing: island.s(5)

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: island.s(8)

                            Text {
                                text: card.live ? model.icon : (model.status === "fail" ? "󰅖" : "󰄬")
                                font.family: "Iosevka Nerd Font"
                                font.pixelSize: island.s(15)
                                color: card.acc
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                Text {
                                    Layout.fillWidth: true
                                    text: model.title
                                    elide: Text.ElideRight
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: island.s(12)
                                    font.weight: Font.Bold
                                    color: island.text
                                }
                                Text {
                                    Layout.fillWidth: true
                                    visible: text !== ""
                                    text: model.subtitle
                                    elide: Text.ElideRight
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: island.s(9)
                                    color: island.subtext0
                                }
                            }

                            // Elapsed since start (live) / percent
                            Text {
                                text: {
                                    if (model.progress >= 0 && card.live)
                                        return Math.round(model.progress * 100) + "%"
                                    const el = Math.max(0, Math.floor((root.nowTs - model.startTs) / 1000))
                                    return island.fmtChrono(el)
                                }
                                font.family: "JetBrains Mono"
                                font.pixelSize: island.s(11)
                                font.weight: Font.Black
                                color: card.live ? card.acc : island.subtext0
                            }

                            // Dismiss
                            Rectangle {
                                width: island.s(20); height: island.s(20)
                                radius: width / 2
                                color: xMouse.containsMouse
                                    ? Qt.rgba(island.red.r, island.red.g, island.red.b, 0.18)
                                    : Qt.rgba(island.text.r, island.text.g, island.text.b, 0.06)
                                Behavior on color { ColorAnimation { duration: 120 } }
                                Text {
                                    anchors.centerIn: parent
                                    text: "󰅖"
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: island.s(9)
                                    color: xMouse.containsMouse ? island.red : island.subtext0
                                }
                                MouseArea {
                                    id: xMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: island.activityDismiss(model.aid)
                                }
                            }
                        }

                        // Progress bar — numeric progress only
                        Rectangle {
                            visible: model.progress >= 0
                            Layout.fillWidth: true
                            height: island.s(4); radius: height / 2
                            color: Qt.rgba(island.text.r, island.text.g, island.text.b, 0.10)
                            Rectangle {
                                width: parent.width * Math.max(0.02, Math.min(1, model.progress))
                                height: parent.height; radius: parent.radius
                                color: card.acc
                                Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }
                        }

                        // Indeterminate sweep — live with spinner progress
                        Rectangle {
                            visible: model.progress === -1 && card.live
                            Layout.fillWidth: true
                            height: island.s(4); radius: height / 2
                            color: Qt.rgba(island.text.r, island.text.g, island.text.b, 0.10)
                            clip: true
                            Rectangle {
                                id: sweep
                                width: parent.width * 0.30
                                height: parent.height; radius: parent.radius
                                color: Qt.rgba(card.acc.r, card.acc.g, card.acc.b, 0.75)
                                NumberAnimation on x {
                                    running: sweep.visible && !Theme.reduceMotion
                                    loops: Animation.Infinite
                                    from: -sweep.width; to: sweep.parent ? sweep.parent.width : 200
                                    duration: 1300
                                    easing.type: Easing.InOutQuad
                                }
                            }
                        }

                        // Action chips (producer-declared)
                        RowLayout {
                            visible: actionsRepeater.count > 0 && card.live
                            Layout.fillWidth: true
                            spacing: island.s(6)

                            Repeater {
                                id: actionsRepeater
                                model: {
                                    try { return JSON.parse(actionsJson) } catch(e) { return [] }
                                }
                                Rectangle {
                                    required property var modelData
                                    implicitWidth: chipLabel.implicitWidth + island.s(16)
                                    implicitHeight: island.s(22)
                                    radius: island.s(7)
                                    color: chipMouse.containsMouse
                                        ? Qt.rgba(island.surface2.r, island.surface2.g, island.surface2.b, 0.9)
                                        : Qt.rgba(island.surface1.r, island.surface1.g, island.surface1.b, 0.8)
                                    border.width: 1
                                    border.color: Qt.rgba(island.text.r, island.text.g, island.text.b, 0.10)
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                    Text {
                                        id: chipLabel
                                        anchors.centerIn: parent
                                        text: parent.modelData.label || parent.modelData.id
                                        font.family: Theme.fontUI
                                        font.pixelSize: island.s(10)
                                        font.weight: Font.Medium
                                        color: island.text
                                    }
                                    MouseArea {
                                        id: chipMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: island.activityAction(card.cardAid, parent.modelData.id)
                                    }
                                }
                            }
                            Item { Layout.fillWidth: true }
                        }
                    }
                }
            }
        }
    }
}
