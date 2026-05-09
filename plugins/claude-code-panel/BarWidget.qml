import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets
import qs.Services.UI
import qs.Services.System

Item {
  id: root
  property var pluginApi: null

  property ShellScreen screen
  property string widgetId: ""
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  readonly property var mainInstance: pluginApi?.mainInstance
  readonly property bool isGenerating: mainInstance?.isGenerating || false
  readonly property bool binaryAvailable: mainInstance?.binaryAvailable || false
  readonly property string permissionMode: mainInstance?.permissionMode || "default"
  readonly property bool dangerouslySkip: mainInstance?.dangerouslySkip || false
  readonly property int messageCount: mainInstance?.messages?.length || 0
  readonly property string sessionId: mainInstance?.sessionId || ""

  readonly property string screenName: screen ? screen.name : ""
  readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
  readonly property bool isVertical: barPosition === "left" || barPosition === "right"
  readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)

  readonly property real contentWidth: capsuleHeight
  readonly property real contentHeight: capsuleHeight

  implicitWidth: contentWidth
  implicitHeight: contentHeight

  function accentColor() {
    if (!binaryAvailable) { return Color.mOnSurfaceVariant; }
    if (dangerouslySkip || permissionMode === "bypassPermissions") { return Color.mError; }
    if (permissionMode === "acceptEdits") { return Color.mSecondary; }
    if (permissionMode === "plan") { return Color.mTertiary; }
    if (isGenerating) { return Color.mPrimary; }
    return Color.mOnSurface;
  }

  Rectangle {
    id: capsule
    x: Style.pixelAlignCenter(parent.width, width)
    y: Style.pixelAlignCenter(parent.height, height)
    width: root.contentWidth
    height: root.contentHeight
    color: mouseArea.containsMouse ? Color.mHover : Style.capsuleColor
    radius: Style.radiusL
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    NIcon {
      id: icon
      anchors.centerIn: parent
      icon: isGenerating ? "loader-2" : "terminal"
      color: root.accentColor()
      applyUiScale: false

      RotationAnimation on rotation {
        running: root.isGenerating
        from: 0; to: 360; duration: 1000
        loops: Animation.Infinite
      }
      Binding {
        target: icon; property: "rotation"; value: 0; when: !root.isGenerating
      }
    }

    // Unread-ish dot for active session
    Rectangle {
      visible: root.sessionId !== ""
      width: Style.marginS; height: Style.marginS; radius: Style.radiusXXXS
      color: root.dangerouslySkip || root.permissionMode === "bypassPermissions"
             ? Color.mError : Color.mPrimary
      anchors.top: parent.top
      anchors.right: parent.right
      anchors.margins: Style.radiusXXXS
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton

    onEntered: TooltipService.show(root, buildTooltip(), BarService.getTooltipDirection())
    onExited: TooltipService.hide()

    onClicked: function (mouse) {
      if (mouse.button === Qt.LeftButton) {
        if (pluginApi) { pluginApi.openPanel(root.screen, root); }
      } else if (mouse.button === Qt.RightButton) {
        PanelService.showContextMenu(contextMenu, root, screen);
      }
    }
  }

  NPopupContextMenu {
    id: contextMenu
    model: [
      { "label": pluginApi?.tr("menu.openPanel"),   "action": "open",    "icon": "external-link" },
      { "label": pluginApi?.tr("menu.newSession"),  "action": "newSession", "icon": "plus" },
      { "label": pluginApi?.tr("menu.stop"),        "action": "stop",    "icon": "square" },
      { "label": pluginApi?.tr("menu.clearHistory"),"action": "clear",   "icon": "trash" },
      { "label": pluginApi?.tr("menu.settings"),    "action": "settings","icon": "settings" }
    ]
    onTriggered: function (action) {
      contextMenu.close();
      PanelService.closeContextMenu(screen);
      if (action === "open") { pluginApi?.openPanel(root.screen, root); }
      else if (action === "newSession") { mainInstance?.newSession(); }
      else if (action === "stop") { mainInstance?.stopGeneration(); }
      else if (action === "clear") {
        mainInstance?.clearMessages();
        ToastService.showNotice(pluginApi?.tr("toast.historyCleared"));
      } else if (action === "settings") {
        BarService.openPluginSettings(screen, pluginApi.manifest);
      }
    }
  }

  function buildTooltip() {
    var t = pluginApi?.tr("widget.tooltipTitle");
    if (!binaryAvailable) {
      t += "\n" + (pluginApi?.tr("widget.notInstalled"));
      return t;
    }
    t += "\n" + (pluginApi?.tr("widget.mode")) + ": " +
         (dangerouslySkip ? "bypass (DANGEROUSLY_SKIP_PERMISSIONS)" : permissionMode);
    if (mainInstance?.lastModel) { t += "\n" + (pluginApi?.tr("widget.model")) + ": " + mainInstance.lastModel; }
    if (sessionId) { t += "\n" + (pluginApi?.tr("widget.session")) + ": " + sessionId.slice(0, 8); }
    if (messageCount > 0) { t += "\n" + (pluginApi?.tr("widget.messages")) + ": " + messageCount; }
    if (isGenerating) { t += "\n" + (pluginApi?.tr("widget.running")); }
    t += "\n\n" + (pluginApi?.tr("widget.rightClickHint"));
    return t;
  }

  Component.onCompleted: {
    Logger.i("ClaudeCode", "BarWidget initialized");
  }
}
