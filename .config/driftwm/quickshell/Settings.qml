import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

// A GNOME-Settings-shaped window: sidebar of sections, one content panel at a
// time. Toggled by `qs ipc call settings toggle` (bound to mod+s in
// config.toml) rather than a spawned process, since it's a window this same
// quickshell instance already owns.
//
// Wi-Fi/Bluetooth/Sound/Power reuse the same backends as the dashboard tiles
// (Bluetooth/Pipewire/UPower are Quickshell services, shared for free; Wi-Fi
// has no such service, so this section polls nmcli independently of
// Network.qml's tile — a simpler poll loop than the tile's, since this
// window is opened deliberately rather than always on screen).
PanelWindow {
    id: root

    WlrLayershell.namespace: "drift-settings"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: false
    implicitWidth: 640
    implicitHeight: 480

    property string section: "wifi"
    readonly property var sections: [
        { key: "wifi", label: "wi-fi" },
        { key: "bluetooth", label: "bluetooth" },
        { key: "sound", label: "звук" },
        { key: "power", label: "питание" },
        { key: "display", label: "экран" },
        { key: "appearance", label: "обои" },
        { key: "keyboard", label: "раскладка" },
        { key: "about", label: "о системе" },
        { key: "updates", label: "обновления" },
    ]

    IpcHandler {
        target: "settings"
        function toggle() {
            root.visible = !root.visible
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.bg
        border.color: Theme.border
        border.width: 1
        radius: Theme.radius
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 16

        ColumnLayout {
            Layout.preferredWidth: 140
            Layout.fillHeight: true
            spacing: 2

            Repeater {
                model: root.sections

                SidebarItem {
                    required property var modelData
                    Layout.fillWidth: true
                    text: modelData.label
                    highlighted: root.section === modelData.key
                    onClicked: root.section = modelData.key
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
