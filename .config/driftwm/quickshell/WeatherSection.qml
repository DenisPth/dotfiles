import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

// Same weather_location.txt the dashboard tile (Weather.qml) reads — this
// just gives it a home in Settings too, for discoverability. Weather.qml's
// FileView watches the file, so saving here updates the tile immediately.
ColumnLayout {
    id: root
    spacing: 6

    property string current: ""

    FileView {
        id: locationFile
        path: Quickshell.shellDir + "/weather_location.txt"
        printErrors: false
        onLoaded: root.current = text().trim()
        onLoadFailed: root.current = ""
    }

    function save() {
        locationFile.setText(field.text.trim())
        root.current = field.text.trim()
    }

    Text {
        text: "погода"
        color: Theme.fg
        opacity: Theme.dim
        font.pixelSize: Theme.smallFontSize
        font.family: Theme.fontFamily
    }

    Text {
        text: root.current ? `сейчас: ${root.current}` : "определяется по IP (может ошибаться за VPN)"
        color: Theme.fg
        opacity: Theme.dim
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        font.pixelSize: Theme.smallFontSize
        font.family: Theme.fontFamily
    }

    RowLayout {
        Layout.topMargin: 4
        spacing: 6

        TextField {
            id: field
            Layout.preferredWidth: 160
            text: root.current
            placeholderText: "город (пусто — по IP)"
            placeholderTextColor: Theme.border
            color: Theme.fg
            font.pixelSize: Theme.fontSize
            font.family: Theme.fontFamily
            background: Rectangle { color: Theme.track; radius: 8 }
            onAccepted: root.save()
        }

        FlatButton {
            text: "сохранить"
            onClicked: root.save()
        }
    }
}
