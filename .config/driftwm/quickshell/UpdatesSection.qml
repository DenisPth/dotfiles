import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Two independent blocks: dotfiles git status (read-only — never pulls or
// pushes, this repo is local-only, see its README) and distro package
// updates (Arch/Fedora, matching install.sh's distro detection). The distro
// block only checks — the actual upgrade needs a password, so "обновить"
// just opens a terminal with the right command rather than trying to run
// sudo from inside quickshell.
ColumnLayout {
    id: root
    spacing: 6

    property string status: "…"
    property bool checking: false
    property bool canPull: false
    property bool pulling: false
    readonly property string repo: Quickshell.env("HOME") + "/dotfiles"

    property string distro: ""
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
            text: root.pulling ? "тяну…" : "подтянуть (git pull)"
            visible: root.canPull
            onClicked: {
                root.pulling = true
                pull.running = true
            }
        }
    }

    Process {
        id: pull
        // --ff-only: applies only when it's a clean fast-forward (canPull
        // already guarantees that) — never merges, never touches local
        // commits, so there's nothing here that could clash with edits.
        command: ["git", "-C", root.repo, "pull", "--ff-only"]
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
        distroDetect.running = true
    }

    Process {
        id: distroDetect
        command: ["sh", "-c", ". /etc/os-release; echo \"$ID $ID_LIKE\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const ids = text.trim().toLowerCase()
                root.distro = ids.includes("fedora") ? "fedora" : ids.includes("arch") ? "arch" : ""
                if (root.distro) {
                    pkgCount.running = true
                } else {
                    root.pkgChecking = false
                    root.pkgStatus = "неизвестный дистрибутив"
                }
            }
        }
    }

    Process {
        id: pkgCount
        command: ["sh", "-c",
            root.distro === "fedora"
                ? "dnf check-update -q 2>/dev/null | grep -c ."
                : "(checkupdates 2>/dev/null || yay -Qu 2>/dev/null) | grep -c ."]
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
        const cmd = root.distro === "fedora" ? "sudo dnf upgrade" : "yay -Syu"
        upgradeTerminal.command = ["ghostty", "-e", "sh", "-c", `${cmd}; exec $SHELL`]
        upgradeTerminal.running = true
    }
}
