pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// i3bar-style text status: no icons, and no hardcoded font (the system sans
// is fine).
Singleton {
    id: theme

    // The GTK interface font, so the panel matches the rest of the desktop;
    // empty (Qt's default) when gsettings is missing.
    property string fontFamily: ""

    Process {
        command: ["gsettings", "get", "org.gnome.desktop.interface", "font-name"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const match = text.trim().match(/^'(.+?)(?: \d+(?:\.\d+)?)?'$/)
                if (match) theme.fontFamily = match[1]
            }
        }
    }

    // dark_sea — та же палитра, что у driftwm-декораций/ghostty/waybar/kitty.
    // Values load from theme_colors.json, NOT hardcoded here — editing this
    // .qml file live (which apply_theme_colors.py used to do directly)
    // makes quickshell hot-reload the whole singleton, which resets every
    // window bound to it back to its declared state, closing Settings
    // (visible: false in its own source) out from under whoever had it
    // open. Reading a plain data file via FileView.watchChanges is just a
    // property update, not a QML reload, so nothing else so much as
    // flickers.
    property color bg: "#2a3841"
    property color border: "#5a636a"
    property color fg: "#e3e7eb"
    property color track: "#394149"
    property color accent: "#97d6ff"
    property color warm: "#d2c7f0"

    FileView {
        id: colorsFile
        path: Quickshell.shellDir + "/theme_colors.json"
        printErrors: false
        watchChanges: true
        onLoaded: theme.applyColors(text())
        onFileChanged: reload()
    }

    function applyColors(json) {
        let c
        try {
            c = JSON.parse(json)
        } catch (e) {
            return
        }
        if (c.bg) theme.bg = c.bg
        if (c.border) theme.border = c.border
        if (c.fg) theme.fg = c.fg
        if (c.track) theme.track = c.track
        if (c.accent) theme.accent = c.accent
        if (c.warm) theme.warm = c.warm
    }

    readonly property real dim: 0.5
    readonly property real hoverOpacity: 0.1
    readonly property int fontSize: 14
    readonly property int smallFontSize: 12
    readonly property int radius: 14
    readonly property int popupRadius: 10
    readonly property int labelGap: 6
    readonly property int sectionGap: 20
}
