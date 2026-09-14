import QtQuick
import QtQuick.Layouts
import Quickshell

// A real xdg popup under `target`, so it can overhang the panel; grabFocus
// dismisses it on an outside click and lets a text field inside take the
// keyboard.
PopupWindow {
    id: root

    required property Item target
    property int padding: 12
    default property alias content: inner.data

    anchor.item: target
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: 6
    grabFocus: true
    color: "transparent"
    implicitWidth: inner.implicitWidth + 2 * padding + 2
    implicitHeight: inner.implicitHeight + 2 * padding + 2

    function toggle() {
        visible = !visible
    }

    onVisibleChanged: {
        if (visible) {
            if (Popups.current && Popups.current !== root) Popups.current.visible = false
            Popups.current = root
            enterAnim.restart()
        } else if (Popups.current === root) {
            Popups.current = null
        }
    }

    Rectangle {
        id: card
        anchors.fill: parent
        color: Theme.bg
        border.color: Theme.border
        border.width: 1
        radius: Theme.popupRadius
        transformOrigin: Item.Top

        // Quick pop-in on open; closing is instant (the xdg-popup surface
        // itself is gone the moment `visible` flips, nothing left to animate).
        ParallelAnimation {
            id: enterAnim
            NumberAnimation { target: card; property: "opacity"; from: 0; to: 1; duration: 140; easing.type: Easing.OutCubic }
            NumberAnimation { target: card; property: "scale"; from: 0.94; to: 1; duration: 140; easing.type: Easing.OutCubic }
        }

        ColumnLayout {
            id: inner
            x: root.padding + 1
            y: root.padding + 1
            width: parent.width - 2 * root.padding - 2
            spacing: 6
        }
    }
}
