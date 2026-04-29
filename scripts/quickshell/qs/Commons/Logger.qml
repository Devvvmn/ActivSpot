pragma Singleton
import QtQuick
import Quickshell

Singleton {
    function d(tag, msg) { console.debug("[" + tag + "]", msg) }
    function i(tag, msg) { console.info("[" + tag + "]", msg) }
    function w(tag, msg) { console.warn("[" + tag + "]", msg) }
    function e(tag, msg) { console.error("[" + tag + "]", msg) }
}
