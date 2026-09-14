import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

// A real driftwm window (xdg-toplevel via FloatingWindow) shaped like GNOME
// Settings — grouped, searchable icon+label sidebar, one content panel at a
// time — rather than a canvas-pinned widget: it gets driftwm's own SSD title
// bar, moves, resizes, and isn't tied to the dashboard's position. Toggled by
// `qs ipc call settings toggle` (mod+s in config.toml) rather than a spawned
// process, since it's a window this same quickshell instance already owns.
//
// Wi-Fi/Bluetooth/Sound/Power reuse the same backends as the dashboard tiles
// (Bluetooth/Pipewire/UPower are Quickshell services, shared for free; Wi-Fi
// has no such service, so this section polls nmcli independently of
// Network.qml's tile — a simpler poll loop than the tile's, since this
// window is opened deliberately rather than always on screen).
FloatingWindow {
    id: root

    title: "Настройки"
    // Theme.bg at the same alpha foot/kitty use, so it frosts the same way
    // (the "drift-settings" window rule below sets blur = true).
    color: Qt.rgba(0.169, 0.196, 0.235, 0.85)
    visible: false
    implicitWidth: 820
    implicitHeight: 560
    minimumSize: Qt.size(680, 460)

    property string section: "wifi"
    property string filter: ""

    function matches(label) {
        return root.filter === "" || label.toLowerCase().includes(root.filter.toLowerCase())
    }

    readonly property var groups: [
        { label: "сеть", items: [
            { key: "wifi", label: "wi-fi", icon: "📶" },
            { key: "bluetooth", label: "bluetooth", icon: "🔷" },
        ] },
        { label: "устройства", items: [
            { key: "sound", label: "звук", icon: "🔊" },
            { key: "power", label: "питание", icon: "🔋" },
            { key: "display", label: "экран", icon: "🖥" },
            { key: "keyboard", label: "раскладка", icon: "⌨" },
        ] },
        { label: "персонализация", items: [
            { key: "appearance", label: "обои", icon: "🎨" },
        ] },
        { label: "система", items: [
            { key: "about", label: "о системе", icon: "ℹ" },
            { key: "updates", label: "обновления", icon: "🔄" },
        ] },
    ]

    IpcHandler {
        target: "settings"
        function toggle() {
            root.visible = !root.visible
        }
    }

    onVisibleChanged: if (visible) filter = ""

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 14

        TextField {
            id: search
            Layout.fillWidth: true
            placeholderText: "поиск"
            placeholderTextColor: Theme.border
            color: Theme.fg
            font.pixelSize: Theme.fontSize
            font.family: Theme.fontFamily
            background: Rectangle { color: Theme.track; radius: 8 }
            text: root.filter
            onTextChanged: root.filter = text
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 16

            ColumnLayout {
                Layout.preferredWidth: 190
                Layout.fillHeight: true
                spacing: 12

                Repeater {
                    model: root.groups

                    ColumnLayout {
                        id: group
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 2
                        visible: modelData.items.some(it => root.matches(it.label))

                        Text {
                            Layout.leftMargin: 10
                            Layout.topMargin: 4
                            text: group.modelData.label
                            color: Theme.fg
                            opacity: Theme.dim
                            font.pixelSize: Theme.smallFontSize
                            font.bold: true
                            font.family: Theme.fontFamily
                        }

                        Repeater {
                            model: group.modelData.items

                            SidebarItem {
                                required property var modelData
                                Layout.fillWidth: true
                                visible: root.matches(modelData.label)
                                text: modelData.label
                                icon: modelData.icon
                                highlighted: root.section === modelData.key
                                onClicked: root.section = modelData.key
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }

            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                color: Theme.border
            }

            ColumnLayout {
                id: content
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignTop
                spacing: 8

                WifiSection { Layout.fillWidth: true; visible: root.section === "wifi" }
                BluetoothSection { Layout.fillWidth: true; visible: root.section === "bluetooth" }
                SoundSection { Layout.fillWidth: true; visible: root.section === "sound" }
                PowerSection { Layout.fillWidth: true; visible: root.section === "power" }
                DisplaySection { Layout.fillWidth: true; visible: root.section === "display" }
                AppearanceSection { Layout.fillWidth: true; Layout.fillHeight: true; visible: root.section === "appearance" }
                KeyboardSection { Layout.fillWidth: true; visible: root.section === "keyboard" }
                AboutSection { Layout.fillWidth: true; visible: root.section === "about" }
                UpdatesSection { Layout.fillWidth: true; visible: root.section === "updates" }
            }
        }
    }
}
