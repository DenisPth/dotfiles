import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

// Блокнот на рабочем столе. Текст живёт в notes.txt рядом с остальным
// quickshell-конфигом (см. .gitignore — сам файл с заметками не в репо).
Item {
    id: root

    implicitWidth: column.implicitWidth
    implicitHeight: column.implicitHeight

    FileView {
        id: file
        path: Quickshell.shellDir + "/notes.txt"
        printErrors: false
        onLoaded: area.text = text()
        onLoadFailed: area.text = ""
    }

    Timer {
        id: saveDebounce
        interval: 800
        onTriggered: file.setText(area.text)
    }

    ColumnLayout {
        id: column
        spacing: 4

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "заметки"
            color: Theme.fg
            opacity: Theme.dim
            font.pixelSize: Theme.smallFontSize
            font.family: Theme.fontFamily
        }

        Rectangle {
            Layout.preferredWidth: 220
            Layout.preferredHeight: 90
            radius: 6
            color: Theme.track

            ScrollView {
                anchors.fill: parent
                anchors.margins: 6
                clip: true

                TextArea {
                    id: area
                    wrapMode: TextArea.Wrap
                    color: Theme.fg
                    selectionColor: Theme.border
                    font.pixelSize: Theme.smallFontSize
                    font.family: Theme.fontFamily
                    background: null
                    onTextChanged: saveDebounce.restart()
                }
            }
        }
    }
}
