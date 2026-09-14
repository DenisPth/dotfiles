import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Read-only: fetches origin and reports how far local is from it. Never
// pulls or pushes — this repo is local-only, see its README.
ColumnLayout {
    id: root
    spacing: 6

    property string status: "…"
    property bool checking: false
    readonly property string repo: Quickshell.env("HOME") + "/dotfiles"

    onVisibleChanged: if (visible) check()

    function check() {
        root.checking = true
        fetch.running = true
    }

    Process {
        id: fetch
        command: ["git", "-C", root.repo, "fetch", "--quiet"]
        onExited: count.running = true
    }

    Process {
        id: count
        command: ["git", "-C", root.repo, "rev-list", "--left-right", "--count", "origin/main...HEAD"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.checking = false
                const parts = text.trim().split(/\s+/).map(Number)
                if (parts.length !== 2 || parts.some(isNaN)) {
                    root.status = "не удалось проверить"
                    return
                }
                const [behind, ahead] = parts
                if (behind === 0 && ahead === 0) root.status = "актуально"
                else if (behind > 0 && ahead === 0) root.status = `отстаёт на ${behind} коммит(ов) от origin`
                else if (behind === 0 && ahead > 0) root.status = `на ${ahead} коммит(ов) впереди origin (не запушено)`
                else root.status = `разошлись: +${ahead}/-${behind} от origin`
            }
        }
    }

    Text {
        text: "обновления dotfiles"
        color: Theme.fg
        opacity: Theme.dim
        font.pixelSize: Theme.smallFontSize
        font.family: Theme.fontFamily
    }

    Text {
        text: root.checking ? "проверяю…" : root.status
        color: Theme.fg
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        font.pixelSize: Theme.fontSize
        font.family: Theme.fontFamily
    }

    FlatButton {
        Layout.topMargin: 4
        text: "проверить снова"
        onClicked: root.check()
    }
}
