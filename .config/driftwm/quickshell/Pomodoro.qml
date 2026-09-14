import QtQuick
import QtQuick.Layouts
import Quickshell

// Классическое помодоро: 25 мин работы / 5 мин перерыв, каждый 4-й —
// длинный (15 мин). Счётчик сессий живёт, пока не перезапустится quickshell.
Item {
    id: root

    readonly property int workMin: 25
    readonly property int shortBreakMin: 5
    readonly property int longBreakMin: 15
    readonly property int cyclesUntilLongBreak: 4

    property int phase: 0 // 0 = работа, 1 = перерыв
    property int completedWork: 0
    property bool running: false
    property int remaining: workMin * 60

    function isLongBreak() {
        return root.completedWork > 0 && root.completedWork % root.cyclesUntilLongBreak === 0
    }

    function phaseSeconds() {
        if (root.phase === 0) return root.workMin * 60
        return (root.isLongBreak() ? root.longBreakMin : root.shortBreakMin) * 60
    }

    function phaseLabel() {
        if (root.phase === 0) return "работа"
        return root.isLongBreak() ? "длинный перерыв" : "перерыв"
    }

    function advance() {
        if (root.phase === 0) {
            root.completedWork += 1
            root.phase = 1
        } else {
            root.phase = 0
        }
        root.remaining = root.phaseSeconds()
    }

    function fmt(s) {
        const m = Math.floor(s / 60)
        const sec = s % 60
        return `${m}:${sec < 10 ? "0" : ""}${sec}`
    }

    implicitWidth: column.implicitWidth
    implicitHeight: column.implicitHeight

    Timer {
        interval: 1000
        running: root.running
        repeat: true
        onTriggered: {
            if (root.remaining > 1) {
                root.remaining -= 1
                return
            }

            root.remaining = 0
            root.running = false
            const wasWork = root.phase === 0
            root.advance()

            Quickshell.execDetached([
                "notify-send", "-a", "помодоро",
                wasWork ? "Сессия закончена" : "Перерыв закончен",
                wasWork ? `${root.phaseLabel()} ${Math.round(root.phaseSeconds() / 60)} мин` : "пора работать",
            ])
        }
    }

    ColumnLayout {
        id: column
        spacing: 4

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "помодоро"
            color: Theme.fg
            opacity: Theme.dim
            font.pixelSize: Theme.smallFontSize
            font.family: Theme.fontFamily
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.phaseLabel()
            color: Theme.fg
            font.pixelSize: Theme.smallFontSize
            font.family: Theme.fontFamily
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.fmt(root.remaining)
            color: Theme.fg
            font.pixelSize: 32
            font.bold: true
            font.family: Theme.fontFamily
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: `сессии: ${root.completedWork}`
            color: Theme.fg
            opacity: Theme.dim
            font.pixelSize: Theme.smallFontSize
            font.family: Theme.fontFamily
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 6

            FlatButton {
                text: root.running ? "пауза" : "старт"
                onClicked: root.running = !root.running
            }

            FlatButton {
                text: "сброс"
                onClicked: {
                    root.running = false
                    root.phase = 0
                    root.completedWork = 0
                    root.remaining = root.phaseSeconds()
                }
            }

            FlatButton {
                text: "скип"
                onClicked: {
                    root.running = false
                    root.advance()
                }
            }
        }
    }
}
