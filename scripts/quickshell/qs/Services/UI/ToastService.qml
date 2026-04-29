pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Routes plugin toast notifications through notify-send.
Singleton {
    id: root

    function showNotice(title, body) {
        let args = ["notify-send", "-u", "normal", title ?? ""]
        if (body) args.push(body)
        Quickshell.execDetached(args)
    }

    function showError(title, body) {
        let args = ["notify-send", "-u", "critical", title ?? "Error"]
        if (body) args.push(body)
        Quickshell.execDetached(args)
    }

    function showWarning(title, body) {
        let args = ["notify-send", "-u", "low", title ?? ""]
        if (body) args.push(body)
        Quickshell.execDetached(args)
    }
}
