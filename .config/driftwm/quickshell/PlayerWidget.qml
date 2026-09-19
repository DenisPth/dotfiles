import QtQuick 6.0
import QtQuick.Layouts 6.0
import Quickshell.Widgets 0.1
import Quickshell.Services.Mpris 0.1

WrapperRectangle {
    id: root

    // Стилизация под тему (Glassmorphism) — из Theme.qml, чтобы менялась
    // вместе с обоями (см. apply_theme_colors.py) без правок этого файла.
    color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.75)        // Базовый тон с прозрачностью
    radius: 12                // Мягкое скругление углов
    border.color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.10) // Тонкий тёплый блик по контуру панели
    border.width: 1

    leftMargin: 10
    rightMargin: 10
    topMargin: 5
    bottomMargin: 5

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 15

        // Отображаем блок управления, только если есть запущенный плеер
        RowLayout {
            id: playerBlock
            Layout.fillWidth: true
            spacing: 15

            visible: Mpris.players.values.length > 0
            property var activePlayer: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null

            // Блок кнопок управления плеером
            RowLayout {
                spacing: 12

                // Назад (⏮)
                WrapperMouseArea {
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20
                    Text {
                        anchors.centerIn: parent
                        text: "⏮"
                        color: "#8a9a7c" // Мятно-зелёный акцент
                        font.pixelSize: 13
                    }
                    onClicked: if (playerBlock.activePlayer) playerBlock.activePlayer.previous()
                }

                // Play / Pause (▶ / ⏸)
                WrapperMouseArea {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    Text {
                        anchors.centerIn: parent
                        text: playerBlock.activePlayer && playerBlock.activePlayer.playbackState === MprisPlaybackState.Playing ? "⏸" : "▶"
                        color: Theme.accent // Акцентный цвет темы
                        font.pixelSize: 16
                    }
                    onClicked: if (playerBlock.activePlayer) playerBlock.activePlayer.toggle()
                }

                // Вперед (⏭)
                WrapperMouseArea {
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20
                    Text {
                        anchors.centerIn: parent
                        text: "⏭"
                        color: "#8a9a7c"
                        font.pixelSize: 13
                    }
                    onClicked: if (playerBlock.activePlayer) playerBlock.activePlayer.next()
                }
            }

            // Вертикальная разделительная черта внутри плеера
            Rectangle {
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.06)
            }

            // Информация о текущем треке
            Text {
                id: trackInfo
                text: playerBlock.activePlayer && playerBlock.activePlayer.trackTitle
                    ? (playerBlock.activePlayer.trackArtist ? playerBlock.activePlayer.trackArtist + " - " : "") + playerBlock.activePlayer.trackTitle
                    : "Музыка не играет"
                color: Theme.warm // Тёплый светлый акцент темы
                font.pixelSize: 13
                font.bold: true
                elide: Text.ElideRight // Обрезает длинный текст троеточием
                Layout.fillWidth: true
            }
        }

        // Заглушка на панели, если ни один плеер в системе не запущен
        Text {
            text: "Плеер не запущен"
            color: Theme.border // Приглушённый текст, сливающийся с обоями
            font.pixelSize: 13
            visible: Mpris.players.values.length === 0
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
