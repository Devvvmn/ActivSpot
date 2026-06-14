import QtQuick
import QtQuick.Effects
import "../themes"

Item {
    id: root
    property var island
    property string bubbleId: ""
    property real homeX: 0
    property real homeY: 0
    property bool snapSpring: false
    property bool initialized: false

    // Apple-like priority hierarchy. The island flips primary among all
    // currently-visible bubbles on a round-robin timer; tapping a non-primary
    // bubble pins it as primary instead of firing the bubble's own action.
    property bool primary: true

    // opacity < 0.5 means the bubble is currently hidden and about to appear → showMs
    // opacity ≥ 0.5 means it is currently visible and about to hide → hideMs
    Behavior on opacity {
        NumberAnimation {
            duration: island && island.expanded ? 0 : (root.opacity < 0.5 ? (island ? island.bubbleShowMs : 220) : (island ? island.bubbleHideMs : 360))
            easing.type: island ? island.bubbleEasingType : Easing.OutCubic
        }
    }

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
        id: tap
        acceptedButtons: Qt.LeftButton
        onTapped: {
            // Non-primary bubble: tap pins it as primary instead of firing
            // the bubble's native action. Apple Live Activities behavior.
            if (root.island && !root.primary && root.island.pinBubble) {
                root.island.pinBubble(root.bubbleId)
                return
            }
            root.tapped()
        }
    }

    // Right-click anywhere on a bubble: drop its focus (unpin + advance
    // primary past it). Works on both primary and satellite bubbles.
    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: {
            if (root.island && root.island.unfocusBubble)
                root.island.unfocusBubble(root.bubbleId)
        }
    }

    // Elevation shadow — primary bubble appears to lift off the others.
    // Halo "breathes" in: starts at bubble bounds and expands outward as the
    // bubble becomes primary; collapses back to bubble size before fading out.
    // Both ends animate together so the shadow morphs rather than pops.
    property real _haloPad: root.primary ? 16 : 0
    Behavior on _haloPad {
        NumberAnimation { duration: 480; easing.type: Easing.InOutCubic }
    }

    Rectangle {
        z: -1
        readonly property real _padW: root.island ? root.island.s(root._haloPad) : root._haloPad
        readonly property real _padH: root.island ? root.island.s(root._haloPad * 0.75) : root._haloPad * 0.75
        readonly property real _yOff: root.island ? root.island.s(5) : 5
        x: -_padW / 2
        y: -_padH / 2 + _yOff
        width:  parent.width  + _padW
        height: parent.height + _padH
        radius: height / 2
        color: Theme.shadowColor
        opacity: root.primary ? 0.25 : 0.0
        visible: opacity > 0.001
        layer.enabled: true
        layer.effect: MultiEffect { blurEnabled: true; blurMax: 32; blur: 1.0 }
        Behavior on opacity { NumberAnimation { duration: 480; easing.type: Easing.InOutCubic } }
    }

    // Primary scale applied via a separate transform so it composes with —
    // and isn't overwritten by — each subclass's own `scale:` binding (e.g.
    // shouldShow show/hide). Press feedback (0.92) lives here too.
    // Single animated source feeds both axes so they morph in lock-step.
    property real _primaryScale: tap.pressed ? 0.92 : (root.primary ? 1.0 : 0.82)
    Behavior on _primaryScale {
        NumberAnimation { duration: 480; easing.type: Easing.InOutCubic }
    }
    transform: Scale {
        id: primaryScale
        origin.x: root.width / 2
        origin.y: root.height / 2
        xScale: root._primaryScale
        yScale: root._primaryScale
    }
}
