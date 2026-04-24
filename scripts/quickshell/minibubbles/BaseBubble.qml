import QtQuick

Item {
    id: root
    property var island
    property string bubbleId: ""
    property real homeX: 0
    property real homeY: 0
    property bool pinned: false
    property real offsetX: 0  // pixels from homeX when pinned
    property real offsetY: 0  // pixels from homeY when pinned

    signal tapped()

    // Track home shifts while pinned — bubble orbits the island, not the screen
    onHomeXChanged: if (!dragger.active) x = homeX + (pinned ? offsetX : 0)
    onHomeYChanged: if (!dragger.active) y = homeY + (pinned ? offsetY : 0)

    Connections {
        target: island
        function onBubblePositionsChanged() {
            let saved = island.bubblePositions[root.bubbleId]
            if (saved && saved.ox !== undefined) {
                root.offsetX = saved.ox * Screen.width
                root.offsetY = saved.oy * Screen.height
                root.pinned  = true
                root.x = root.homeX + root.offsetX
                root.y = root.homeY + root.offsetY
            }
        }
    }

    Component.onCompleted: {
        let saved = island && island.bubblePositions ? island.bubblePositions[bubbleId] : null
        if (saved && saved.ox !== undefined) {
            offsetX = saved.ox * Screen.width
            offsetY = saved.oy * Screen.height
            pinned  = true
            x = homeX + offsetX
            y = homeY + offsetY
        } else {
            x = homeX
            y = homeY
        }
    }

    function resetPosition() {
        pinned  = false
        offsetX = 0
        offsetY = 0
        x = homeX
        y = homeY
        island.clearBubblePos(bubbleId)
    }

    DragHandler {
        id: dragger
        target: root
        xAxis.minimum: 0
        xAxis.maximum: Screen.width - root.width
        // Keep bubbles in the top strip so the input mask can cover them
        yAxis.minimum: 0
        yAxis.maximum: island ? island.s(100) : 80
        onActiveChanged: {
            if (!active) {
                root.offsetX = root.x - root.homeX
                root.offsetY = root.y - root.homeY
                root.pinned  = true
                island.setBubblePos(root.bubbleId,
                    root.offsetX / Screen.width,
                    root.offsetY / Screen.height)
            }
        }
    }

    TapHandler {
        onTapped: root.tapped()
        onDoubleTapped: root.resetPosition()
    }
}
