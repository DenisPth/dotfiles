import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

// Блокнот на рабочем столе. Текст живёт в notes.txt рядом с остальным
// quickshell-конфигом (см. .gitignore — сам файл с заметками не в репо).
// Рисование — черкалка поверх того же поля, не сохраняется на диск (сугубо
// разово: набросать схему, стереть, забыть).
Item {
    id: root

    property bool drawMode: false

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

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 6

            Text {
                text: "заметки"
                color: Theme.fg
                opacity: Theme.dim
                font.pixelSize: Theme.smallFontSize
                font.family: Theme.fontFamily
            }

            FlatButton {
                text: root.drawMode ? "текст" : "рисовать"
                fontSize: Theme.smallFontSize
                padX: 6
                padY: 2
                onClicked: root.drawMode = !root.drawMode
            }

            FlatButton {
                visible: root.drawMode
                text: "стереть"
                fontSize: Theme.smallFontSize
                padX: 6
                padY: 2
                onClicked: {
                    canvas.strokes = []
                    canvas.requestPaint()
                }
            }
        }

        Rectangle {
            Layout.preferredWidth: 220
            Layout.preferredHeight: 90
            radius: 6
            color: Theme.track
            clip: true
            visible: !root.drawMode

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

        Rectangle {
            Layout.preferredWidth: 220
            Layout.preferredHeight: 90
            radius: 6
            color: Theme.track
            clip: true
            visible: root.drawMode

            Canvas {
                id: canvas
                anchors.fill: parent
                property var strokes: []
                property var current: null

                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()
                    ctx.strokeStyle = Theme.fg
                    ctx.lineWidth = 2
                    ctx.lineCap = "round"
                    ctx.lineJoin = "round"
                    for (const stroke of strokes) {
                        if (stroke.length < 2) continue
                        ctx.beginPath()
                        ctx.moveTo(stroke[0].x, stroke[0].y)
                        for (let i = 1; i < stroke.length; i++) ctx.lineTo(stroke[i].x, stroke[i].y)
                        ctx.stroke()
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onPressed: (mouse) => {
                        canvas.current = [{ x: mouse.x, y: mouse.y }]
                        canvas.strokes.push(canvas.current)
                    }
                    onPositionChanged: (mouse) => {
                        if (!canvas.current) return
                        canvas.current.push({ x: mouse.x, y: mouse.y })
                        canvas.requestPaint()
                    }
                    onReleased: canvas.current = null
                }
            }
        }
    }
}
