import QtQuick
import QtQuick.Layouts
import Quickshell.Io

// Диск: занятость корня в тайле, все смонтированные разделы — в поповере.
Tile {
    id: root

    property var mounts: []

    label: "disk"
    value: "—"
    clickable: true
    onClicked: popover.toggle()

    function parse(text) {
        const rows = []
        for (const line of text.trim().split("\n")) {
            const parts = line.trim().split(/\s+/)
            if (parts.length < 2) continue
            rows.push({ pcent: parts[0], target: parts.slice(1).join(" ") })
        }
        root.mounts = rows
        const rootRow = rows.find(r => r.target === "/") || rows[0]
        root.value = rootRow ? rootRow.pcent : "—"
    }

    Process {
        id: df
        command: ["sh", "-c", "df -h -x tmpfs -x devtmpfs -x squashfs -x overlay -x efivarfs --output=pcent,target | tail -n +2"]
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: df.running = true
    }

    Popover {
        id: popover
        target: root

        ColumnLayout {
            spacing: 2

            Repeater {
                model: root.mounts

                RowLayout {
                    required property var modelData
                    spacing: 8

                    Text {
                        Layout.preferredWidth: 40
                        horizontalAlignment: Text.AlignRight
                        text: modelData.pcent
                        color: Theme.fg
                        font.pixelSize: Theme.fontSize
                        font.family: Theme.fontFamily
                    }

                    Text {
                        text: modelData.target
                        color: Theme.fg
                        opacity: Theme.dim
                        font.pixelSize: Theme.fontSize
                        font.family: Theme.fontFamily
                    }
                }
            }
        }
    }
}
