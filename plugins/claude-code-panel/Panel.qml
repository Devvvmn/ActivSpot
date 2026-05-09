import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets
import qs.Services.UI

Item {
  id: root

  property var pluginApi: null

  readonly property var mainInstance: pluginApi?.mainInstance
  readonly property var geometryPlaceholder: panelContainer

  readonly property string _panelPosition: pluginApi?.pluginSettings?.panelPosition ?? "right"
  readonly property bool _detached: pluginApi?.pluginSettings?.panelDetached ?? true
  readonly property string _attachmentStyle: pluginApi?.pluginSettings?.attachmentStyle || "connected"
  readonly property bool _isFloatingAttached: !_detached && _attachmentStyle === "floating"
  readonly property bool allowAttach: !_detached

  readonly property bool panelAnchorRight: _panelPosition === "right"
  readonly property bool panelAnchorLeft: _panelPosition === "left"
  readonly property bool panelAnchorHorizontalCenter:
      (_detached && _panelPosition === "center") ||
      (_isFloatingAttached && (_panelPosition === "top" || _panelPosition === "bottom"))
  readonly property bool panelAnchorVerticalCenter:
      _detached || (_isFloatingAttached && (_panelPosition === "left" || _panelPosition === "right"))
  readonly property bool panelAnchorTop: !_detached && _panelPosition === "top"
  readonly property bool panelAnchorBottom: !_detached && _panelPosition === "bottom"

  property int _panelWidth: pluginApi?.pluginSettings?.panelWidth ?? 620
  property real _panelHeightRatio: pluginApi?.pluginSettings?.panelHeightRatio ?? 0.9
  property real contentPreferredWidth: _panelWidth
  property real contentPreferredHeight: screen ? (screen.height * _panelHeightRatio) : 720 * Style.uiScaleRatio
  property real uiScale: pluginApi?.pluginSettings?.scale ?? 1

  anchors.fill: parent

  readonly property string permissionMode: mainInstance?.permissionMode || "default"
  readonly property bool dangerouslySkip: mainInstance?.dangerouslySkip || false
  readonly property bool isGenerating: mainInstance?.isGenerating || false

  function bannerColor() {
    if (dangerouslySkip || permissionMode === "bypassPermissions") { return Color.mError; }
    if (permissionMode === "acceptEdits") { return Color.mSecondary; }
    if (permissionMode === "plan") { return Color.mTertiary; }
    return Color.mPrimary;
  }

  function bannerText() {
    if (dangerouslySkip || permissionMode === "bypassPermissions") {
      return pluginApi?.tr("panel.bannerBypass");
    }
    if (permissionMode === "acceptEdits") { return pluginApi?.tr("panel.bannerAccept"); }
    if (permissionMode === "plan") { return pluginApi?.tr("panel.bannerPlan"); }
    return pluginApi?.tr("panel.bannerDefault");
  }

  Rectangle {
    id: panelContainer
    width: contentPreferredWidth
    height: contentPreferredHeight
    color: "transparent"
    anchors.horizontalCenter: (_detached && _panelPosition === "center" && parent) ? parent.horizontalCenter : undefined
    anchors.verticalCenter: (_detached && _panelPosition === "center" && parent) ? parent.verticalCenter : undefined
    y: (_detached && (_panelPosition === "left" || _panelPosition === "right")) ? (root.height - contentPreferredHeight) / 2 : 0

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.marginM
      spacing: Style.marginS

      // ----- Header -----
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: headerRow.implicitHeight + Style.marginS * 2
        color: Color.mSurfaceVariant
        radius: Style.radiusM

        RowLayout {
          id: headerRow
          anchors.fill: parent
          anchors.margins: Style.marginS
          spacing: Style.marginM

          NIcon { icon: "terminal"; color: Color.mPrimary; pointSize: Style.fontSizeL }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.marginXXS
            NText {
              text: pluginApi?.tr("panel.title")
              font.weight: Font.Bold
              pointSize: Style.fontSizeM
              color: Color.mOnSurface
            }
            NText {
              Layout.fillWidth: true
              elide: Text.ElideMiddle
              text: {
                var parts = [];
                var sid = mainInstance?.sessionId || "";
                parts.push(sid ? pluginApi?.tr("panel.sessionIdValue", { id: sid.slice(0, 8) }) : pluginApi?.tr("panel.noSession"));
                if (mainInstance?.lastModel) { parts.push(mainInstance.lastModel); }
                var wd = mainInstance?.workingDir || "";
                if (wd) { parts.push(pluginApi?.tr("panel.cwdValue", { path: wd })); }
                return parts.join(" · ");
              }
              pointSize: Style.fontSizeXS
              color: Color.mOnSurfaceVariant
            }
          }

          NButton {
            text: pluginApi?.tr("panel.newSession")
            icon: "plus"
            onClicked: mainInstance?.newSession()
            enabled: !!mainInstance
          }
        }
      }

      // ----- Permission banner -----
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: bannerTextEl.implicitHeight + Style.marginS * 2
        color: Qt.rgba(root.bannerColor().r, root.bannerColor().g, root.bannerColor().b, 0.18)
        border.color: root.bannerColor()
        border.width: Style.borderS
        radius: Style.radiusM

        RowLayout {
          anchors.fill: parent
          anchors.margins: Style.marginS
          spacing: Style.marginS

          NIcon {
            icon: root.dangerouslySkip || root.permissionMode === "bypassPermissions" ? "alert-triangle" : "shield"
            color: root.bannerColor()
          }
          NText {
            id: bannerTextEl
            Layout.fillWidth: true
            text: root.bannerText() || ""
            wrapMode: Text.WordWrap
            color: Color.mOnSurface
            pointSize: Style.fontSizeS
          }
          NText {
            text: root.permissionMode
            color: root.bannerColor()
            font.weight: Font.Bold
            pointSize: Style.fontSizeXS
          }
        }
      }

      // ----- Binary missing warning -----
      Rectangle {
        Layout.fillWidth: true
        visible: mainInstance && mainInstance.binaryChecked && !mainInstance.binaryAvailable
        Layout.preferredHeight: visible ? binaryHelp.implicitHeight + Style.marginS * 2 : 0
        color: Qt.rgba(0.9, 0.2, 0.2, 0.15)
        border.color: Color.mError
        radius: Style.radiusM
        NText {
          id: binaryHelp
          anchors.fill: parent
          anchors.margins: Style.marginS
          text: (pluginApi?.tr("errors.binaryMissing")) +
                "\n   npm i -g @anthropic-ai/claude-code"
          wrapMode: Text.WordWrap
          color: Color.mOnSurface
          pointSize: Style.fontSizeXS
        }
      }

      // ----- Conversation -----
      Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        color: Color.mSurfaceVariant
        radius: Style.radiusL
        clip: true

        NListView {
          id: list
          anchors.fill: parent
          anchors.margins: Style.marginS
          spacing: Style.marginS
          model: mainInstance?.messages || []
          cacheBuffer: 400
          boundsBehavior: Flickable.StopAtBounds
          reserveScrollbarSpace: true

          // Auto-scroll that respects the user: stickBottom flips off when they scroll up.
          property bool stickBottom: true
          readonly property real _bottomThreshold: 32

          function scrollToEnd() {
            if (count <= 0) return;
            positionViewAtEnd();
          }

          function isAtBottom() {
            return (contentY + height) >= (contentHeight - _bottomThreshold);
          }

          onCountChanged: {
            if (stickBottom) { Qt.callLater(scrollToEnd); }
          }
          onContentHeightChanged: {
            // Last bubble growing mid-stream — follow it down if we're already at the bottom.
            if (stickBottom) { Qt.callLater(scrollToEnd); }
          }
          onMovingChanged: {
            // User finished a scroll gesture — lock/unlock auto-follow.
            if (!moving) { stickBottom = isAtBottom(); }
          }
          onFlickingChanged: {
            if (!flicking) { stickBottom = isAtBottom(); }
          }

          delegate: MessageBubble {
            width: list.availableWidth
            entry: modelData
            pluginApi: root.pluginApi
            mainInstance: root.mainInstance
          }

          // Jump-to-bottom pill, appears only when auto-follow is off.
          Rectangle {
            visible: !list.stickBottom && list.count > 0
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.margins: Style.marginS
            width: jumpRow.implicitWidth + Style.marginM * 2
            height: jumpRow.implicitHeight + Style.marginS * 2
            radius: height / 2
            color: Color.mPrimary
            opacity: jumpMouse.containsMouse ? 1.0 : 0.85
            z: 10

            RowLayout {
              id: jumpRow
              anchors.centerIn: parent
              spacing: Style.marginXS
              NIcon { icon: "arrow-down"; color: Color.mOnPrimary; pointSize: Style.fontSizeXS }
              NText { text: pluginApi?.tr("panel.jumpToLatest"); color: Color.mOnPrimary; pointSize: Style.fontSizeXS }
            }
            MouseArea {
              id: jumpMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: { list.stickBottom = true; list.scrollToEnd(); }
            }
          }
        }
      }

      // Thin streaming indicator bar (shown while generating; actual text streams inline into the last bubble)
      Rectangle {
        Layout.fillWidth: true
        visible: mainInstance && mainInstance.isGenerating
        Layout.preferredHeight: visible ? 3 : 0
        color: "transparent"
        Rectangle {
          anchors.fill: parent
          color: Color.mPrimary
          opacity: 0.8
          radius: Style.marginXXS
          SequentialAnimation on opacity {
            running: parent.visible
            loops: Animation.Infinite
            NumberAnimation { from: 0.35; to: 1.0; duration: 650; easing.type: Easing.InOutQuad }
            NumberAnimation { from: 1.0; to: 0.35; duration: 650; easing.type: Easing.InOutQuad }
          }
        }
      }

      // ----- Error strip -----
      Rectangle {
        Layout.fillWidth: true
        visible: mainInstance && mainInstance.errorMessage !== ""
        Layout.preferredHeight: visible ? errText.implicitHeight + Style.marginS * 2 : 0
        color: Qt.rgba(0.9, 0.2, 0.2, 0.15)
        border.color: Color.mError
        radius: Style.radiusM
        NText {
          id: errText
          anchors.fill: parent
          anchors.margins: Style.marginS
          text: mainInstance?.errorMessage || ""
          wrapMode: Text.Wrap
          color: Color.mError
          pointSize: Style.fontSizeXS
        }
      }

      // ----- Input row -----
      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        NTextInput {
          id: inputField
          Layout.fillWidth: true
          placeholderText: pluginApi?.tr("panel.inputPlaceholder")
          text: mainInstance?.inputText || ""
          onTextChanged: {
            if (mainInstance) {
              mainInstance.inputText = text;
              mainInstance.saveState();
            }
          }
          Keys.onPressed: function (event) {
            if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && !(event.modifiers & Qt.ShiftModifier)) {
              root.submit();
              event.accepted = true;
            }
          }
        }

        NButton {
          text: isGenerating ? (pluginApi?.tr("panel.stop")) : (pluginApi?.tr("panel.send"))
          icon: isGenerating ? "square" : "send"
          enabled: !!mainInstance && (mainInstance.binaryAvailable || isGenerating)
          onClicked: isGenerating ? mainInstance.stopGeneration() : root.submit()
        }
      }
    }
  }

  function submit() {
    if (!mainInstance) { return; }
    var t = inputField.text;
    if (!t || t.trim() === "") { return; }
    var trimmed = t.trim();
    // Local slash command? Handle and bail without touching Claude.
    if (trimmed[0] === "/" && mainInstance.handleSlashCommand(trimmed)) {
      inputField.text = "";
      mainInstance.inputText = "";
      mainInstance.inputCursor = 0;
      mainInstance.saveState();
      return;
    }
    mainInstance.sendMessage(trimmed);
    inputField.text = "";
    mainInstance.inputText = "";
    mainInstance.inputCursor = 0;
    mainInstance.saveState();
  }

  Component.onCompleted: {
    Logger.i("ClaudeCode", "Panel ready");
  }

  onVisibleChanged: {
    if (visible) { Qt.callLater(function () { inputField.forceActiveFocus(); }); }
  }

  // ====================================================================
  // MessageBubble — rich per-message rendering with markdown + copy button
  // ====================================================================
  component MessageBubble: Item {
    id: bubbleRoot
    property var entry
    property var pluginApi
    property var mainInstance

    implicitHeight: bubble.implicitHeight

    function bubbleColor() {
      if (!entry) return "transparent";
      if (entry.role === "user") return Color.mPrimaryContainer;
      if (entry.role === "tool") return Color.mSurface;
      if (entry.kind === "tool_use") return Color.mSecondaryContainer;
      if (entry.kind === "thinking") return Qt.rgba(0.4, 0.4, 0.7, 0.1);
      return Color.mSurface;
    }

    function headerIcon() {
      if (!entry) return "circle";
      if (entry.role === "user") return "user";
      if (entry.kind === "tool_use") return "wrench";
      if (entry.kind === "tool_result") return "check-circle";
      if (entry.kind === "thinking") return "brain";
      return "sparkles";
    }

    function headerIconColor() {
      if (!entry) return Color.mOnSurface;
      if (entry.kind === "tool_use") {
        var c = entry.meta ? entry.meta.classification : "safe";
        if (c === "exec") return Color.mError;
        if (c === "write") return Color.mSecondary;
        if (c === "network") return Color.mTertiary;
      }
      if (entry.role === "tool" && entry.meta && entry.meta.isError) return Color.mError;
      return Color.mOnSurface;
    }

    function headerLabel() {
      if (!entry) return "";
      if (entry.role === "user") return "You";
      if (entry.role === "tool") return pluginApi?.tr("panel.toolResult");
      if (entry.kind === "tool_use") return (pluginApi?.tr("panel.toolUse")) + " · " + (entry.meta ? entry.meta.toolName : "");
      if (entry.kind === "thinking") return "Thinking";
      return "Claude";
    }

    // Preformatted (monospace, no markdown) for tool I/O; markdown everywhere else.
    function isCodeLike() {
      if (!entry) return false;
      return entry.kind === "tool_use" || entry.kind === "tool_result";
    }

    Rectangle {
      id: bubble
      width: parent.width
      radius: Style.radiusM
      color: bubbleRoot.bubbleColor()
      implicitHeight: inner.implicitHeight + Style.marginS * 2

      ColumnLayout {
        id: inner
        anchors.fill: parent
        anchors.margins: Style.marginS
        spacing: Style.marginXS

        RowLayout {
          Layout.fillWidth: true
          spacing: Style.marginXS

          NIcon {
            icon: bubbleRoot.headerIcon()
            pointSize: Style.fontSizeS
            color: bubbleRoot.headerIconColor()
          }
          NText {
            text: bubbleRoot.headerLabel()
            font.weight: Font.Medium
            pointSize: Style.fontSizeXS
            color: Color.mOnSurfaceVariant
          }
          Item { Layout.fillWidth: true }
          NText {
            visible: entry && entry.timestamp
            text: entry && entry.timestamp ? entry.timestamp.slice(11, 19) : ""
            pointSize: Style.fontSizeXS
            color: Color.mOnSurfaceVariant
            opacity: 0.6
          }
          // Copy button
          Rectangle {
            width: Style.iconSizeS; height: Style.iconSizeS; radius: Style.iconSizeS / 2
            color: copyMouse.containsMouse ? Color.mHover : "transparent"
            visible: entry && entry.text && entry.text !== ""
            NIcon {
              anchors.centerIn: parent
              icon: "copy"
              pointSize: Style.fontSizeXS
              color: Color.mOnSurfaceVariant
            }
            MouseArea {
              id: copyMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (bubbleRoot.mainInstance && entry && entry.text) {
                  bubbleRoot.mainInstance.copyToClipboard(entry.text);
                }
              }
            }
          }
        }

        // Body — markdown for chat text, preformatted for tool I/O
        RowLayout {
          Layout.fillWidth: true
          spacing: Style.marginXXS

          NText {
            Layout.fillWidth: true
            text: {
              if (!entry) return "";
              if (entry.streaming && (!entry.text || entry.text === "")) {
                return "_…_";   // italic ellipsis as an initial placeholder
              }
              return entry.text || "";
            }
            wrapMode: bubbleRoot.isCodeLike() ? Text.NoWrap : Text.Wrap
            textFormat: bubbleRoot.isCodeLike() ? Text.PlainText : Text.MarkdownText
            color: Color.mOnSurface
            pointSize: Style.fontSizeS
            font.family: bubbleRoot.isCodeLike() ? "monospace" : ""
            visible: text !== ""
            onLinkActivated: function (url) { Qt.openUrlExternally(url); }
          }

          // Blinking caret while this bubble is streaming
          Rectangle {
            visible: entry && entry.streaming === true
            width: 8; height: 14
            color: Color.mPrimary
            radius: Style.marginXXXS
            Layout.alignment: Qt.AlignBottom
            SequentialAnimation on opacity {
              running: visible
              loops: Animation.Infinite
              NumberAnimation { from: 1.0; to: 0.1; duration: 500 }
              NumberAnimation { from: 0.1; to: 1.0; duration: 500 }
            }
          }
        }

        // Tool-use details (arg preview in mono) — only when entry has structured input
        Rectangle {
          Layout.fillWidth: true
          visible: entry && entry.kind === "tool_use" && entry.meta && entry.meta.input && Object.keys(entry.meta.input).length > 0
          Layout.preferredHeight: visible ? (argsText.implicitHeight + Style.marginXS * 2) : 0
          color: Qt.rgba(0, 0, 0, 0.12)
          radius: Style.radiusS

          NText {
            id: argsText
            anchors.fill: parent
            anchors.margins: Style.marginXS
            text: {
              if (!entry || entry.kind !== "tool_use" || !entry.meta) return "";
              try { return JSON.stringify(entry.meta.input, null, 2); }
              catch (e) { return ""; }
            }
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            font.family: "monospace"
            pointSize: Style.fontSizeXS
            color: Color.mOnSurface
          }
        }
      }
    }
  }
}
