import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Services.UI

Item {
  property var pluginApi: null

  Component.onCompleted: {
    if (pluginApi) {
      Logger.i("FileSearch", "Plugin initialized");
    }
  }

  IpcHandler {
    target: "plugin:file-search"
    
    // Toggle launcher in file search mode
    function toggle() {
      if (!pluginApi) return;
      
      pluginApi.withCurrentScreen(screen => {
        var launcherPanel = PanelService.getPanel("launcherPanel", screen);
        if (!launcherPanel) {
          Logger.e("FileSearch", "Could not get launcher panel");
          return;
        }
        
        var searchText = launcherPanel.searchText || "";
        var isInFileMode = searchText.startsWith(">file");
        
        if (!launcherPanel.isPanelOpen) {
          // Launcher closed - open with file search
          Logger.i("FileSearch", "Opening launcher in file search mode");
          launcherPanel.open();
          launcherPanel.setSearchText(">file ");
        } else if (isInFileMode) {
          // Already in file mode - close launcher
          Logger.i("FileSearch", "Closing launcher (toggle off)");
          launcherPanel.close();
        } else {
          // Launcher open but different mode - switch to file search
          Logger.i("FileSearch", "Switching to file search mode");
          launcherPanel.setSearchText(">file ");
        }
      });
    }
    
    // Open launcher with file search and specific query
    function search(query: string) {
      if (!pluginApi) return;
      
      pluginApi.withCurrentScreen(screen => {
        var launcherPanel = PanelService.getPanel("launcherPanel", screen);
        if (!launcherPanel) {
          Logger.e("FileSearch", "Could not get launcher panel");
          return;
        }
        
        var searchQuery = query || "";
        Logger.i("FileSearch", "Opening launcher with search query:", searchQuery);
        
        launcherPanel.open();
        launcherPanel.setSearchText(">file " + searchQuery);
      });
    }
  }
}
