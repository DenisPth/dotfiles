import QtQuick
import QtQuick.Layouts
import Quickshell.Io

// Read-only view of driftwm's [keybindings] table (config.toml stays the
// source of truth — this just makes them browsable without a text editor,
// GNOME Settings' "Keyboard Shortcuts" panel style).
ColumnLayout {
    id: root
    spacing: 6

    property var binds: []

    Component.onCompleted: if (visible) query.running = true
    onVisibleChanged: if (visible) query.running = true

    Process {
        id: query
        command: ["sh", "-c", "sed -n '/^\\[keybindings\\]/,/^\\[/p' ~/.config/driftwm/config.toml"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = []
                for (const line of text.split("\n")) {
                    const m = line.match(/^"([^"]+)"\s*=\s*"([^"]+)"/)
                    if (m) out.push({ key: m[1], action: m[2] })
                }
                root.binds = out
            }
        }
    }

    Text {
        text: "сочетания клавиш driftwm"
        color: Theme.fg
        opacity: Theme.dim
        font.pixelSize: Theme.smallFontSize
        font.family: Theme.fontFamily
    }

    Text {
        Layout.bottomMargin: 4
        text: "определены в config.toml — здесь только просмотр"
        color: Theme.fg
        opacity: Theme.dim
        font.pixelSize: Theme.smallFontSize
        font.family: Theme.fontFamily
    }

    Flickable {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        contentWidth: width
        contentHeight: list.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: list
            width: parent.width
            spacing: 2

            Repeater {
                model: root.binds

                RowLayout {
                    id: row
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        Layout.preferredWidth: keyText.implicitWidth + 16
                        Layout.preferredHeight: 24
                        radius: 6
                        color: Theme.bg

                        Text {
                            id: keyText
                            anchors.centerIn: parent
                            text: row.modelData.key
                            color: Theme.fg
                            font.pixelSize: Theme.smallFontSize
                            font.family: Theme.fontFamily
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: row.modelData.action
                        color: Theme.fg
                        opacity: Theme.dim
                        elide: Text.ElideRight
                        font.pixelSize: Theme.smallFontSize
                        font.family: Theme.fontFamily
                    }
                }
            }
        }
    }
}
