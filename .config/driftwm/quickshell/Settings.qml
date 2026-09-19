import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

// A real driftwm window (xdg-toplevel via FloatingWindow) shaped like GNOME
// Settings — rather than a canvas-pinned widget: it gets driftwm's own SSD
// title bar, moves, resizes, and isn't tied to the dashboard's position.
// Toggled by `qs ipc call settings toggle` (mod+s in config.toml) rather
// than a spawned process, since it's a window this same quickshell instance
// already owns.
//
// Drill-down navigation: an empty `section` shows the searchable grouped
// list; picking one swaps to that section full-width with a back button,
// rather than a permanent side-by-side split.
//
// Wi-Fi/Bluetooth/Sound/Power reuse the same backends as the dashboard tiles
// (Bluetooth/Pipewire/UPower are Quickshell services, shared for free; Wi-Fi
// has no such service, so this section polls nmcli independently of
// Network.qml's tile — a simpler poll loop than the tile's, since this
// window is opened deliberately rather than always on screen).
FloatingWindow {
    id: root

    title: "Настройки"
    // Theme.bg at the same alpha ghostty/kitty use, so it frosts the same way
    // (the "drift-settings" window rule below sets blur = true).
    color: Qt.rgba(0.169, 0.196, 0.235, 0.85)
    visible: false
    implicitWidth: 820
    implicitHeight: 560
    minimumSize: Qt.size(680, 460)

    property string section: ""
    property string filter: ""

    function matches(label) {
        return root.filter === "" || label.toLowerCase().includes(root.filter.toLowerCase())
    }

    function currentItem() {
        for (const g of root.groups)
            for (const it of g.items)
                if (it.key === root.section) return it
        return null
    }

    // Keyed by section — the content Loader below instantiates only this
    // one component. Twelve statically-declared sections each toggling
    // `visible` used to all sit in the same ColumnLayout at once; the
    // eleven hidden ones still ate up `spacing`, leaving a stack of dead
    // space above whichever one was actually shown. A Loader only ever
    // creates the item it's asked for, so there are no hidden siblings left
    // to leave a gap.
    readonly property var sectionComponents: ({
        wifi: wifiComp, bluetooth: bluetoothComp, sound: soundComp, power: powerComp,
        display: displayComp, appearance: appearanceComp, clock: clockComp,
        weather: weatherComp, keyboard: keyboardComp, about: aboutComp,
        updates: updatesComp, keybinds: keybindsComp,
    })

    // The loaded item is a plain child of Loader, not a Layout child of
    // one, so it needs real anchors to get the Loader's width. Deliberately
    // NOT anchors.fill for most of these: pinning height too stretches the
    // ColumnLayout taller than its content, and with no child claiming
    // that slack via Layout.fillHeight, ColumnLayout spreads it out as
    // uniform gaps between every row instead of leaving it blank at the
    // bottom — anchoring top+left+right only keeps each section's natural
    // height. AppearanceSection and KeybindsSection are the exception:
    // they have their own internal scrolling area that's meant to claim
    // the leftover height, so they get the full anchors.fill.
    Component { id: wifiComp; WifiSection { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right } }
    Component { id: bluetoothComp; BluetoothSection { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right } }
    Component { id: soundComp; SoundSection { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right } }
    Component { id: powerComp; PowerSection { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right } }
    Component { id: displayComp; DisplaySection { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right } }
    Component { id: appearanceComp; AppearanceSection { anchors.fill: parent } }
    Component { id: clockComp; ClockSection { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right } }
    Component { id: weatherComp; WeatherSection { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right } }
    Component { id: keyboardComp; KeyboardSection { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right } }
    Component { id: aboutComp; AboutSection { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right } }
    Component { id: updatesComp; UpdatesSection { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right } }
    Component { id: keybindsComp; KeybindsSection { anchors.fill: parent } }

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
            { key: "clock", label: "время", icon: "🕐" },
            { key: "weather", label: "погода", icon: "⛅" },
        ] },
        { label: "система", items: [
            { key: "about", label: "о системе", icon: "ℹ" },
            { key: "updates", label: "обновления", icon: "🔄" },
            { key: "keybinds", label: "сочетания клавиш", icon: "⌘" },
        ] },
    ]

    IpcHandler {
        target: "settings"
        function toggle() {
            root.visible = !root.visible
            if (root.visible) root.section = ""
        }
        // Jumps straight to a section, e.g. `qs ipc call settings open wifi`.
        function open(key: string) {
            root.section = key
            root.visible = true
        }
    }

    onVisibleChanged: if (visible) filter = ""

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 14

        // ---------------------------------------------------- list view ---
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 14
            visible: root.section === ""

            TextField {
                id: search
                Layout.fillWidth: true
                implicitHeight: 40
                placeholderText: "поиск"
                placeholderTextColor: Theme.border
                color: Theme.fg
                font.pixelSize: Theme.fontSize
                font.family: Theme.fontFamily
                background: Rectangle { color: Theme.track; radius: 20 }
                leftPadding: 16
                text: root.filter
                onTextChanged: root.filter = text
            }

            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: width
                contentHeight: groupsColumn.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: groupsColumn
                    width: parent.width
                    spacing: 10

                    Repeater {
                        model: root.groups

                        // One rounded card per group — GNOME/libadwaita
                        // "boxed list" style grouping.
                        Rectangle {
                            id: card
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: cardColumn.implicitHeight + 16
                            radius: 16
                            color: Theme.track
                            visible: modelData.items.some(it => root.matches(it.label))

                            ColumnLayout {
                                id: cardColumn
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 2

                                Text {
                                    // Matches SidebarItem's own internal left inset (12px) below,
                                    // so the group label lines up with the row icons, not the pills.
                                    Layout.leftMargin: 12
                                    Layout.bottomMargin: 2
                                    text: card.modelData.label
                                    color: Theme.fg
                                    opacity: Theme.dim
                                    font.pixelSize: Theme.smallFontSize
                                    font.bold: true
                                    font.family: Theme.fontFamily
                                }

                                Repeater {
                                    model: card.modelData.items

                                    SidebarItem {
                                        required property var modelData
                                        Layout.fillWidth: true
                                        visible: root.matches(modelData.label)
                                        text: modelData.label
                                        icon: modelData.icon
                                        onClicked: root.section = modelData.key
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // -------------------------------------------------- detail view ---
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12
            visible: root.section !== ""

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                FlatButton {
                    text: "← назад"
                    onClicked: root.section = ""
                }

                Text {
                    readonly property var item: root.currentItem()
                    text: item ? `${item.icon}  ${item.label}` : ""
                    color: Theme.fg
                    font.bold: true
                    font.pixelSize: Theme.fontSize + 2
                    font.family: Theme.fontFamily
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 16
                color: Theme.track

                Loader {
                    anchors.fill: parent
                    anchors.margins: 18
                    // Reloads on every section change — each section's own
                    // Component.onCompleted already handles its initial
                    // fetch, so a fresh instance per visit is the right
                    // behavior here (not a cache to preserve).
                    sourceComponent: root.sectionComponents[root.section] || null
                }
            }
        }
    }
}
