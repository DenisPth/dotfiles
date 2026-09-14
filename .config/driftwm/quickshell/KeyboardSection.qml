import QtQuick
import QtQuick.Layouts
import Quickshell.Io

// config.toml sets layout = "us,ru" with alt+shift as the toggle; this just
// surfaces the current one and offers the same switch as a click.
ColumnLayout {
    id: root
    spacing: 6

    property string layout: "—"

    onVisibleChanged: if (visible) query.running = true

    Process {
        id: query
        command: ["driftwm", "msg", "layout"]
        stdout: StdioCollector {
            onStreamFinished: root.layout = text.trim()
        }
    }

    Process {
        id: switcher
        command: ["driftwm", "msg", "action", "switch-layout", "next"]
        onExited: query.running = true
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
}
