import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Wallpapers are GLSL shaders under wallpapers/ (see driftwm/config.toml's
// [background] section) — nothing QtQuick can render directly, so the grid
// shows pre-baked thumbnails (scripts/gen_wallpaper_thumbs.sh: briefly
// switches through each one on the real screen and screenshots it, once).
// Picking a tile rewrites [background]'s `path = ` line and asks driftwm to
// reload — driftwm auto-backs-up config.toml on its own writes, so this
// doesn't need to (see .gitignore's *.bak* note).
ColumnLayout {
    id: root
    spacing: 8

    readonly property string base: Quickshell.env("HOME") + "/.config/driftwm/wallpapers"
    readonly property string thumbDir: base + "/thumbs"
    property var wallpapers: []
    property string active: ""

    Component.onCompleted: if (visible) { list.running = true; current.running = true }
    onVisibleChanged: if (visible) {
        list.running = true
        current.running = true
    }

    function thumbFor(rel) {
        return thumbDir + "/" + rel.replace(/\//g, "_").replace(/\.glsl$/, ".png")
    }

    function apply(rel) {
        rewrite.command = ["sh", "-c",
            `sed -i 's|^path = ".*"|path = "~/.config/driftwm/wallpapers/${rel}"|' ~/.config/driftwm/config.toml && ~/.config/driftwm/scripts/apply_theme_colors.py '${rel}' && driftwm msg action reload-config`]
        rewrite.running = true
        root.active = rel
    }

    // A handful of the .glsl files (mirrored_parallax, ripple, and their
    // textured/ copies) are templates that need a `texture = "~/Pictures/…"`
    // line pointing at a photo — this picker only ever sets `path`, so
    // applying one renders whatever an unset sampler happens to produce, not
    // a usable wallpaper. Left out until there's a way to also pick a photo.
    Process {
        id: list
        command: ["sh", "-c", `find "${root.base}" -name '*.glsl' | xargs grep -L sampler2D | sort`]
        stdout: StdioCollector {
            onStreamFinished: root.wallpapers = text.trim().split("\n").filter(l => l).map(p => p.slice(root.base.length + 1))
        }
    }

    Process {
        id: current
        command: ["sh", "-c", "grep '^path = ' ~/.config/driftwm/config.toml | head -n1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.match(/wallpapers\/(.+)\.glsl/)
                root.active = m ? `${m[1]}.glsl` : ""
            }
        }
    }

    Process { id: rewrite }

    // Extension decides driftwm's [background] `type`: an image becomes
    // `wallpaper` (single image, aspect-preserving cover — see driftwm's
    // README on background modes), a shader stays `shader` like the
    // bundled ones, just pointed outside wallpapers/.
    readonly property var imageExts: ["png", "jpg", "jpeg", "webp", "bmp"]

    function applyCustom(path) {
        const ext = path.split(".").pop().toLowerCase()
        const type = root.imageExts.includes(ext) ? "wallpaper" : "shader"
        rewrite.command = ["sh", "-c",
            `sed -i -e 's|^type = ".*"|type = "${type}"|' -e 's|^path = ".*"|path = "${path}"|' ~/.config/driftwm/config.toml && ~/.config/driftwm/scripts/apply_theme_colors.py '${path}' && driftwm msg action reload-config`]
        rewrite.running = true
        root.active = path
    }

    function pickCustom() {
        picker.command = ["zenity", "--file-selection", "--title=Выбери файл обоев",
            "--file-filter=Изображения | *.png *.jpg *.jpeg *.webp *.bmp",
            "--file-filter=GLSL шейдер | *.glsl"]
        picker.running = true
    }

    Process {
        id: picker
        stdout: StdioCollector {
            onStreamFinished: {
                const path = text.trim()
                if (path) root.applyCustom(path)
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
            Layout.fillWidth: true
            text: "обои — клик применяет сразу"
            color: Theme.fg
            opacity: Theme.dim
            font.pixelSize: Theme.smallFontSize
            font.family: Theme.fontFamily
        }

        FlatButton {
            text: "+ добавить обои"
            fontSize: Theme.smallFontSize
            onClicked: root.pickCustom()
        }
    }

    Flickable {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        contentWidth: width
        contentHeight: grid.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        Flow {
            id: grid
            width: parent.width
            spacing: 10

            Repeater {
                model: root.wallpapers

                ColumnLayout {
                    id: tile
                    required property string modelData
                    readonly property bool active: modelData === root.active
                    width: 140
                    spacing: 4

                    Rectangle {
                        Layout.preferredWidth: 140
                        Layout.preferredHeight: 80
                        radius: 8
                        color: Theme.track
                        border.color: tile.active ? Theme.fg : Theme.border
                        border.width: tile.active ? 2 : 1
                        clip: true

                        Image {
                            anchors.fill: parent
                            anchors.margins: tile.active ? 2 : 1
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            source: "file://" + root.thumbFor(tile.modelData)
                            onStatusChanged: if (status === Image.Error) visible = false
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.apply(tile.modelData)
                        }
                    }

                    Text {
                        Layout.preferredWidth: 140
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: tile.modelData.split("/").pop().replace(/\.glsl$/, "")
                        color: Theme.fg
                        opacity: tile.active ? 1 : Theme.dim
                        font.pixelSize: Theme.smallFontSize
                        font.bold: tile.active
                        font.family: Theme.fontFamily
                    }
                }
            }
        }
    }
}
