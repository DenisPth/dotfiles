import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth

// Same Quickshell.Bluetooth backend as Bluetooth.qml's popover — that's a
// shared service, not a per-widget poll, so there's nothing to duplicate here
// beyond the list UI itself.
ColumnLayout {
    id: root
    spacing: 6

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var devices: adapter
        ? [...adapter.devices.values]
            .filter(device => device.paired || device.connected || !/^([0-9A-F]{2}-){5}[0-9A-F]{2}$/i.test(device.name))
            .sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name))
        : []
    property var justPaired: null

    function tap(device) {
        if (device.connected) {
            device.disconnect()
        } else if (device.paired) {
            device.connect()
        } else {
            justPaired = device
            device.pair()
        }
    }

    function detail(device) {
        if (device.pairing) return "pairing…"
        if (device.state === BluetoothDeviceState.Connecting) return "connecting…"
        if (device.connected) return device.batteryAvailable ? `connected · ${Math.round(device.battery * 100)}%` : "connected"
        return device.paired ? "paired" : ""
    }

    Connections {
        target: root.justPaired
        function onPairedChanged() {
            const device = root.justPaired
            if (!device.paired) return
            root.justPaired = null
            device.trusted = true
            device.connect()
        }
    }

    Binding {
        target: root.adapter
        property: "discovering"
        value: root.visible && root.adapter !== null && root.adapter.enabled
        when: root.adapter !== null
        restoreMode: Binding.RestoreNone
    }

    RowLayout {
        Layout.fillWidth: true

        Text {
            Layout.fillWidth: true
            text: "bluetooth"
            color: Theme.fg
            font.pixelSize: Theme.fontSize
            font.bold: true
            font.family: Theme.fontFamily
        }

        FlatButton {
            text: root.adapter && root.adapter.enabled ? "on" : "off"
            onClicked: root.adapter.enabled = !root.adapter.enabled
        }
    }

    ListView {
        Layout.fillWidth: true
        Layout.preferredHeight: 280
        clip: true
        model: root.devices

        delegate: ListRow {
            id: entry
            required property var modelData
            width: ListView.view.width
            text: entry.modelData.name
            highlighted: entry.modelData.connected
            detail: root.detail(entry.modelData)
            action: entry.modelData.paired ? "forget" : ""
            onClicked: root.tap(entry.modelData)
            onActionClicked: entry.modelData.forget()
        }
    }

    Text {
        visible: root.devices.length === 0
        text: root.adapter && root.adapter.enabled ? "сканируем…" : "bluetooth выключен"
        color: Theme.fg
        opacity: Theme.dim
        font.pixelSize: Theme.fontSize
        font.family: Theme.fontFamily
    }
}
