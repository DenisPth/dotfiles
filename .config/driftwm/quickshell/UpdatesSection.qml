import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Two independent blocks: dotfiles git status (synced via GitHub across
// machines now — see .zshrc's `dotfiles` command and update.sh) and Arch
// package updates. The package block only checks — the actual upgrade
// needs a password, so "обновить" just opens a terminal with the right
// command rather than trying to run sudo from inside quickshell.
ColumnLayout {
    id: root
    spacing: 6

    property string status: "…"
    property bool checking: false
    property bool canPull: false
    property bool pulling: false
    readonly property string repo: Quickshell.env("HOME") + "/dotfiles"

    property string pkgStatus: "…"
    property bool pkgChecking: false

    Component.onCompleted: if (visible) { check(); checkPackages() }
    onVisibleChanged: if (visible) { check(); checkPackages() }

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
                root.canPull = behind > 0 && ahead === 0
                if (behind === 0 && ahead === 0) root.status = "актуально"
                else if (behind > 0 && ahead === 0) root.status = `отстаёт на ${behind} коммит(ов) от origin`
                else if (behind === 0 && ahead > 0) root.status = `на ${ahead} коммит(ов) впереди origin (не запушено)`
                else root.status = `разошлись: +${ahead}/-${behind} от origin — обнови вручную`
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

    RowLayout {
        Layout.topMargin: 4
        spacing: 6

        FlatButton {
            text: "проверить снова"
            onClicked: root.check()
        }

        FlatButton {
            text: root.pulling ? "обновляю…" : "обновить (dotfiles update)"
            visible: root.canPull
            onClicked: {
                root.pulling = true
                pull.running = true
            }
        }
    }

    Process {
        id: pull
        // update.sh itself does `git pull --ff-only` (applies only on a
        // clean fast-forward — canPull already guarantees that, never
        // merges or touches local commits) and then relinks configs, so
        // this is the same thing the mod+s button and a shell's `dotfiles
        // update` both end up running.
        command: [root.repo + "/update.sh"]
        onExited: {
            root.pulling = false
            root.check()
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: 10
        Layout.bottomMargin: 4
        implicitHeight: 1
        color: Theme.border
    }

    Text {
        text: "системные пакеты"
        color: Theme.fg
        opacity: Theme.dim
        font.pixelSize: Theme.smallFontSize
        font.family: Theme.fontFamily
    }

    Text {
        text: root.pkgChecking ? "проверяю…" : root.pkgStatus
        color: Theme.fg
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        font.pixelSize: Theme.fontSize
        font.family: Theme.fontFamily
    }

    RowLayout {
        Layout.topMargin: 4
        spacing: 6

        FlatButton {
            text: "проверить снова"
            onClicked: root.checkPackages()
        }

        FlatButton {
            text: "обновить в терминале"
            onClicked: root.openUpgradeTerminal()
        }
    }

    function checkPackages() {
        root.pkgChecking = true
        pkgCount.running = true
    }

    Process {
        id: pkgCount
        // checkupdates (pacman-contrib) needs no root and doesn't touch the
        // local sync db; yay -Qu is the fallback if it's missing.
        command: ["sh", "-c", "(checkupdates 2>/dev/null || yay -Qu 2>/dev/null) | grep -c ."]
        stdout: StdioCollector {
            onStreamFinished: {
                root.pkgChecking = false
                const n = parseInt(text.trim(), 10)
                root.pkgStatus = (isNaN(n) || n === 0) ? "всё актуально" : `доступно обновлений: ${n}`
            }
        }
    }

    Process { id: upgradeTerminal }

    function openUpgradeTerminal() {
        upgradeTerminal.command = ["ghostty", "-e", "sh", "-c", "yay -Syu; exec $SHELL"]
        upgradeTerminal.running = true
    }
}
