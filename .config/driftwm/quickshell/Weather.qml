import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

// wttr.in geolocates by public IP when no location is set — fine normally,
// but wrong behind a VPN. locationOverride, once set, is used verbatim and
// persisted to weather_location.txt so it survives a restart.
Tile {
    id: root

    property string city: ""
    property string condition: ""
    property string feelsLike: ""
    property string humidity: ""
    property string windKmph: ""
    property var forecast: []
    property string locationOverride: ""

    label: "weather"
    value: "—"
    clickable: true
    onClicked: popover.toggle()

    FileView {
        id: locationFile
        path: Quickshell.shellDir + "/weather_location.txt"
        printErrors: false
        // Settings > погода writes this file directly (no IPC) — watch it so
        // a change there shows up here without restarting quickshell.
        watchChanges: true
        onLoaded: {
            root.locationOverride = text().trim()
            fetch.running = true
        }
        onLoadFailed: fetch.running = true
        onFileChanged: reload()
    }

    function parse(text) {
        let data
        try {
            data = JSON.parse(text)
        } catch (e) {
            return
        }
        const cur = data.current_condition && data.current_condition[0]
        if (!cur) return
        const area = data.nearest_area && data.nearest_area[0]
        root.city = area && area.areaName && area.areaName[0] ? area.areaName[0].value : ""
        root.condition = cur.weatherDesc && cur.weatherDesc[0] ? cur.weatherDesc[0].value : ""
        root.feelsLike = cur.FeelsLikeC
        root.humidity = cur.humidity
        root.windKmph = cur.windspeedKmph
        root.value = `${cur.temp_C}°C`
        // Midday (index 4 of the 3-hourly buckets) stands in for "the day's weather".
        root.forecast = (data.weather || []).slice(1, 3).map(day => ({
            date: day.date,
            min: day.mintempC,
            max: day.maxtempC,
            desc: day.hourly && day.hourly[4] && day.hourly[4].weatherDesc
                ? day.hourly[4].weatherDesc[0].value : "",
        }))
    }

    function setLocation(loc) {
        root.locationOverride = loc
        locationFile.setText(loc)
        fetch.running = true
    }

    Process {
        id: fetch
        command: {
            const path = root.locationOverride ? encodeURIComponent(root.locationOverride) : ""
            return ["curl", "-s", "--max-time", "10", `wttr.in/${path}?format=j1`]
        }
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }

    Timer {
        interval: 30 * 60 * 1000
        running: true
        repeat: true
        onTriggered: fetch.running = true
    }

    Popover {
        id: popover
        target: root

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                Layout.fillWidth: true
                text: root.city || "…"
                color: Theme.fg
                font.pixelSize: Theme.fontSize
                font.bold: true
                font.family: Theme.fontFamily
            }

            TextField {
                id: locationField
                Layout.preferredWidth: 100
                text: root.locationOverride
                placeholderText: "город"
                placeholderTextColor: Theme.border
                color: Theme.fg
                font.pixelSize: Theme.smallFontSize
                font.family: Theme.fontFamily
                background: Rectangle { color: Theme.track; radius: 6 }
                onAccepted: root.setLocation(text.trim())
            }
        }

        Text {
            text: `${root.condition} · ощущается ${root.feelsLike}°C`
            color: Theme.fg
            opacity: Theme.dim
            font.pixelSize: Theme.smallFontSize
            font.family: Theme.fontFamily
        }

        Text {
            text: `влажность ${root.humidity}% · ветер ${root.windKmph} км/ч`
            color: Theme.fg
            opacity: Theme.dim
            font.pixelSize: Theme.smallFontSize
            font.family: Theme.fontFamily
        }

        ColumnLayout {
            Layout.topMargin: 4
            spacing: 2

            Repeater {
                model: root.forecast

                RowLayout {
                    required property var modelData
                    spacing: 8

                    Text {
                        Layout.preferredWidth: 70
                        text: modelData.date
                        color: Theme.fg
                        opacity: Theme.dim
                        font.pixelSize: Theme.smallFontSize
                        font.family: Theme.fontFamily
                    }

                    Text {
                        text: `${modelData.min}–${modelData.max}°C · ${modelData.desc}`
                        color: Theme.fg
                        font.pixelSize: Theme.smallFontSize
                        font.family: Theme.fontFamily
                    }
                }
            }
        }
    }
}
