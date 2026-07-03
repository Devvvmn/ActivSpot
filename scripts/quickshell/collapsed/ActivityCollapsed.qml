import QtQuick

Row {
    property var island
    property int preferredWidth: island.s(230)
    spacing: island.s(10)
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined

    readonly property bool isDone: island.laTopStatus !== "live"
    readonly property bool isFail: island.laTopStatus === "fail"
    readonly property color accent: isDone ? (isFail ? island.red : island.green) : island.teal

    Text {
        text: isDone ? (isFail ? "󰅖" : "󰄬") : island.laTopIcon
        font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(16)
        color: accent
        anchors.verticalCenter: parent.verticalCenter
        Behavior on color { ColorAnimation { duration: 200 } }
    }

    Column {
        spacing: island.s(2); anchors.verticalCenter: parent.verticalCenter

        Text {
            text: {
                let t = island.laTopTitle
                if (t.length > 22) t = t.substring(0, 21) + "…"
                return t
            }
            font.family: "JetBrains Mono"; font.pixelSize: island.s(13); font.weight: Font.Black
            color: island.text
        }

        // Thin progress bar for numeric progress; status/subtitle otherwise
        Item {
            width: island.s(120); height: island.s(10)

            Rectangle {
                visible: island.laTopProgress >= 0
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width; height: island.s(3); radius: height / 2
                color: Qt.rgba(island.text.r, island.text.g, island.text.b, 0.12)
                Rectangle {
                    width: parent.width * Math.max(0.02, Math.min(1, island.laTopProgress))
                    height: parent.height; radius: parent.radius
                    color: accent
                    Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                }
            }
            Text {
                visible: island.laTopProgress < 0
                anchors.verticalCenter: parent.verticalCenter
                text: {
                    let t = island.laTopSub !== "" ? island.laTopSub
                        : (isDone ? (isFail ? "failed" : "done") : "running")
                    if (t.length > 26) t = t.substring(0, 25) + "…"
                    return t
                }
                font.family: "JetBrains Mono"; font.pixelSize: island.s(9)
                color: island.subtext0
            }
        }
    }

    // Percent / count tail
    Column {
        spacing: -1; anchors.verticalCenter: parent.verticalCenter

        Text {
            visible: island.laTopProgress >= 0 && !isDone
            text: Math.round(island.laTopProgress * 100) + "%"
            font.family: "JetBrains Mono"; font.pixelSize: island.s(14); font.weight: Font.Black
            color: accent
        }
        Text {
            visible: island.laCount > 1
            text: "+" + (island.laCount - 1)
            font.family: "JetBrains Mono"; font.pixelSize: island.s(9)
            color: island.subtext0
        }
    }
}
