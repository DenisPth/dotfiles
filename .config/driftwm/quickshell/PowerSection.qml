import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Services.UPower

// Brightness: same sysfs read/brightnessctl write as Brightness.qml, simpler
// (no optimistic batching — this window isn't dragged as often as the
// dashboard tile). Battery/power profiles: same UPower backend as
// Battery.qml's popover.
ColumnLayout {
    id: root
    spacing: 6

    property string backlight: ""
    property int maximum: 0
    property int current: 0
    readonly property bool present: backlight !== "" && maximum > 0

    readonly property var device: UPower.displayDevice
    readonly property bool batteryPresent: device !== null && device.isPresent

    function span(seconds) {
        const minutes = Math.round(seconds / 60)
        const h = Math.floor(minutes / 60)
        const m = minutes % 60
        return h > 0 ? `${h}h ${m}m` : `${m}m`
    }

    function status() {
        if (!batteryPresent) return ""
        switch (device.state) {
        case UPowerDeviceState.Charging:
            return device.timeToFull > 0 ? `заряжается, ещё ${span(device.timeToFull)}` : "заряжается"
        case UPowerDeviceState.Discharging:
            return device.timeToEmpty > 0 ? `разряжается, осталось ${span(device.timeToEmpty)}` : "разряжается"
        case UPowerDeviceState.FullyCharged:
            return "заряжена полностью"
        case UPowerDeviceState.PendingCharge:
            return "подключена, не заряжается"
        default:
            return UPowerDeviceState.toString(device.state).toLowerCase()
        }
    }

    Process {
        command: ["sh", "-c", "ls /sys/class/backlight | head -n1"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const name = text.trim()
                if (name) root.backlight = `/sys/class/backlight/${name}`
            }
        }
    }

    FileView {
        path: root.backlight ? `${root.backlight}/max_brightness` : ""
        onLoaded: root.maximum = Number(text().trim())
    }

    FileView {
        id: level
        path: root.backlight ? `${root.backlight}/brightness` : ""
        onLoaded: root.current = Number(text().trim())
    }

    Timer {
        interval: 3000
        running: root.present && root.visible
        repeat: true
        onTriggered: level.reload()
    }

    Process {
        id: writer
        onExited: level.reload()
    }

    Text {
        text: "яркость"
        color: Theme.fg
        opacity: Theme.dim
        font.pixelSize: Theme.smallFontSize
        font.family: Theme.fontFamily
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        ThinSlider {
            id: slider
            Layout.fillWidth: true
            from: 1
            to: 100
            stepSize: 1
            onMoved: writer.command = ["brightnessctl", "-q", "set", `${Math.round(value)}%`]
            onPressedChanged: if (!pressed) writer.running = true
        }

        Binding {
            target: slider
            property: "value"
            value: root.present ? root.current / root.maximum * 100 : 0
            when: !slider.pressed
            restoreMode: Binding.RestoreNone
        }

        Text {
            Layout.preferredWidth: 36
            horizontalAlignment: Text.AlignRight
            text: root.present ? `${Math.round(slider.value)}%` : "—"
            color: Theme.fg
            font.pixelSize: Theme.fontSize
            font.family: Theme.fontFamily
        }
    }

    Text {
        Layout.topMargin: 8
        visible: root.batteryPresent
        text: `батарея ${Math.round(root.device.percentage * 100)}% · ${root.status()}`
        color: Theme.fg
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        font.pixelSize: Theme.fontSize
        font.family: Theme.fontFamily
    }

    Text {
        visible: root.batteryPresent && root.device.healthSupported
        text: `здоровье ${Math.round(root.device.healthPercentage)}%`
        color: Theme.fg
        opacity: Theme.dim
        font.pixelSize: Theme.smallFontSize
        font.family: Theme.fontFamily
    }

    Text {
        Layout.topMargin: 8
        text: "профиль питания"
        color: Theme.fg
        opacity: Theme.dim
        font.pixelSize: Theme.smallFontSize
        font.family: Theme.fontFamily
    }

    RowLayout {
        spacing: 4

        Repeater {
            model: [
                { label: "экономия", profile: PowerProfile.PowerSaver, available: true },
                { label: "баланс", profile: PowerProfile.Balanced, available: true },
                { label: "производительность", profile: PowerProfile.Performance, available: PowerProfiles.hasPerformanceProfile },
            ]

            FlatButton {
                required property var modelData
                visible: modelData.available
                text: modelData.label
                highlighted: PowerProfiles.profile === modelData.profile
                onClicked: PowerProfiles.profile = modelData.profile
            }
        }
    }
}
