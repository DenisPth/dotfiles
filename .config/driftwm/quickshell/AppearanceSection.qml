import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Wallpapers are GLSL shaders under wallpapers/ (see driftwm/config.toml's
// [background] section). Picking one rewrites that section's `path = ` line
// and asks driftwm to reload — driftwm auto-backs-up config.toml on its own
// writes, so this doesn't need to (see .gitignore's *.bak* note).
ColumnLayout {
    id: root
    spacing: 6

    readonly property string base: Quickshell.env("HOME") + "/.config/driftwm/wallpapers"
    property var wallpapers: []
    property string active: ""

    onVisibleChanged: if (visible) {
        list.running = true
        current.running = true
    }

    function apply(rel) {
        rewrite.command = ["sh", "-c",
            `sed -i 's|^path = ".*"|path = "~/.config/driftwm/wallpapers/${rel}"|' ~/.config/driftwm/config.toml && driftwm msg action reload-config`]
        rewrite.running = true
        root.active = rel
    }

    Process {
        id: list
        command: ["sh", "-c", `find "${root.base}" -name '*.glsl' | sort`]
        stdout: StdioCollector {
            onStreamFinished: root.wallpapers = text.trim().split("\n").filter(l => l).map(p => p.slice(root.base.length + 1))
        }
    }

    Process {
        id: current
        command: ["sh", "-c", "grep '^path = ' ~/.config/driftwm/config.toml | head -n1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.match(/wallpapers\/(.+)\.glsl/)
                root.active = m ? `${m[1]}.glsl` : ""
            }
        }
    }

    Process { id: rewrite }

    Text {
        text: "обои (dark_sea.glsl и варианты)"
        color: Theme.fg
        opacity: Theme.dim
        font.pixelSize: Theme.smallFontSize
        font.family: Theme.fontFamily
    }

    ColumnLayout {
        spacing: 2

        Repeater {
            model: root.wallpapers

            ListRow {
                required property string modelData
                Layout.fillWidth: true
                text: modelData
                highlighted: modelData === root.active
                onClicked: root.apply(modelData)
            }
        }
    }
}
