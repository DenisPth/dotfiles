import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Wallpapers are GLSL shaders under wallpapers/ (see driftwm/config.toml's
// [background] section) — nothing QtQuick can render directly, so the grid
// shows pre-baked thumbnails (scripts/gen_wallpaper_thumbs.sh: briefly
// switches through each one on the real screen and screenshots it, once).
// Custom wallpapers (picked via zenity, see applyCustom) are real images —
// copied into wallpapers/custom/ so they persist and show in the same grid,
// no thumbnail needed since the image already is one.
// Picking a tile rewrites [background]'s `type`/`path = ` lines and asks
// driftwm to reload — driftwm auto-backs-up config.toml on its own writes,
// so this doesn't need to (see .gitignore's *.bak* note).
ColumnLayout {
    id: root
    spacing: 8

    readonly property string base: Quickshell.env("HOME") + "/.config/driftwm/wallpapers"
    readonly property string thumbDir: base + "/thumbs"
    readonly property string customDir: base + "/custom"
    property var wallpapers: []
    property string active: ""
    property bool sorting: false

    readonly property var imageExts: ["png", "jpg", "jpeg", "webp", "bmp"]
    function isImage(rel) {
        return root.imageExts.includes(rel.split(".").pop().toLowerCase())
    }

    Component.onCompleted: if (visible) { list.running = true; current.running = true }
    onVisibleChanged: if (visible) {
        list.running = true
        current.running = true
    }

    function thumbFor(rel) {
        if (root.isImage(rel)) return root.base + "/" + rel
        return thumbDir + "/" + rel.replace(/\//g, "_").replace(/\.glsl$/, ".png")
    }

    function label(rel) {
        return rel.split("/").pop().replace(/\.[^.]+$/, "")
    }

    function apply(rel) {
        const type = root.isImage(rel) ? "wallpaper" : "shader"
        rewrite.command = ["sh", "-c",
            `sed -i -e 's|^type = ".*"|type = "${type}"|' -e 's|^path = ".*"|path = "~/.config/driftwm/wallpapers/${rel}"|' ~/.config/driftwm/config.toml && ~/.config/driftwm/scripts/apply_theme_colors.py '${rel}' && driftwm msg action reload-config`]
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
        command: ["sh", "-c",
            `{ find "${root.base}" -name '*.glsl' | xargs grep -L sampler2D; ` +
            `find "${root.customDir}" -maxdepth 1 -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.bmp' \\) 2>/dev/null; } | sort`]
        stdout: StdioCollector {
            onStreamFinished: root.wallpapers = text.trim().split("\n").filter(l => l).map(p => p.slice(root.base.length + 1))
        }
    }

    Process {
        id: current
        command: ["sh", "-c", "grep '^path = ' ~/.config/driftwm/config.toml | head -n1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.match(/wallpapers\/(.+)$/)
                root.active = m ? m[1].replace(/"$/, "") : ""
            }
        }
    }

    Process { id: rewrite }

    function applyCustom(externalPath) {
        copier.command = ["sh", "-c",
            `mkdir -p '${root.customDir}' && cp -n -- '${externalPath}' '${root.customDir}/' && basename -- '${externalPath}'`]
        copier.running = true
    }

    Process {
        id: copier
        stdout: StdioCollector {
            onStreamFinished: {
                const name = text.trim()
                if (!name) return
                const rel = "custom/" + name
                if (!root.wallpapers.includes(rel)) root.wallpapers = [...root.wallpapers, rel]
                root.apply(rel)
            }
        }
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

    Process { id: remover }

    function removeCustom(rel) {
        if (!rel.startsWith("custom/")) return
        remover.command = ["rm", "-f", `${root.base}/${rel}`]
        remover.running = true
        root.wallpapers = root.wallpapers.filter(w => w !== rel)
        if (root.active === rel) root.active = ""
    }

    // Sorts by hue — samples each wallpaper's own thumbnail/image down to a
    // single average pixel (ImageMagick), same source thumbFor() shows.
    function sortByColor() {
        if (root.sorting || root.wallpapers.length === 0) return
        root.sorting = true
        const probes = root.wallpapers.map(rel =>
            `printf '%s|' '${rel}'; magick '${root.thumbFor(rel)}' -resize 1x1 txt:- | tail -n1 | grep -oE '\\([0-9]+,[0-9]+,[0-9]+' | tr -d '(' ; echo`
        ).join("; ")
        sorter.command = ["sh", "-c", probes]
        sorter.running = true
    }

    function hue(r, g, b) {
        r /= 255; g /= 255; b /= 255
        const max = Math.max(r, g, b), min = Math.min(r, g, b)
        if (max === min) return 0
        const d = max - min
        let h
        if (max === r) h = ((g - b) / d) % 6
        else if (max === g) h = (b - r) / d + 2
        else h = (r - g) / d + 4
        return h * 60
    }

    Process {
        id: sorter
        stdout: StdioCollector {
            onStreamFinished: {
                root.sorting = false
                const entries = text.trim().split("\n").filter(l => l).map(line => {
                    const [rel, rgb] = line.split("|")
                    const parts = (rgb || "0,0,0").split(",").map(Number)
                    return { rel: rel, hue: root.hue(parts[0] || 0, parts[1] || 0, parts[2] || 0) }
                })
                entries.sort((a, b) => a.hue - b.hue)
                if (entries.length === root.wallpapers.length) root.wallpapers = entries.map(e => e.rel)
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
            text: root.sorting ? "сортирую…" : "по цвету"
            fontSize: Theme.smallFontSize
            onClicked: root.sortByColor()
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
                    readonly property bool custom: modelData.startsWith("custom/")
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

                        FlatButton {
                            visible: tile.custom
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: 2
                            text: "✕"
                            fontSize: Theme.smallFontSize
                            padX: 5
                            padY: 2
                            onClicked: root.removeCustom(tile.modelData)
                        }
                    }

                    Text {
                        Layout.preferredWidth: 140
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: root.label(tile.modelData)
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
