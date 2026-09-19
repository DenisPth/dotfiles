import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.Mpris

// "Now playing" card, toggled from waybar's mpris click (`qs ipc call
// player toggle`). Modeled on ilyamiro/serpantinum's MusicPopup — cover
// art, seek bar, transport — minus its cava-reactive ring around the art
// and its 10-band parametric EQ mixer, which are a separate, much bigger
// feature (live audio analysis + a pipewire EQ backend) than "what the
// player looks like".
FloatingWindow {
    id: root

    title: "player-popup"
    color: "transparent"
    implicitWidth: card.implicitWidth
    implicitHeight: card.implicitHeight
    visible: false

    IpcHandler {
        target: "player"
        function toggle() {
            root.visible = !root.visible
        }
    }

    // playerctld mirrors whichever player is active, so it's skipped
    // rather than shown as a second, redundant entry (see Mpris.qml).
    readonly property var players: Mpris.players.values.filter(p => p.dbusName !== "org.mpris.MediaPlayer2.playerctld")
    readonly property var player: players.find(p => p.isPlaying) || players[0] || null
    readonly property bool active: player !== null

    // MprisPlayer.position doesn't notify on every tick, so poll it once a
    // second while the popup is open rather than freezing the seek bar.
    property real displayPosition: player ? player.position : 0
    onPlayerChanged: displayPosition = player ? player.position : 0
    Timer {
        interval: 1000
        repeat: true
        triggeredOnStart: true
        running: root.visible && root.active
        onTriggered: if (!seek.pressed) root.displayPosition = root.player.position
    }

    function formatTime(sec) {
        sec = Math.max(0, Math.floor(sec || 0))
        const m = Math.floor(sec / 60), s = sec % 60
        return m + ":" + (s < 10 ? "0" : "") + s
    }

    WrapperRectangle {
        id: card
        color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.92)
        radius: Theme.radius
        border.width: 1
        border.color: Theme.border
        leftMargin: 18
        rightMargin: 18
        topMargin: 16
        bottomMargin: 16

        focus: true
        Keys.onEscapePressed: root.visible = false

        Item {
            id: body
            implicitWidth: 300
            implicitHeight: content.implicitHeight

            ColumnLayout {
            id: content
            anchors.fill: parent
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
                spacing: 14

                ClippingRectangle {
                    id: cover
                    Layout.preferredWidth: 84
                    Layout.preferredHeight: 84
                    radius: 14
                    color: Theme.track
                    border.width: root.active && root.player.isPlaying ? 2 : 0
                    border.color: Theme.accent

                    Behavior on border.width {
                        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                    }

                    Image {
                        id: art
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: status === Image.Ready
                        source: {
                            if (!root.active || !root.player.trackArtUrl) return ""
                            const u = root.player.trackArtUrl
                            return /^[a-z][a-z0-9+.-]*:\/\//i.test(u) ? u : "file://" + u
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "♫"
                        color: Theme.fg
                        opacity: 0.4
                        font.pixelSize: 30
                        visible: art.status !== Image.Ready
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Item {
                        id: titleClip
                        Layout.fillWidth: true
                        Layout.preferredHeight: titleText.implicitHeight
                        clip: true

                        property int gap: 40
                        property bool overflow: titleText.implicitWidth > titleClip.width

                        Row {
                            id: marquee
                            spacing: titleClip.gap

                            Text {
                                id: titleText
                                text: root.active ? (root.player.trackTitle || root.player.identity) : "Музыка не играет"
                                color: root.active ? Theme.warm : Theme.fg
                                font.bold: true
                                font.pixelSize: Theme.fontSize
                                font.family: Theme.fontFamily
                            }

                            Text {
                                text: titleText.text
                                color: root.active ? Theme.warm : Theme.fg
                                font.bold: true
                                font.pixelSize: Theme.fontSize
                                font.family: Theme.fontFamily
                                visible: titleClip.overflow
                            }
                        }

                        SequentialAnimation on x {
                            id: marqueeAnim
                            loops: Animation.Infinite
                            running: root.visible && titleClip.overflow
                            PauseAnimation { duration: 2000 }
                            NumberAnimation {
                                from: 0
                                to: -(titleText.implicitWidth + titleClip.gap)
                                duration: (titleText.implicitWidth + titleClip.gap) * 20
                            }
                            PropertyAction { target: marquee; property: "x"; value: 0 }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: root.active ? root.player.trackArtist : ""
                        color: Theme.fg
                        opacity: 0.6
                        font.pixelSize: Theme.smallFontSize
                        font.family: Theme.fontFamily
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: root.active ? (root.player.identity || "") : ""
                        color: Theme.fg
                        opacity: 0.35
                        font.pixelSize: Theme.smallFontSize - 1
                        font.family: Theme.fontFamily
                        elide: Text.ElideRight
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                // Always present, just disabled/dimmed when there's nothing to
                // seek — a pinned_to_screen popup doesn't renegotiate its size
                // with the compositor after it's first mapped, so toggling
                // this row's *visibility* on track-change would leave the
                // window too short and clip the buttons below it.
                readonly property bool seekable: root.active && root.player.lengthSupported && root.player.length > 0
                opacity: seekable ? 1 : 0.35

                ThinSlider {
                    id: seek
                    Layout.fillWidth: true
                    implicitHeight: 16
                    enabled: parent.seekable && root.player.canSeek
                    from: 0
                    to: root.active && root.player.length > 0 ? root.player.length : 1

                    Binding on value {
                        value: root.displayPosition
                        when: !seek.pressed
                    }

                    onPressedChanged: {
                        if (!pressed && root.active && root.player.canSeek) {
                            root.player.position = seek.value
                            root.displayPosition = seek.value
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: root.formatTime(seek.value)
                        color: Theme.fg
                        opacity: 0.6
                        font.pixelSize: Theme.smallFontSize
                        font.family: Theme.fontFamily
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: root.active ? root.formatTime(root.player.length) : "0:00"
                        color: Theme.fg
                        opacity: 0.6
                        font.pixelSize: Theme.smallFontSize
                        font.family: Theme.fontFamily
                    }
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 10

                FlatButton {
                    text: "⇄"
                    fontSize: 15
                    padX: 8
                    padY: 8
                    visible: root.active && root.player.shuffleSupported
                    highlighted: root.active && root.player.shuffle
                    enabled: root.active && root.player.canControl
                    textOpacity: highlighted ? 1 : 0.4
                    onClicked: if (root.active) root.player.shuffle = !root.player.shuffle
                }

                FlatButton {
                    text: "⏮"
                    fontSize: 20
                    padX: 10
                    padY: 8
                    enabled: root.active && root.player.canGoPrevious
                    textOpacity: enabled ? 1 : 0.3
                    onClicked: if (root.active) root.player.previous()
                }

                FlatButton {
                    text: root.active && root.player.isPlaying ? "⏸" : "⏵"
                    fontSize: 26
                    padX: 14
                    padY: 8
                    highlighted: true
                    enabled: root.active && root.player.canTogglePlaying
                    textOpacity: enabled ? 1 : 0.3
                    onClicked: if (root.active) root.player.togglePlaying()
                }

                FlatButton {
                    text: "⏭"
                    fontSize: 20
                    padX: 10
                    padY: 8
                    enabled: root.active && root.player.canGoNext
                    textOpacity: enabled ? 1 : 0.3
                    onClicked: if (root.active) root.player.next()
                }

                FlatButton {
                    text: root.active && root.player.loopState === MprisLoopState.Track ? "↻¹" : "↻"
                    fontSize: 15
                    padX: 8
                    padY: 8
                    visible: root.active && root.player.loopSupported
                    highlighted: root.active && root.player.loopState !== MprisLoopState.None
                    enabled: root.active && root.player.canControl
                    textOpacity: highlighted ? 1 : 0.4
                    onClicked: {
                        if (!root.active) return
                        const s = MprisLoopState
                        root.player.loopState = root.player.loopState === s.None ? s.Playlist
                            : root.player.loopState === s.Playlist ? s.Track : s.None
                    }
                }
            }
            }
        }
    }
}
