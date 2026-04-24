#!/usr/bin/env node
// Bubble positioning invariant tests — run with: node bubble_positioning.test.js
//
// Reimplements homeXFor + snapBubble in pure JS (identical logic to DynamicIsland.qml)
// and asserts three invariants after every operation:
//   1. No bubble overlaps the island body
//   2. No two visible same-side bubbles overlap each other
//   3. Every bubble ID appears in exactly one slot

// ---------------------------------------------------------------------------
// Environment mocks
// ---------------------------------------------------------------------------

const SCREENS = [
    { name: "1920×1080", width: 1920 },
    { name: "2560×1440", width: 2560 },
    { name: "3840×2160", width: 3840 },
    { name: "1366×768",  width: 1366 },
]

function makeScaler(screenW) {
    return v => Math.round(v * (screenW / 1920))
}

// Pages and their collapsed island widths (approximate values matching QML components)
const PAGE_WIDTHS = {
    clock:     130,   // scaled later
    music:     340,
    recording: 175,
    notifs:    230,
    discord:   185,
}

// ---------------------------------------------------------------------------
// Pure reimplementation of QML functions (must stay in sync with DynamicIsland.qml)
// ---------------------------------------------------------------------------

function homeXFor(id, leftSlots, rightSlots, collapsedW, bubbles, screenW, s) {
    const half = collapsedW / 2
    const GAP  = s(14)

    const ri = rightSlots.indexOf(id)
    if (ri >= 0) {
        let x = Math.floor(screenW / 2) + half + GAP
        for (let i = 0; i < ri; i++) {
            const b = bubbles[rightSlots[i]]
            if (b && b.shouldShow) x += b.width + s(8)
        }
        return x
    }

    const li = leftSlots.indexOf(id)
    if (li >= 0) {
        const bub = bubbles[id]
        let x = Math.floor(screenW / 2) - half - GAP - (bub ? bub.width : 0)
        for (let i = 0; i < li; i++) {
            const b = bubbles[leftSlots[i]]
            if (b && b.shouldShow) x -= b.width + s(8)
        }
        return x
    }

    return 0
}

function snapBubble(id, dropCenterX, leftSlots, rightSlots, collapsedW, bubbles, screenW, s) {
    let newLeft  = leftSlots.filter(v => v !== id)
    let newRight = rightSlots.filter(v => v !== id)
    const iCenter = screenW / 2
    const halfW   = collapsedW / 2
    const GAP     = s(14)

    if (dropCenterX <= iCenter) {
        let insertIdx = newLeft.length
        let x = iCenter - halfW - GAP
        for (let i = 0; i < newLeft.length; i++) {
            const b  = bubbles[newLeft[i]]
            const bw = (b && b.shouldShow) ? b.width : 0
            if (bw > 0) {
                x -= bw
                if (dropCenterX >= x) { insertIdx = i; break }
                x -= s(8)
            }
        }
        newLeft.splice(insertIdx, 0, id)
    } else {
        let insertIdx = newRight.length
        let x = iCenter + halfW + GAP
        for (let i = 0; i < newRight.length; i++) {
            const b  = bubbles[newRight[i]]
            const bw = (b && b.shouldShow) ? b.width : 0
            if (bw > 0) {
                if (dropCenterX <= x + bw) { insertIdx = i; break }
                x += bw + s(8)
            }
        }
        newRight.splice(insertIdx, 0, id)
    }

    return { leftSlots: newLeft, rightSlots: newRight }
}

// ---------------------------------------------------------------------------
// Invariant checkers
// ---------------------------------------------------------------------------

function checkNoIslandOverlap(leftSlots, rightSlots, collapsedW, bubbles, screenW, s) {
    const islandLeft  = Math.floor(screenW / 2 - collapsedW / 2)
    const islandRight = Math.floor(screenW / 2 + collapsedW / 2)
    const all = [...leftSlots, ...rightSlots]

    for (const id of all) {
        const bub = bubbles[id]
        if (!bub || !bub.shouldShow) continue
        const hx = homeXFor(id, leftSlots, rightSlots, collapsedW, bubbles, screenW, s)
        const bLeft  = hx
        const bRight = hx + bub.width

        if (bRight > islandLeft && bLeft < islandRight) {
            return {
                ok: false,
                msg: `'${id}' overlaps island  bubble[${bLeft}..${bRight}]  island[${islandLeft}..${islandRight}]`
            }
        }
    }
    return { ok: true }
}

function checkNoBubbleOverlap(leftSlots, rightSlots, collapsedW, bubbles, screenW, s) {
    for (const [side, ids] of [['left', leftSlots], ['right', rightSlots]]) {
        const visible = ids.filter(id => bubbles[id]?.shouldShow)
        for (let i = 0; i < visible.length; i++) {
            for (let j = i + 1; j < visible.length; j++) {
                const a = visible[i], b = visible[j]
                const xA = homeXFor(a, leftSlots, rightSlots, collapsedW, bubbles, screenW, s)
                const xB = homeXFor(b, leftSlots, rightSlots, collapsedW, bubbles, screenW, s)
                const wA = bubbles[a].width, wB = bubbles[b].width
                if (xA + wA > xB && xA < xB + wB) {
                    return {
                        ok: false,
                        msg: `'${a}' and '${b}' overlap on ${side}  [${xA}..${xA+wA}] vs [${xB}..${xB+wB}]`
                    }
                }
            }
        }
    }
    return { ok: true }
}

function checkUniqueSlots(leftSlots, rightSlots) {
    const seen = new Set()
    for (const id of [...leftSlots, ...rightSlots]) {
        if (seen.has(id)) return { ok: false, msg: `'${id}' appears in multiple slots` }
        seen.add(id)
    }
    return { ok: true }
}

function checkSnapSide(id, dropCenterX, leftSlots, rightSlots, screenW) {
    const onLeft  = leftSlots.includes(id)
    const onRight = rightSlots.includes(id)
    const shouldBeLeft = dropCenterX <= screenW / 2
    if (shouldBeLeft && !onLeft)  return { ok: false, msg: `'${id}' dropped left of center but ended in rightSlots` }
    if (!shouldBeLeft && !onRight) return { ok: false, msg: `'${id}' dropped right of center but ended in leftSlots` }
    return { ok: true }
}

// ---------------------------------------------------------------------------
// Test runner
// ---------------------------------------------------------------------------

let passed = 0, failed = 0, skipped = 0
const failures = []

function check(label, result) {
    if (result.ok) {
        passed++
    } else {
        failed++
        failures.push(`  FAIL  ${label}\n        ${result.msg}`)
    }
}

function runInvariants(label, leftSlots, rightSlots, collapsedW, bubbles, screenW, s) {
    check(`${label} | no island overlap`, checkNoIslandOverlap(leftSlots, rightSlots, collapsedW, bubbles, screenW, s))
    check(`${label} | no bubble overlap`, checkNoBubbleOverlap(leftSlots, rightSlots, collapsedW, bubbles, screenW, s))
    check(`${label} | unique slots`,      checkUniqueSlots(leftSlots, rightSlots))
}

// ---------------------------------------------------------------------------
// Test scenarios
// ---------------------------------------------------------------------------

const ALL_IDS = ['vpn', 'music', 'discord', 'rec', 'notif', 'clock']

const DEFAULT_SLOTS = {
    leftSlots:  ['vpn', 'music', 'discord'],
    rightSlots: ['rec', 'notif', 'clock'],
}

// Bubble widths (pre-scale, will be scaled per screen)
const BASE_WIDTHS = { vpn: 90, music: 120, discord: 100, rec: 100, notif: 36, clock: 72 }

// Visibility presets
const PRESETS = {
    none:    { vpn: false, music: false, discord: false, rec: false, notif: false, clock: false },
    default: { vpn: true,  music: true,  discord: false, rec: false, notif: false, clock: true  },
    all:     { vpn: true,  music: true,  discord: true,  rec: true,  notif: true,  clock: true  },
    music:   { vpn: false, music: true,  discord: false, rec: false, notif: false, clock: true  },
    rec:     { vpn: false, music: false, discord: false, rec: true,  notif: true,  clock: true  },
}

for (const { name: screenName, width: screenW } of SCREENS) {
    const s = makeScaler(screenW)

    const makeBubbles = (vis) =>
        Object.fromEntries(ALL_IDS.map(id => [id, { width: s(BASE_WIDTHS[id]), shouldShow: vis[id] }]))

    // 1 — Default state, all pages, all visibility presets
    for (const [pageName, baseW] of Object.entries(PAGE_WIDTHS)) {
        const collapsedW = s(baseW)
        for (const [presetName, vis] of Object.entries(PRESETS)) {
            const bubbles = makeBubbles(vis)
            runInvariants(
                `${screenName} | ${pageName} | preset:${presetName}`,
                [...DEFAULT_SLOTS.leftSlots], [...DEFAULT_SLOTS.rightSlots],
                collapsedW, bubbles, screenW, s
            )
        }
    }

    // 2 — snap: every bubble × 9 drop positions × all pages × two visibility presets
    const dropFractions = [0.02, 0.15, 0.35, 0.49, 0.50, 0.51, 0.65, 0.85, 0.98]

    for (const [pageName, baseW] of Object.entries(PAGE_WIDTHS)) {
        const collapsedW = s(baseW)
        for (const vis of [PRESETS.all, PRESETS.default]) {
            const bubbles = makeBubbles(vis)
            for (const id of ALL_IDS) {
                for (const frac of dropFractions) {
                    const dropX = Math.round(screenW * frac)
                    const { leftSlots, rightSlots } = snapBubble(
                        id, dropX,
                        [...DEFAULT_SLOTS.leftSlots], [...DEFAULT_SLOTS.rightSlots],
                        collapsedW, bubbles, screenW, s
                    )
                    const label = `${screenName} | snap '${id}' to ${Math.round(frac*100)}% | ${pageName}`
                    runInvariants(label, leftSlots, rightSlots, collapsedW, bubbles, screenW, s)
                    check(`${label} | correct side`, checkSnapSide(id, dropX, leftSlots, rightSlots, screenW))
                }
            }
        }
    }

    // 3 — Chained snaps: move the same bubble multiple times in a row
    for (const id of ['clock', 'music']) {
        const collapsedW = s(PAGE_WIDTHS.music)
        const bubbles = makeBubbles(PRESETS.all)
        let { leftSlots, rightSlots } = DEFAULT_SLOTS
        leftSlots  = [...leftSlots]
        rightSlots = [...rightSlots]

        for (const frac of [0.1, 0.9, 0.3, 0.7, 0.5]) {
            const dropX = Math.round(screenW * frac);
            ({ leftSlots, rightSlots } = snapBubble(id, dropX, leftSlots, rightSlots, collapsedW, bubbles, screenW, s))
            runInvariants(`${screenName} | chain-snap '${id}' to ${Math.round(frac*100)}%`, leftSlots, rightSlots, collapsedW, bubbles, screenW, s)
        }
    }

    // 4 — Vol-stretch simulation: island wider than its page collapsedW
    for (const stretch of [0.1, 0.2, 0.3]) {
        const collapsedW = s(Math.round(PAGE_WIDTHS.music * (1 + stretch * 0.26)))
        const bubbles = makeBubbles(PRESETS.all)
        runInvariants(
            `${screenName} | vol-stretch ${Math.round(stretch*100)}% | all visible`,
            [...DEFAULT_SLOTS.leftSlots], [...DEFAULT_SLOTS.rightSlots],
            collapsedW, bubbles, screenW, s
        )
    }
}

// ---------------------------------------------------------------------------
// Summary
// ---------------------------------------------------------------------------

const total = passed + failed
console.log(`\nBubble positioning invariants`)
console.log(`${'─'.repeat(42)}`)
if (failures.length) {
    failures.forEach(f => console.error(f))
    console.log()
}
console.log(`${total} checks — ${passed} passed, ${failed} failed`)
if (failed > 0) process.exit(1)
