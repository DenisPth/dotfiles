import QtQuick
import QtQuick.Layouts
import Quickshell.Io

// Single-monitor rice (see kanshi/config): wlr-randr sets the mode live,
// then kanshi's config is rewritten to the same mode so it survives a
// reconnect, and kanshi is told to reload.
ColumnLayout {
    id: root
    spacing: 6

    readonly property string output: "DP-1"
    property var modes: []
    property string current: ""

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
        const out = data.find(o => o.name === root.output)
        if (!out) return
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
        setter.command = ["wlr-randr", "--output", root.output, "--mode", `${m.width}x${m.height}@${m.refresh}Hz`]
        setter.running = true
        kanshiRewrite.command = ["sh", "-c",
            `sed -i 's/mode [0-9x@.]*/mode ${m.width}x${m.height}@${Math.round(m.refresh)}/' ~/.config/kanshi/config && kanshictl reload`]
        kanshiRewrite.running = true
    }

    Process {
        id: query
        command: ["wlr-randr", "--json"]
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }

    Process { id: setter }
    Process { id: kanshiRewrite }

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
