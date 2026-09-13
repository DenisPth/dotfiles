import QtQuick 6.0
import QtQuick.Layouts 6.0
import Quickshell.Widgets 0.1
import Quickshell.Services.Mpris 0.1

WrapperRectangle {
    id: root

    // Стилизация под dark_sea (Glassmorphism)
    color: "#2b323cc0"        // Базовый тон dark_sea с прозрачностью
    radius: 12                // Мягкое скругление углов
    border.color: "#c9c4ab1a" // Тонкий тёплый блик по контуру панели
    border.width: 1

    margin.left: 10
    margin.right: 10
    margin.top: 5
    margin.bottom: 5

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 15

        // Отображаем блок управления, только если есть запущенный плеер
        RowLayout {
            id: playerBlock
            Layout.fillWidth: true
            spacing: 15

            visible: Mpris.players.length > 0
            property var activePlayer: Mpris.players

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
                        text: playerBlock.activePlayer && playerBlock.activePlayer.playbackStatus === MprisStatus.Playing ? "⏸" : "▶"
                        color: "#7089a0" // Сине-серый акцент dark_sea
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
                color: "#c9c4ab10"
            }

            // Информация о текущем треке
            Text {
                id: trackInfo
                text: playerBlock.activePlayer && playerBlock.activePlayer.metadata["xf86:title"]
                    ? (playerBlock.activePlayer.metadata["xf86:artist"] ? playerBlock.activePlayer.metadata["xf86:artist"] + " - " : "") + playerBlock.activePlayer.metadata["xf86:title"]
                    : "Музыка не играет"
                color: "#e2ddc4" // Тёплый светлый — foam-color dark_sea
                font.pixelSize: 13
                font.bold: true
                elide: Text.ElideRight // Обрезает длинный текст троеточием
                Layout.fillWidth: true
            }
        }

        // Заглушка на панели, если ни один плеер в системе не запущен
        Text {
            text: "Плеер не запущен"
            color: "#4b5560" // Приглушённый серый текст, сливающийся с обоями
            font.pixelSize: 13
            visible: Mpris.players.length === 0
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
