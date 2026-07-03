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

    // ── Liquid spawn squash ──
    // Fires once each time the bubble transitions hidden→visible: a fast splat
    // to 1.0 then a spring back to 0, driving the droplet deform below.
    property real _spawnSquash: 0.0
    property bool _wasShown:    false
    SequentialAnimation {
        id: spawnPulse
        NumberAnimation {
            target: root; property: "_spawnSquash"
            to: 1.0; duration: 90; easing.type: Easing.OutCubic
        }
        SpringAnimation {
            target: root; property: "_spawnSquash"
            to: 0.0; spring: 3.0; damping: 0.16; mass: 1.0; epsilon: 0.005
        }
    }
    // Trigger on the opacity crossing — guarded so it never fires at startup
    // (initialized latches later) or while collapsed-hidden under expansion.
    onOpacityChanged: {
        if (!initialized || (island && island.expanded) || Theme.reduceMotion) return
        if (opacity > 0.5 && !_wasShown) { _wasShown = true; spawnPulse.restart() }
        else if (opacity < 0.5)          { _wasShown = false }
    }

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
        // Latch current visibility so an already-visible bubble doesn't fire a
        // phantom spawn splat on the first opacity wiggle after startup.
        _wasShown = opacity > 0.5
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

    // Spring snap used only right after drag ends — juicier "click into slot" bounce
    SpringAnimation {
        target: root; property: "x"
        to: root.homeX
        spring: 4.8; damping: 0.46
        running: root.snapSpring
    }
    SpringAnimation {
        target: root; property: "y"
        to: root.homeY
        spring: 4.8; damping: 0.46
        running: root.snapSpring
    }

    // ── Liquid drag smear ──
    // While dragging, the bubble stretches along its travel direction and
    // pinches across it, proportional to pointer speed — a droplet in flight.
    // Velocity (px/s) is mapped to −1..1 and smoothed so it eases back to
    // round the instant the drag stops (binding falls to 0 → Behavior relaxes).
    property real _smearX: (dragger.active && !Theme.reduceMotion)
        ? Math.max(-1, Math.min(1, dragger.centroid.velocity.x / 1200)) : 0
    property real _smearY: (dragger.active && !Theme.reduceMotion)
        ? Math.max(-1, Math.min(1, dragger.centroid.velocity.y / 1200)) : 0
    Behavior on _smearX { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
    Behavior on _smearY { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }

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

    // Analytic RectangularShadow instead of Rectangle+layer+MultiEffect blur —
    // the layered version re-rasterized during every _haloPad/opacity animation
    // (each 30 s primary rotation), one blur layer per bubble.
    RectangularShadow {
        z: -1
        readonly property real _padW: root.island ? root.island.s(root._haloPad) : root._haloPad
        readonly property real _padH: root.island ? root.island.s(root._haloPad * 0.75) : root._haloPad * 0.75
        readonly property real _yOff: root.island ? root.island.s(5) : 5
        x: -_padW / 2
        y: -_padH / 2 + _yOff
        width:  parent.width  + _padW
        height: parent.height + _padH
        radius: height / 2
        blur: 32
        spread: 0
        color: Theme.shadowColor
        opacity: root.primary ? 0.25 : 0.0
        visible: opacity > 0.001
        Behavior on opacity { NumberAnimation { duration: 480; easing.type: Easing.InOutCubic } }
    }

    // Primary scale applied via a separate transform so it composes with —
    // and isn't overwritten by — each subclass's own `scale:` binding (e.g.
    // shouldShow show/hide). Press feedback (0.92) lives here too.
    // Single animated source feeds both axes so they morph in lock-step.
    property real _primaryScale: tap.pressed ? 0.92 : (root.primary ? 1.0 : 0.82)
    // Spring instead of a linear tween — primary bubble *lifts* with a soft
    // overshoot, press releases with a bounce. Reads as elastic, not mechanical.
    Behavior on _primaryScale {
        SpringAnimation { spring: 4.6; damping: 0.42; mass: 1.0; epsilon: 0.005 }
    }

    // Three composed deforms: primary/press scale + spawn squash + drag smear.
    transform: [
        Scale {
            id: primaryScale
            origin.x: root.width / 2
            origin.y: root.height / 2
            xScale: root._primaryScale
            yScale: root._primaryScale
        },
        // Droplet "splat": as the bubble appears it stretches wide + squashes
        // short, then springs back to round. Center-anchored so it stays put.
        Scale {
            origin.x: root.width / 2
            origin.y: root.height / 2
            xScale: 1.0 + root._spawnSquash * 0.22
            yScale: 1.0 - root._spawnSquash * 0.17
        },
        // Drag smear: elongate along motion, pinch across it.
        Scale {
            origin.x: root.width / 2
            origin.y: root.height / 2
            xScale: 1.0 + Math.abs(root._smearX) * 0.26 - Math.abs(root._smearY) * 0.12
            yScale: 1.0 + Math.abs(root._smearY) * 0.26 - Math.abs(root._smearX) * 0.12
        }
    ]
}
