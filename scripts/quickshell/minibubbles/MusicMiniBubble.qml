import QtQuick

BaseBubble {
    id: root

    bubbleId: "music"
    onTapped: island.currentPage = "music"

    readonly property bool shouldShow: island.isMediaActive
        && island.currentPage !== "music"
        && !island.expanded

    property int bubbleH: island.s(36)
    height: bubbleH
    width: bubbleRow.implicitWidth + island.s(24)

    opacity: shouldShow ? 1.0 : 0.0
    visible: opacity > 0.001
    scale:   shouldShow ? 1.0 : 0.5
    transformOrigin: Item.Right

    Behavior on opacity { NumberAnimation { duration: 360; easing.type: Easing.OutCubic } }
    Behavior on scale   { NumberAnimation { duration: 420; easing.type: Easing.OutBack  } }

    Rectangle {
        anchors.fill: parent
        radius: parent.height / 2
        color: Qt.rgba(island.base.r, island.base.g, island.base.b, 0.94)
        border.width: 1.5
        border.color: Qt.rgba(island.mauve.r, island.mauve.g, island.mauve.b, island.musicPulse)
        Behavior on border.color { ColorAnimation { duration: 200 } }
    }

    Row {
        id: bubbleRow
        anchors.centerIn: parent
        spacing: island.s(6)

        Rectangle {
            width: root.bubbleH - island.s(12)
            height: root.bubbleH - island.s(12)
            radius: island.s(5)
            clip: true
            color: island.surface0
            anchors.verticalCenter: parent.verticalCenter

            Image {
                anchors.fill: parent
                source: island.musicData.artUrl || ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }

        Item {
            width: island.s(34)
            height: root.bubbleH - island.s(14)
            anchors.verticalCenter: parent.verticalCenter

            Repeater {
                model: 6
                Rectangle {
                    property color barColor: index === 0 ? island.blue
                        : index === 1 ? island.mauve
                        : index === 2 ? island.pink
                        : index === 3 ? island.peach
                        : index === 4 ? island.pink
                        : island.blue
                    property real barVal: index === 0 ? island.cavaBar0
                        : index === 1 ? island.cavaBar1
                        : index === 2 ? island.cavaBar2
                        : index === 3 ? island.cavaBar3
                        : index === 4 ? island.cavaBar4
                        : island.cavaBar5

                    x: index * island.s(6)
                    width: island.s(4)
                    radius: island.s(2)
                    anchors.bottom: parent.bottom
                    height: island.musicData.status !== "Playing"
                        ? parent.height * 0.12
                        : Math.max(parent.height * 0.12, parent.height * barVal)
                    Behavior on height { NumberAnimation { duration: 60; easing.type: Easing.Linear } }

                    opacity: island.musicData.status === "Playing" ? 1.0 : 0.3
                    Behavior on opacity { NumberAnimation { duration: 300 } }

                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0.0; color: Qt.lighter(barColor, 1.3) }
                        GradientStop { position: 0.5; color: barColor }
                        GradientStop { position: 1.0; color: Qt.darker(barColor, 1.15) }
                    }
                }
            }
        }
    }
}
