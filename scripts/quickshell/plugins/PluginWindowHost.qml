import QtQuick
import Quickshell

// Instantiates standalone plugin windows (PanelWindows etc.) declared via the
// manifest "window" field. Lives in TopBar.qml's ShellRoot. Windows appear /
// disappear live as plugins are installed or removed (PluginLoader rescans).
Scope {
    id: root

    Instantiator {
        model: {
            const out = []
            for (const p of PluginLoader.plugins) {
                if (p.window && p.pluginDir)
                    out.push({ src: "file://" + p.pluginDir + "/" + p.window })
            }
            return out
        }
        delegate: LazyLoader {
            activeAsync: true
            source: modelData.src
        }
    }
}
