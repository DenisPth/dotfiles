import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire

// Same Pipewire backend as Volume.qml's popover.
ColumnLayout {
    id: root
    spacing: 6

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property bool present: sink !== null && sink.audio !== null
    readonly property bool micPresent: source !== null && source.audio !== null
    readonly property var sinks: Pipewire.nodes.values.filter(node => node.isSink && !node.isStream && (node.type & PwNodeType.Audio))
    readonly property var sources: Pipewire.nodes.values.filter(node => !node.isSink && !node.isStream && (node.type & PwNodeType.Audio))

    function nodeName(node) {
        return node.description || node.nickname || node.name
    }

    PwObjectTracker {
        objects: [root.sink, root.source].filter(node => node !== null)
    }

    Text {
        text: "вывод"
        color: Theme.fg
        opacity: Theme.dim
        font.pixelSize: Theme.smallFontSize
        font.family: Theme.fontFamily
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        ThinSlider {
            id: slider
            Layout.fillWidth: true
            from: 0
            to: 1
            onMoved: if (root.present) root.sink.audio.volume = value
        }

        Binding {
            target: slider
            property: "value"
            value: root.present ? root.sink.audio.volume : 0
            when: !slider.pressed
            restoreMode: Binding.RestoreNone
        }

        Text {
            Layout.preferredWidth: 36
            horizontalAlignment: Text.AlignRight
            text: root.present ? `${Math.round(slider.value * 100)}%` : "—"
            color: Theme.fg
            font.pixelSize: Theme.fontSize
            font.family: Theme.fontFamily
        }

        FlatButton {
            text: root.present && root.sink.audio.muted ? "unmute" : "mute"
            onClicked: if (root.present) root.sink.audio.muted = !root.sink.audio.muted
        }
    }

    Repeater {
        model: root.sinks

        ListRow {
            required property var modelData
            Layout.fillWidth: true
            text: root.nodeName(modelData)
            highlighted: modelData === root.sink
            detail: modelData === root.sink ? "активно" : ""
            onClicked: Pipewire.preferredDefaultAudioSink = modelData
        }
    }

    Text {
        Layout.topMargin: 8
        text: "ввод"
        color: Theme.fg
        opacity: Theme.dim
        font.pixelSize: Theme.smallFontSize
        font.family: Theme.fontFamily
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        ThinSlider {
            id: micSlider
            Layout.fillWidth: true
            from: 0
            to: 1
            onMoved: if (root.micPresent) root.source.audio.volume = value
        }

        Binding {
            target: micSlider
            property: "value"
            value: root.micPresent ? root.source.audio.volume : 0
            when: !micSlider.pressed
            restoreMode: Binding.RestoreNone
        }

        Text {
            Layout.preferredWidth: 36
            horizontalAlignment: Text.AlignRight
            text: root.micPresent ? `${Math.round(micSlider.value * 100)}%` : "—"
            color: Theme.fg
            font.pixelSize: Theme.fontSize
            font.family: Theme.fontFamily
        }

        FlatButton {
            text: root.micPresent && root.source.audio.muted ? "unmute" : "mute"
            onClicked: if (root.micPresent) root.source.audio.muted = !root.source.audio.muted
        }
    }

    Repeater {
        model: root.sources

        ListRow {
            required property var modelData
            Layout.fillWidth: true
            text: root.nodeName(modelData)
            highlighted: modelData === root.source
            detail: modelData === root.source ? "активно" : ""
            onClicked: Pipewire.preferredDefaultAudioSource = modelData
        }
    }
}
