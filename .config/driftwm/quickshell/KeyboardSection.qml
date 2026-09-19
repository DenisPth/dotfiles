import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

// config.toml sets layout = "us,ru" with alt+shift as the toggle; this
// surfaces the current one, offers the same switch as a click, and can
// append a new xkb layout code to that list (edits [input.keyboard].layout
// in config.toml directly, then reload-config — same pattern
// AppearanceSection uses for wallpapers).
ColumnLayout {
    id: root
    spacing: 6

    property string layout: "—"
    property var configured: []

    Component.onCompleted: if (visible) refresh()
    onVisibleChanged: if (visible) refresh()

    function refresh() {
        query.running = true
        list.running = true
    }

    Process {
        id: query
        command: ["driftwm", "msg", "layout"]
        stdout: StdioCollector {
            onStreamFinished: root.layout = text.trim()
        }
    }

    Process {
        id: list
        command: ["sh", "-c", "grep '^layout = ' ~/.config/driftwm/config.toml | head -n1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.match(/layout = "([^"]*)"/)
                root.configured = m ? m[1].split(",").map(s => s.trim()).filter(s => s) : []
            }
        }
    }

    Process {
        id: switcher
        command: ["driftwm", "msg", "action", "switch-layout", "next"]
        onExited: query.running = true
    }

    Process { id: rewrite }

    function addLayout(code) {
        code = code.trim().toLowerCase()
        if (!/^[a-z]+$/.test(code) || root.configured.includes(code)) return
        const next = [...root.configured, code].join(",")
        rewrite.command = ["sh", "-c",
            `sed -i 's|^layout = ".*"|layout = "${next}"|' ~/.config/driftwm/config.toml && driftwm msg action reload-config`]
        rewrite.running = true
        field.text = ""
        // config.toml's own write settles a beat before driftwm reloads it.
        refreshTimer.start()
    }

    Timer {
        id: refreshTimer
        interval: 300
        onTriggered: root.refresh()
    }

    Text {
        text: "раскладка клавиатуры"
        color: Theme.fg
        opacity: Theme.dim
        font.pixelSize: Theme.smallFontSize
        font.family: Theme.fontFamily
    }

    Text {
        text: root.layout
        color: Theme.fg
        font.pixelSize: Theme.fontSize
        font.family: Theme.fontFamily
    }

    RowLayout {
        Layout.topMargin: 4
        spacing: 6

        FlatButton {
            text: "переключить"
            onClicked: switcher.running = true
        }

        Text {
            text: "или alt+shift"
            color: Theme.fg
            opacity: Theme.dim
            font.pixelSize: Theme.smallFontSize
            font.family: Theme.fontFamily
        }
    }

    Text {
        Layout.topMargin: 10
        text: "настроенные раскладки: " + (root.configured.join(", ") || "—")
        color: Theme.fg
        opacity: Theme.dim
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        font.pixelSize: Theme.smallFontSize
        font.family: Theme.fontFamily
    }

    RowLayout {
        spacing: 6

        TextField {
            id: field
            Layout.preferredWidth: 100
            placeholderText: "код, напр. de"
            placeholderTextColor: Theme.border
            color: Theme.fg
            font.pixelSize: Theme.fontSize
            font.family: Theme.fontFamily
            background: Rectangle { color: Theme.track; radius: 8 }
            onAccepted: root.addLayout(text)
        }

        FlatButton {
            text: "добавить"
            onClicked: root.addLayout(field.text)
        }
    }
}
