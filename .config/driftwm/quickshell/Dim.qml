import QtQuick
import Quickshell
import Quickshell.Wayland

// A gradual fade to Theme.bg before driftwm's swayidle autolock takes over,
// instead of the instant cut straight to swaylock — the idle-dim idea from
// ilyamiro/serpantinum's guide/IdleTab, minus the IPC hop: Quickshell's own
// idle-notify protocol drives it directly, so no shell script is involved.
// Purely cosmetic — click-through and never focused — so it can't interfere
// with the actual lock, which stays swayidle's job entirely.
//
// dimLead must stay below config.toml's swayidle lock timeout (autostart,
// currently 1800s) or the fade never finishes before the lock fires.
PanelWindow {
    id: root

    readonly property int lockTimeout: 1800
    readonly property int dimLead: 20

    WlrLayershell.namespace: "drift-dim"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    focusable: false
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    // Empty region: the overlay never claims a click, so activity that
    // wakes it back up (mouse move, click-through, keypress) reaches
    // whatever's underneath exactly as if it weren't there.
    mask: Region {}

    IdleMonitor {
        id: idle
        timeout: root.lockTimeout - root.dimLead
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.bg
        opacity: idle.isIdle ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                // Slow fade in as idle approaches the lock; snap back fast on
                // the first sign of activity so waking up doesn't feel laggy.
                duration: idle.isIdle ? root.dimLead * 1000 : 200
                easing.type: Easing.InQuad
            }
        }
    }
}
