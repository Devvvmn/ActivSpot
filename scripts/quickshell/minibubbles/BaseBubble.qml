import QtQuick

Item {
    id: root
    property var island
    property string bubbleId: ""
    property real homeX: 0
    property real homeY: 0
    property bool snapSpring: false
    property bool initialized: false

    signal tapped()

    Component.onCompleted: {
        x = homeX
        y = homeY
        // Enable animations only after initial placement to avoid fly-in on startup
        Qt.callLater(function() { root.initialized = true })
    }

    Timer { id: snapTimer; interval: 700; onTriggered: root.snapSpring = false }

    // Assign x/y when home shifts — triggers Behavior below (fast tracking)
    // Skipped while dragging (DragHandler owns x) or during spring snap
    onHomeXChanged: if (initialized && !dragger.active && !snapSpring) x = homeX
    onHomeYChanged: if (initialized && !dragger.active && !snapSpring) y = homeY

    // Fast tracking for slot reposition and island width changes.
    // OutExpo (160 ms) keeps bubbles ahead of the island edge — no overlap.
    Behavior on x {
        enabled: root.initialized && !dragger.active && !root.snapSpring
        NumberAnimation { duration: 160; easing.type: Easing.OutExpo }
    }
    Behavior on y {
        enabled: root.initialized && !dragger.active && !root.snapSpring
        NumberAnimation { duration: 160; easing.type: Easing.OutExpo }
    }

    // Spring snap used only right after drag ends — gives the "click into slot" bounce
    SpringAnimation {
        target: root; property: "x"
        to: root.homeX
        spring: 4.5; damping: 0.6
        running: root.snapSpring
    }
    SpringAnimation {
        target: root; property: "y"
        to: root.homeY
        spring: 4.5; damping: 0.6
        running: root.snapSpring
    }

    DragHandler {
        id: dragger
        target: root
        xAxis.minimum: 0
        xAxis.maximum: Screen.width - root.width
        yAxis.minimum: 0
        yAxis.maximum: island ? island.s(100) : 80
        onActiveChanged: {
            if (!active && island) {
                let dropCenterX = root.x + root.width / 2

                // Assign slot first so homeX updates before spring starts
                island.snapBubble(bubbleId, dropCenterX)

                // If the bubble was dropped inside the island body, eject it to the
                // near edge so the spring never animates through the island.
                let halfW    = island.islandCollapsedW / 2
                let iLeft    = Screen.width / 2 - halfW
                let iRight   = Screen.width / 2 + halfW
                let gap      = island.s(10)
                let bRight   = root.x + root.width
                let bLeft    = root.x
                if (bRight > iLeft && bLeft < iRight) {
                    if (dropCenterX <= Screen.width / 2)
                        root.x = iLeft - root.width - gap
                    else
                        root.x = iRight + gap
                }

                root.snapSpring = true
                snapTimer.restart()
            }
        }
    }

    TapHandler {
        onTapped: root.tapped()
    }
}
