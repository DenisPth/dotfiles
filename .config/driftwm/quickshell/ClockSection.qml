import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Writes clock_format.txt ("24" or "12"); Clock.qml's FileView watches it
// and re-renders the dashboard clock immediately.
ColumnLayout {
    id: root
    spacing: 6

    property string format: "24"

    FileView {
        id: formatFile
        path: Quickshell.shellDir + "/clock_format.txt"
        printErrors: false
        onLoaded: {
            const v = text().trim()
            root.format = (v === "12") ? "12" : "24"
        }
        onLoadFailed: root.format = "24"
    }

    function setFormat(v) {
        root.format = v
        formatFile.setText(v)
    }

    Text {
        text: "время"
        color: Theme.fg
        opacity: Theme.dim
        font.pixelSize: Theme.smallFontSize
        font.family: Theme.fontFamily
    }

    RowLayout {
        Layout.topMargin: 4
        spacing: 6

        FlatButton {
            text: "24-часовой"
            highlighted: root.format === "24"
            onClicked: root.setFormat("24")
        }

        FlatButton {
            text: "12-часовой (AM/PM)"
            highlighted: root.format === "12"
            onClicked: root.setFormat("12")
        }
    }
}
