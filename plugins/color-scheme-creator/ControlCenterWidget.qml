import QtQuick
import Quickshell
import qs.Widgets

NIconButtonHot {
  property ShellScreen screen
  property var pluginApi: null

  icon: "palette"
  tooltipText: pluginApi?.tr("widget.tooltip")
  onClicked: {
    if (pluginApi) {
      pluginApi.togglePanel(screen, this);
    }
  }
}
