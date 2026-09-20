import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// wlr-randr sets the mode live, then set_output_mode.py writes the same
// mode into config.toml's [[outputs]] (matched by connector name) so it
// survives a driftwm restart — config.toml is the only place output modes
// are persisted (see the [[outputs]] comment in config.toml).
ColumnLayout {
    id: root
    spacing: 6

    // The enabled output — found live from wlr-randr's own list rather than
    // a fixed name, since that's "DP-1" on a desktop and "eDP-1" (or
    // something else entirely) on a laptop.
    property string output: ""
    property var modes: []
    property string current: ""
    readonly property string setModeScript: Quickshell.env("HOME") + "/.config/driftwm/scripts/set_output_mode.py"

    Component.onCompleted: if (visible) query.running = true
    onVisibleChanged: if (visible) query.running = true

    function label(m) {
        return `${m.width}×${m.height}@${Math.round(m.refresh)}`
    }

    function parse(text) {
        let data
        try {
            data = JSON.parse(text)
        } catch (e) {
            return
        }
        const out = data.find(o => o.enabled) || data[0]
        if (!out) return
        root.output = out.name
        const seen = new Set()
        const list = []
        for (const m of out.modes) {
            const key = `${m.width}x${m.height}@${Math.round(m.refresh)}`
            if (seen.has(key)) continue
            seen.add(key)
            list.push({ width: m.width, height: m.height, refresh: m.refresh, current: m.current })
        }
        root.modes = list
        const active = list.find(m => m.current)
        root.current = active ? root.label(active) : ""
    }

    function apply(m) {
        const mode = `${m.width}x${m.height}@${Math.round(m.refresh)}`
        setter.command = ["wlr-randr", "--output", root.output, "--mode", `${mode}Hz`]
        setter.running = true
        configWriter.command = [root.setModeScript, root.output, mode]
        configWriter.running = true
    }

    Process {
        id: query
        command: ["wlr-randr", "--json"]
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }

    Process { id: setter }
    Process { id: configWriter }

    Text {
        text: "разрешение и частота обновления"
        color: Theme.fg
        opacity: Theme.dim
        font.pixelSize: Theme.smallFontSize
        font.family: Theme.fontFamily
    }

    Text {
        text: `сейчас: ${root.current || "—"}`
        color: Theme.fg
        font.pixelSize: Theme.fontSize
        font.family: Theme.fontFamily
    }

    Flow {
        Layout.fillWidth: true
        Layout.topMargin: 4
        spacing: 4

        Repeater {
            model: root.modes

            FlatButton {
                required property var modelData
                text: root.label(modelData)
                fontSize: Theme.smallFontSize
                highlighted: modelData.current
                onClicked: root.apply(modelData)
            }
        }
    }
}
