import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services.UI
import qs.Widgets

// Row delegate for the clipboard history ListView in Panel.qml.
//
// Visual contract: matches the NotificationHistoryPanel item treatment —
// a rounded mSurfaceVariant card with internal margins, primary-color
// focus border, no hover fill. See the reference delegate in
// $XDG_CONFIG_HOME/quickshell/noctalia-shell/Modules/Panels/NotificationHistory/
// NotificationHistoryPanel.qml (Rectangle with radius: Style.radiusM and
// color: Color.mSurfaceVariant). This keeps clipper rows looking like
// native notification rows so the panel reads as part of the shell.
//
// Responsibilities:
//   - Render a single clipboard entry's text preview, truncated so long lines
//     do not blow up the row height.
//   - Left-click: copy the entry (by cliphist id), show a toast, emit copied()
//     so Panel.qml can close the panel (Panel owns the close timer).
//   - Hover: reveal an icon-only delete button that removes the entry and
//     fires a separate toast.
//
// Contracts followed:
//   - docs/specs/plugin-qml-idioms.md (component composition — internal
//     components receive pluginApi from the parent; null-guard everything;
//     ToastService usage for transient confirmations; pointSize for NText).
//   - Main.qml exposes copy(id) / remove(id) via pluginApi.mainInstance.
Item {
    id: card

    // --- Properties passed from the ListView delegate -----------------------

    // Plugin API handed down from Panel.qml — ClipboardItem never reads the
    // shell directly; it goes through pluginApi. Null-guard each access.
    property var pluginApi: null
    // Cliphist entry id (string, e.g. "42") — the stable key used by
    // copy(id) and remove(id) in Main.qml. For pinned rows this is a
    // synthetic "pinned:N" string carrying no cliphist meaning; see the
    // `pinned` / `pinnedIndex` properties below for the real identity.
    property string entryId: ""
    // Raw preview text as returned by `cliphist list` (tab-stripped).
    property string previewText: ""
    // Entry kind, one of "text" | "image" | "file". Set by Panel.qml from
    // the parsed cliphist output in Main.qml (see
    // docs/specs/image-previews.md). Drives the branch in RowLayout between
    // the Image thumbnail and NText preview.
    property string itemType: "text"

    // True when this row represents a pinned entry (from Main.qml's
    // pinnedItems). Pinned rows render a pin badge, route copy() through
    // copyPinned(index) instead of copy(id), and route delete through
    // unpin(index) instead of remove(id). See docs/specs/pinned-items.md.
    property bool pinned: false

    // Positional index into Main.qml's pinnedItems for this pinned row.
    // -1 for history rows. Used by copy / delete to avoid a second
    // preview+type lookup.
    property int pinnedIndex: -1

    // Compact mode is used by the image grid (Panel.qml Images tab). When
    // true, the full row layout is hidden and an image-fill cell with a
    // hover-reveal delete overlay is shown instead. The Panel sets an
    // explicit height on the delegate so implicitHeight is not consulted.
    property bool compact: false

    // Keyboard-selected state. Driven by Panel.qml's selectedIndex via
    // `selected: index === root.selectedIndex` in the delegate binding.
    // Independent of hover and press, so a selected row stays visibly
    // highlighted as the user moves the mouse over other rows — the
    // highlight is a keyboard affordance, not a hover echo.
    //
    // See docs/specs/panel-keyboard-nav.md — Delegate highlight contract.
    property bool selected: false

    // True only when this is an image entry AND the user has image previews
    // enabled AND this is not a pinned row. When false, image entries degrade
    // gracefully to the text path with their raw "[[ binary data ... ]]"
    // preview — same as the pre-image behavior, so the setting is a clean
    // kill-switch.
    //
    // Pinned image entries force the text fallback: pinned items carry no
    // cliphist id, so `cliphist decode` has nothing to fetch. Rendering the
    // raw binary marker as text is the contract from
    // docs/specs/pinned-items.md §Acceptance Criteria #9.
    readonly property bool renderAsImage: card.itemType === "image"
        && !card.pinned
        && (card.pluginApi?.pluginSettings?.showImagePreviews ?? true)

    // True when this is a file entry. Unlike renderAsImage there is no
    // setting-level kill-switch — file rendering has no decode cost
    // beyond one stat per entry per session, and the plain-text
    // fallback (showing the raw file:// URI) is worse UX.
    // Compact mode is never used for files (the Files tab renders as a
    // list, not a grid — see docs/specs/file-items.md).
    readonly property bool renderAsFile: card.itemType === "file" && !card.compact

    // Human-readable "how long ago" label for this entry, derived from
    // the shared copiedAt map in Main.qml. Reads timeRevision so the
    // binding re-evaluates on every ticker increment (one 60s Timer
    // in Main.qml serves the whole plugin — no per-row timers, see
    // docs/specs/relative-time-display.md and
    // docs/specs/plugin-qml-idioms.md memory management).
    //
    // Reads itemsRevision too so the label updates when Main.qml stamps
    // a timestamp for a newly-observed id (copiedAt is replaced by
    // reference in the same block that bumps itemsRevision).
    //
    // Returns "" when the map has no record for this id OR when the
    // stored value is unparseable — the Text element hides via its
    // visible binding so the row doesn't reserve whitespace.
    readonly property string relativeTimeText: {
        const _rev = card.pluginApi?.mainInstance?.timeRevision ?? 0;
        const _irev = card.pluginApi?.mainInstance?.itemsRevision ?? 0;
        const main = card.pluginApi?.mainInstance;
        if (!main || !card.entryId)
            return "";
        // Pinned rows have no cliphist id and therefore no copiedAt
        // timestamp. The pin badge replaces the time label visually, so
        // returning "" here lets the label's visibility binding hide it
        // cleanly without a special case elsewhere.
        if (card.pinned)
            return "";
        const iso = main.copiedAt?.[card.entryId];
        if (!iso)
            return "";
        return main.formatRelativeTime(iso);
    }

    // Live metadata snapshot for the current entryId. Binding reads
    // fileMetaRevision so the delegate re-evaluates when
    // addFileMeta(id, ...) fires the counter (Object.assign replaces the
    // reference, but reading the revision counter is the consistent
    // idiom across the plugin — see imageCache handling above).
    //
    // While the stat is in flight the binding returns a synthesised
    // placeholder derived from the raw preview so the row still shows a
    // basename and parent path (and no size) until metadata resolves.
    readonly property var fileMeta: {
        const _rev = card.pluginApi?.mainInstance?.fileMetaRevision ?? 0;
        const cached = card.pluginApi?.mainInstance?.fileMetaCache?.[card.entryId];
        if (cached)
            return cached;
        // Placeholder: derive filename + parentDir directly from the
        // preview URI. Matches the shape of the cached record so the
        // render path doesn't branch.
        const main = card.pluginApi?.mainInstance;
        if (!main || !card.previewText)
            return { filename: "", parentDir: "", sizeBytes: -1, sizeHuman: "" };
        const path = main.fileUriToPath(card.previewText);
        if (!path)
            return { filename: card.previewText, parentDir: "", sizeBytes: -1, sizeHuman: "" };
        const parts = main.splitPath(path);
        return {
            filename: parts.filename,
            parentDir: parts.parentDir,
            sizeBytes: -1,
            sizeHuman: ""
        };
    }

    // Trigger lazy fetches when this delegate becomes an image or file
    // row. Both getImage() and getFileMeta() are cheap on cache hit,
    // validate their own ids, and no-op when the relevant setting is
    // off, so the handler can fire freely without extra guarding.
    //
    // Three firing paths cover the delegate lifecycle:
    //   - onEntryIdChanged — fires when the ListView rebinds a reused
    //     delegate onto a new id (also on initial "" → "17" transition
    //     after pluginApi is bound).
    //   - onRenderAsImageChanged — covers late-arriving pluginApi and
    //     showImagePreviews toggles: renderAsImage flips false→true and
    //     the decode kicks off on the currently bound entryId.
    //   - onRenderAsFileChanged — same thing for file metadata
    //     resolution after pluginApi arrives.
    function _requestDecode() {
        // Pinned rows skip both fetches entirely: they carry no cliphist
        // id (entryId is a synthetic "pinned:N" string), so getImage and
        // getFileMeta's numeric-id guard would reject them. The
        // delegate's `fileMeta` fallback (derived from preview URI) is
        // sufficient for pinned file rendering, and pinned images render
        // as text per the renderAsImage guard above.
        if (card.pinned)
            return;
        if (card.renderAsImage && card.entryId) {
            card.pluginApi?.mainInstance?.getImage(card.entryId);
        }
        if (card.renderAsFile && card.entryId) {
            card.pluginApi?.mainInstance?.getFileMeta(card.entryId);
        }
    }
    onEntryIdChanged: _requestDecode()
    onRenderAsImageChanged: _requestDecode()
    onRenderAsFileChanged: _requestDecode()

    // Signal bubbled up when this row triggers a copy. Panel.qml listens to
    // this and drives its own closePanelTimer so recycled delegates
    // (ListView reuseItems: true) cannot carry stale state into the deferred
    // close — see issue #23.
    signal copied()
    signal deleted()

    // --- Sizing -------------------------------------------------------------

    // The ListView sets width: parent.width on the delegate. Height is driven
    // from the content plus the card's internal padding (Style.marginM on
    // all sides), mirroring how the notification delegate sizes itself via
    // `contentColumn.height + Style.margin2M`.
    implicitHeight: card.compact ? Style.baseWidgetSize * 2 : rowLayout.implicitHeight + Style.margin2M

    // --- Hover / press detection --------------------------------------------

    // Hover state drives:
    //   - card border accent (idle: mOutline; hover/press: mPrimary)
    //   - visibility of the delete button (hidden until hover)
    //   - pressed fill overlay (mPrimary @ 12% opacity while held)
    // Tracks whether the row is currently being pressed (mouse down but not
    // yet released). Driven by rowArea.onPressed/onReleased below.
    property bool pressed: false

    // HoverHandler is geometry-based and not affected by z-ordering of child
    // MouseAreas (e.g. NIconButton internals). Using it instead of
    // rowArea.containsMouse prevents the flicker loop where hovering over a
    // button causes rowArea (z:-1) to lose hover → buttons hide → rowArea
    // regains hover → buttons show → repeat.
    HoverHandler { id: cardHover }

    // --- Row background card -----------------------------------------------
    //
    // Visual model:
    //
    //   Idle      — mSurfaceVariant fill, mOutline border
    //   Hover     — mSurfaceVariant fill, mPrimary border
    //   Selected  — mSecondaryContainer fill, mPrimary border
    //   Pressed   — mPrimary @ 12% opacity fill, mPrimary border
    //
    // Precedence (highest wins): Pressed > Selected > Hover > Idle.
    // Pressed beats Selected so a click on a selected row still gives
    // the user "you pressed me" feedback — otherwise the selection fill
    // would swallow the press overlay.
    //
    // border.width is CONSTANT (Style.borderS) so the border never changes
    // thickness on hover or selection — a variable border.width causes
    // inset geometry changes that shift content (bug #3 regression fix).
    //
    // Uses NBox (qs.Widgets) per the noctalia-plugins AGENTS.md rule that
    // rounded surfaces should use the shared widget rather than a raw
    // Rectangle. `forceOpaque: true` disables NBox's default
    // `Color.smartAlpha(color)` adjustment so the pressed-state alpha we
    // set here (Qt.alpha(Color.mPrimary, 0.12)) is honored literally —
    // otherwise smartAlpha would compound the alpha and shift the idle /
    // selected fills as well.
    NBox {
        anchors.fill: parent
        forceOpaque: true
        radius: Style.radiusM
        color: card.pressed
            ? Qt.alpha(Color.mPrimary, 0.12)
            : (card.selected ? Color.mSecondaryContainer : Color.mSurfaceVariant)
        border.color: (cardHover.hovered || card.pressed || card.selected)
            ? Color.mPrimary
            : Qt.alpha(Color.mOutline, Style.opacityHeavy)
        border.width: Style.borderS
    }

    // --- Row content --------------------------------------------------------

    RowLayout {
        id: rowLayout
        visible: !card.compact
        // Internal padding lives on the card (Style.marginM on all sides),
        // identical to the NotificationHistoryPanel's `contentColumn`
        // anchors.margins. No per-side override — the card owns its gutters.
        anchors.fill: parent
        anchors.margins: Style.marginM
        spacing: Style.marginM

        // Image branch: visible only for image-type entries when the
        // showImagePreviews setting is on. Source binding reads
        // imageCacheRevision so the Image refreshes as soon as the
        // decode completes and addToImageCache fires the counter.
        //
        // While the cache lookup returns undefined (first-load state),
        // source is "" which paints nothing — the RowLayout still
        // reserves the row height via Layout.preferredHeight so there's
        // no content jump when the thumbnail appears. If we wanted a
        // placeholder icon here later, it would go in an overlay that
        // fades out on Image.status === Image.Ready.
        Image {
            id: previewImage
            visible: card.renderAsImage
            Layout.fillWidth: true
            // 2x baseWidgetSize gives enough room to make thumbnails
            // recognisable without the row towering over text rows.
            Layout.preferredHeight: Style.baseWidgetSize * 2
            fillMode: Image.PreserveAspectFit
            // Align left so short/narrow thumbnails don't drift to the
            // center of a wide row where they look disconnected from the
            // row gutter.
            horizontalAlignment: Image.AlignLeft
            // Avoid rastering at the exact Image dimensions — lets
            // PreserveAspectFit scale from the decoded source without
            // a second blurry resample.
            asynchronous: true
            cache: true
            smooth: true
            // Both reads matter: imageCache holds the URL; reading
            // imageCacheRevision in the same expression forces a
            // re-evaluation when addToImageCache mutates the cache in
            // place from Object.assign (the reference itself changes,
            // but reading the revision counter is the idiom used
            // elsewhere in the plugin — see Panel.qml model binding).
            source: {
                const _rev = card.pluginApi?.mainInstance?.imageCacheRevision ?? 0;
                return card.pluginApi?.mainInstance?.imageCache?.[card.entryId] ?? "";
            }
        }

        NText {
            id: previewLabel
            // Hidden on image rows (both rendered and icon-fallback) and file rows.
            visible: !card.renderAsImage && !card.renderAsFile && card.itemType !== "image"
            Layout.fillWidth: true
            text: card.previewText
            pointSize: Style.fontSizeM
            font.weight: Font.Normal
            color: Color.mOnSurface
            elide: Text.ElideRight
            maximumLineCount: 1
            wrapMode: Text.NoWrap
        }

        // Image icon branch: shown for image entries when showImagePreviews is
        // off. Mirrors the file branch pattern — icon on the left, preview text
        // on the right so the row looks intentional rather than broken.
        RowLayout {
            id: imageBranch
            visible: card.itemType === "image" && !card.renderAsImage && !card.compact
            enabled: false
            Layout.fillWidth: true
            spacing: Style.marginM

            NIcon {
                icon: "image"
                pointSize: Style.fontSizeXXL
                color: Color.mOnSurface
            }

            NText {
                Layout.fillWidth: true
                text: card.previewText
                pointSize: Style.fontSizeM
                color: Color.mOnSurface
                elide: Text.ElideRight
                maximumLineCount: 1
                wrapMode: Text.NoWrap
            }
        }

        // File branch: icon + basename (primary) + parent path (secondary,
        // dimmed) + right-aligned size. Laid out as a row inside the
        // outer RowLayout so it coexists cleanly with the trailing
        // delete button. The NIcon + inner ColumnLayout mirrors the
        // icon-left / two-line-text-right pattern used by the Noctalia
        // notification panel.
        //
        // See docs/specs/file-items.md for the full rendering contract.
        RowLayout {
            id: fileBranch
            visible: card.renderAsFile
            // disabled so NIcon (and any other child with hover/mouse
            // tracking) does not consume pointer events — clicks fall
            // through to rowArea (copy) and rowArea.containsMouse tracks
            // hover for the whole card so deleteButton remains reachable.
            enabled: false
            Layout.fillWidth: true
            spacing: Style.marginM

            NIcon {
                icon: "file"
                pointSize: Style.fontSizeXXL
                color: Color.mOnSurface
            }

            ColumnLayout {
                Layout.fillWidth: true
                // 0 spacing so the filename/parent pair reads as one
                // two-line block, matching the notification panel's
                // title/body stack. Line height of NText itself gives
                // the small visual gap between lines.
                spacing: 0

                NText {
                    id: fileName
                    Layout.fillWidth: true
                    // Primary line: bold basename. Elide right so a
                    // long filename doesn't push the size column off
                    // the row.
                    text: card.fileMeta.filename || card.previewText
                    pointSize: Style.fontSizeM
                    font.weight: Style.fontWeightBold
                    color: Color.mOnSurface
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    wrapMode: Text.NoWrap
                }

                NText {
                    id: fileParent
                    Layout.fillWidth: true
                    // Secondary line: dimmed parent dir. Elide middle
                    // so both the leading "~" / "/" and the final dir
                    // segment stay visible for long nested paths.
                    // Hidden when there's no parent to show (e.g. a
                    // malformed URI) so the row doesn't reserve a
                    // blank line.
                    visible: text.length > 0
                    text: card.fileMeta.parentDir
                    pointSize: Style.fontSizeS
                    color: Color.mOnSurfaceVariant
                    elide: Text.ElideMiddle
                    maximumLineCount: 1
                    wrapMode: Text.NoWrap
                }
            }

            NText {
                id: fileSize
                // Right-aligned size. Hidden when the meta record's
                // sizeHuman is empty (stat failed, file missing, or
                // placeholder before the stat completes) so the row
                // doesn't reserve whitespace for an invisible value.
                visible: text.length > 0
                text: card.fileMeta.sizeHuman
                pointSize: Style.fontSizeS
                color: Color.mOnSurfaceVariant
                horizontalAlignment: Text.AlignRight
            }
        }

        // Trailing section — fixed-width slot so the left content column
        // never shifts position regardless of which state is active inside.
        //
        // Three mutually-exclusive states rendered inside a single Item:
        //   1. Time label   — non-pinned, not hovering
        //   2. Pin + Delete — non-pinned, hovering
        //   3. Unpin button — pinned (always, no hover required)
        //
        // Using visible (not opacity) to switch between states is safe here
        // because all three live inside the fixed-width Item — only their
        // own width changes, not the Item's, so the outer RowLayout never
        // reflows. Compact cells omit this section entirely (the image grid
        // has its own overlaid controls in compactContent).
        Item {
            id: trailingSection
            visible: !card.compact
            // Pinned rows occupy one button width (just unpin); history rows
            // occupy two buttons + gap (pin + delete on hover). This gives
            // pinned rows more horizontal space for the copy value while
            // keeping non-pinned rows stable between idle and hover states.
            Layout.preferredWidth: card.pinned
                ? Style.baseWidgetSize * 0.7
                : Style.baseWidgetSize * 0.7 * 2 + Style.marginS
            Layout.fillHeight: true

            // State 1: relative-time label (non-pinned, idle).
            NText {
                id: relativeTimeLabel
                anchors.centerIn: parent
                visible: !cardHover.hovered && !card.pinned && card.relativeTimeText.length > 0
                text: card.relativeTimeText
                pointSize: Style.fontSizeS
                color: Color.mOnSurfaceVariant
                horizontalAlignment: Text.AlignRight
            }

            // State 2: pin + delete buttons (non-pinned, hovering).
            Row {
                id: hoverButtons
                anchors.centerIn: parent
                visible: cardHover.hovered && !card.pinned
                spacing: Style.marginS

                NIconButton {
                    icon: "pin"
                    tooltipText: card.pluginApi?.tr("panel.pin")
                    baseSize: Style.baseWidgetSize * 0.7
                    onClicked: {
                        const main = card.pluginApi?.mainInstance;
                        if (!main)
                            return;
                        main.pin({ preview: card.previewText, type: card.itemType });
                    }
                }

                NIconButton {
                    icon: "trash"
                    tooltipText: card.pluginApi?.tr("panel.delete")
                    baseSize: Style.baseWidgetSize * 0.7
                    onClicked: {
                        if (!card.entryId)
                            return;
                        card.pluginApi?.mainInstance?.remove(card.entryId);
                        card.deleted();
                    }
                }
            }

            // State 3: unpin button (pinned rows, always visible).
            // Right-anchored so it aligns with the delete button position
            // in non-pinned rows (delete is the rightmost of the two buttons).
            NIconButton {
                id: unpinButton
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                visible: card.pinned
                icon: "unpin"
                tooltipText: card.pluginApi?.tr("panel.unpin")
                baseSize: Style.baseWidgetSize * 0.7
                onClicked: {
                    const main = card.pluginApi?.mainInstance;
                    if (!main || card.pinnedIndex < 0)
                        return;
                    main.unpin(card.pinnedIndex);
                    card.deleted();
                }
            }
        }
    }

    // --- Compact grid cell (Images tab) ------------------------------------
    //
    // Fills the card with a cropped thumbnail; the delete button overlays the
    // top-right corner and is revealed on hover (same opacity idiom as the
    // list mode delete button so the row height / cell size is stable).
    Item {
        id: compactContent
        visible: card.compact
        anchors.fill: parent

        // Inset just enough to clear the card's rounded border so the image
        // never visually overflows the corner radius.
        Image {
            anchors.fill: parent
            anchors.margins: Style.marginXS
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            smooth: true
            source: {
                const _rev = card.pluginApi?.mainInstance?.imageCacheRevision ?? 0;
                return card.pluginApi?.mainInstance?.imageCache?.[card.entryId] ?? "";
            }
        }

        // Pin badge overlay for pinned cells in the Images grid. Top-
        // left so it doesn't collide with the top-right delete button.
        // Always visible (not hover-gated) so the user can see at a
        // glance which cells are pinned while scrolling.
        NIcon {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.margins: Style.marginS
            visible: card.pinned
            icon: "pin"
            pointSize: Style.fontSizeL
            color: Color.mPrimary
        }

        NIconButton {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: Style.marginS
            opacity: cardHover.hovered ? 1 : 0
            // Same pinned-vs-trash branch as the list-mode button so a
            // pinned image cell in the Images grid unpins correctly. In
            // practice pinned image entries render as text (not as grid
            // cells) because renderAsImage is false for pinned rows, but
            // keep the icon in sync for any future cell-level reuse.
            icon: card.pinned ? "unpin" : "trash"
            tooltipText: card.pinned
                ? card.pluginApi?.tr("panel.unpin")
                : card.pluginApi?.tr("panel.delete")
            baseSize: Style.baseWidgetSize * 0.8
            onClicked: {
                const main = card.pluginApi?.mainInstance;
                if (!main)
                    return;
                if (card.pinned) {
                    if (card.pinnedIndex >= 0)
                        main.unpin(card.pinnedIndex);
                } else {
                    if (!card.entryId)
                        return;
                    main.remove(card.entryId);
                }
                // No toast on delete — see rationale above on the
                // list-mode delete button.
                card.deleted();
            }
        }
    }

    // --- Whole-row click → copy --------------------------------------------

    // MouseArea instead of TapHandler: NIconButton's internal MouseArea has
    // `enabled: true` at all times (Qt 6 pointer event system), which eats
    // LeftButton events before a sibling TapHandler can see them. Using
    // MouseArea here matches NotificationHistoryPanel's row-click pattern
    // and plays correctly with NIconButton's own handler sitting above it.
    //
    // anchors.fill covers the full row; the delete button's own MouseArea
    // (inside NIconButton) sits higher in the z-order and handles its own
    // clicks — the containsMouse/press tracking here does not conflict.
    MouseArea {
        id: rowArea
        // z:-1 puts this behind rowLayout so Qt delivers clicks to
        // rowLayout's children (e.g. deleteButton) first. Clicks in
        // non-interactive areas (text, icon) fall through to rowArea
        // here, which handles the copy action. Without z:-1, rowArea
        // (declared last = highest default z) would eat all clicks
        // before the delete button's handler sees them.
        z: -1
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor
        // Drive pressed state for the fill-color visual feedback on the
        // background Rectangle above. onReleased fires whether the pointer
        // lifts inside or outside the item, so the pressed overlay always
        // clears — no stuck-highlighted state after a drag-away.
        onPressed: card.pressed = true
        onReleased: card.pressed = false
        onClicked: {
            if (!card.entryId)
                return;
            const main = card.pluginApi?.mainInstance;
            if (!main)
                return;
            // Pinned rows route through copyPinned(index) — they carry no
            // cliphist id, so copy(id) would fail its internal lookup and
            // wl-copy would receive an empty string. copyPinned pipes the
            // stored preview text directly. See docs/specs/pinned-items.md.
            if (card.pinned && card.pinnedIndex >= 0) {
                main.copyPinned(card.pinnedIndex);
            } else {
                main.copy(card.entryId);
            }
            const typeSlug = card.itemType === "file" ? "file"
                           : card.itemType === "image" ? "image"
                           : "text";
            ToastService.showNotice(
                card.pluginApi?.tr("toast.item-copied-" + typeSlug + "-title"),
                card.pluginApi?.tr("toast.item-copied-" + typeSlug + "-body")
            );
            // Emit copied() so Panel can fire its own deferred-close timer.
            // Panel owns the timer because `reuseItems: true` on the ListView
            // can recycle this delegate mid-close, invalidating any Timer
            // owned here. Panel's pluginApi.panelOpenScreen reference is
            // stable across the 50ms deferral.
            card.copied();
        }
    }
}
