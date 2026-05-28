import QtQuick
import Quickshell

FloatingWindow {
    visible: true
    color: "#1a1b26" 
    width: 1920
    height: 120
    
    Loader {
        anchors.fill: parent
        source: "sysinfo/SysInfoCard.qml"
        onStatusChanged: {
            if (status == Loader.Error) console.error("Loader Error: " + sourceComponent.errorString())
            else if (status == Loader.Ready) console.log("Widget successfully loaded into proxy window")
        }
    }
}
