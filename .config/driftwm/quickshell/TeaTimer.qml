import QtQuick
import QtQuick.Layouts
import Quickshell

// Таймер проливов для гунфу-чаепития: белый чай / шу пуэр / шэн пуэр.
// Два режима: "вкус" — обычные проливы, текст про вкус; "крепко" — время
// пролива увеличено (сильнее экстракция), текст про эффект/ци вместо вкуса.
// Времена и заметки — ориентировочные, под классическую гунфу-схему; шу/шэн
// начинаются со споласкивающего пролива, который принято сливать.
Item {
    id: root

    readonly property real strongMultiplier: 1.7

    readonly property var teas: [
        {
            key: "white",
            name: "белый",
            steeps: [
                { time: 10, note: "лёгкий, цветочный", effect: "лёгкая бодрость, чистый ум" },
                { time: 15, note: "мягкая сладость", effect: "мягкое тепло, расслабление" },
                { time: 20, note: "мёд, пик цветочности", effect: "ровная бодрость без нервозности" },
                { time: 25, note: "полнее тело, абрикос", effect: "тело теплеет, спокойный фокус" },
                { time: 35, note: "мягкий, тёплая сладость", effect: "лёгкая эйфория, мягкое ци" },
                { time: 50, note: "лёгкая древесность, спокойствие", effect: "спокойствие, почти без стимуляции" },
                { time: 70, note: "тонкий, но сладкий", effect: "едва заметный эффект, умиротворение" },
                { time: 100, note: "почти прозрачный, мягкая энергия", effect: "почти нейтрально, лёгкость" },
            ],
        },
        {
            key: "shu",
            name: "шу пуэр",
            steeps: [
                { time: 5, note: "споласкивание — этот слить", effect: "споласкивание — этот слить" },
                { time: 8, note: "гладкий, землистый", effect: "тепло в теле, мягкое пищеварение" },
                { time: 10, note: "глубокая землистость, сладкое дерево", effect: "заземляющее тепло, спокойная бодрость" },
                { time: 12, note: "полное тело, какао, тепло", effect: "плотное тепло, сонное спокойствие" },
                { time: 15, note: "насыщенный, тёплое ци", effect: "сильное согревающее ци" },
                { time: 20, note: "мягкая землистая сладость", effect: "мягкое тепло держится долго" },
                { time: 30, note: "уютный, согревает, помогает пищеварению", effect: "глубокое спокойствие после еды" },
                { time: 45, note: "лёгкое послевкусие, расслабление", effect: "лёгкое тепло, сонное умиротворение" },
            ],
        },
        {
            key: "sheng",
            name: "шэн пуэр",
            steeps: [
                { time: 5, note: "споласкивание — этот слить", effect: "споласкивание — этот слить" },
                { time: 8, note: "травянистый, яркий, немного вяжет", effect: "лёгкая бодрость, чистота в голове" },
                { time: 10, note: "овощной, бодрит", effect: "заметная бодрость, слюноотделение" },
                { time: 12, note: "горько-сладкий, начинается хуэйгань", effect: "сильное ци, лёгкое давление в теле" },
                { time: 15, note: "цветочно-минеральный, сильное ци", effect: 'пик бодрости, "чайное опьянение"' },
                { time: 20, note: "слаще, мягче, долгий хуэйгань", effect: "энергия ровнее, приятная эйфория" },
                { time: 30, note: "мягкий, медовый, спокойная бодрость", effect: "спокойная бодрость, долгий хуэйгань" },
                { time: 45, note: "лёгкое сладкое послевкусие", effect: "лёгкий отголосок энергии, ясность" },
            ],
        },
    ]

    property int teaIndex: 0
    property int steepIndex: 0
    property bool strong: false
    readonly property var tea: teas[teaIndex]
    readonly property var steep: tea.steeps[Math.min(steepIndex, tea.steeps.length - 1)]
    readonly property int steepTime: strong ? Math.round(steep.time * strongMultiplier) : steep.time

    property int remaining: steepTime
    property bool running: false

    onSteepTimeChanged: {
        running = false
        remaining = steepTime
    }

    function fmt(s) {
        const m = Math.floor(s / 60)
        const sec = s % 60
        return m > 0 ? `${m}:${sec < 10 ? "0" : ""}${sec}` : `${sec}s`
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
            } else {
                root.remaining = 0
                root.running = false
                Quickshell.execDetached([
                    "notify-send", "-a", "чай",
                    "Пролив готов",
                    `${root.tea.name} · пролив ${root.steepIndex + 1}${root.strong ? " · крепко" : ""}`,
                ])
            }
        }
    }

    ColumnLayout {
        id: column
        spacing: 4

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "чай"
            color: Theme.fg
            opacity: Theme.dim
            font.pixelSize: Theme.smallFontSize
            font.family: Theme.fontFamily
        }

        RowLayout {
            spacing: 2
            Layout.alignment: Qt.AlignHCenter

            Repeater {
                model: root.teas

                delegate: FlatButton {
                    required property int index
                    required property var modelData
                    text: modelData.name
                    fontSize: Theme.smallFontSize
                    highlighted: root.teaIndex === index
                    onClicked: {
                        root.teaIndex = index
                        root.steepIndex = 0
                    }
                }
            }
        }

        RowLayout {
            spacing: 2
            Layout.alignment: Qt.AlignHCenter

            FlatButton {
                text: "вкус"
                fontSize: Theme.smallFontSize
                highlighted: !root.strong
                onClicked: root.strong = false
            }

            FlatButton {
                text: "крепко"
                fontSize: Theme.smallFontSize
                highlighted: root.strong
                onClicked: root.strong = true
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 8

            FlatButton {
                text: "‹"
                padX: 6
                onClicked: if (root.steepIndex > 0) root.steepIndex -= 1
            }

            Text {
                text: `пролив ${root.steepIndex + 1}/${root.tea.steeps.length}`
                color: Theme.fg
                font.pixelSize: Theme.smallFontSize
                font.family: Theme.fontFamily
            }

            FlatButton {
                text: "›"
                padX: 6
                onClicked: if (root.steepIndex < root.tea.steeps.length - 1) root.steepIndex += 1
            }
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
            Layout.preferredWidth: 220
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: root.strong ? root.steep.effect : root.steep.note
            color: Theme.fg
            opacity: Theme.dim
            font.pixelSize: Theme.smallFontSize
            font.family: Theme.fontFamily
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 6

            FlatButton {
                text: root.running ? "пауза" : (root.remaining === 0 ? "заново" : "старт")
                onClicked: {
                    if (root.remaining === 0) root.remaining = root.steepTime
                    root.running = !root.running
                }
            }

            FlatButton {
                text: "сброс"
                onClicked: {
                    root.running = false
                    root.remaining = root.steepTime
                }
            }
        }
    }
}
