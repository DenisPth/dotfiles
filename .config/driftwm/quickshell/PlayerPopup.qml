import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

// A small floating window wrapping the dashboard's own PlayerWidget —
// toggled from waybar's mpris module (`qs ipc call player toggle`) so
// clicking that icon pops up real controls instead of jumping the whole
// canvas view to the dashboard.
FloatingWindow {
    id: root

    title: "player-popup"
    color: "transparent"
    implicitWidth: player.implicitWidth
    implicitHeight: player.implicitHeight
    visible: false

    IpcHandler {
        target: "player"
        function toggle() {
            root.visible = !root.visible
        }
    }

    PlayerWidget {
        id: player
        anchors.fill: parent
    }
}
