import QtQuick
import QtQuick.Layouts
import Quickshell

// Ряд иконок для быстрого запуска. Символы — обычный Unicode (как ⏮/⏸/⏭ в
// Mpris.qml), а не PUA-глифы Nerd Font: у пропатченного шрифта не гарантирован
// полный набор брендовых иконок, а эти отрисуются всегда.
Item {
    id: root

    readonly property var apps: [
        { icon: "🌐", cmd: ["zen-browser"] },
        { icon: "⌨",  cmd: ["foot"] },
        { icon: "📁", cmd: ["thunar"] },
        { icon: "✈",  cmd: ["Telegram"] },
        { icon: "💬", cmd: ["vesktop"] },
        { icon: "📝", cmd: ["zeditor"] },
    ]

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 2

        Repeater {
            model: root.apps

            delegate: FlatButton {
                text: modelData.icon
                fontSize: 18
                padX: 8
                padY: 6
                onClicked: Quickshell.execDetached(modelData.cmd)
            }
        }
    }
}
