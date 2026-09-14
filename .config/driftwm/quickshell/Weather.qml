import QtQuick
import QtQuick.Layouts
import Quickshell.Io

// wttr.in auto-detects location from the machine's public IP — no city, no
// API key, nothing to configure. Refreshed every 30 min; weather doesn't
// need tighter polling than that, and it's a free service.
Tile {
    id: root

    property string city: ""
    property string condition: ""
    property string feelsLike: ""
    property string humidity: ""
    property string windKmph: ""
    property var forecast: []

    label: "weather"
    value: "—"
    clickable: true
    onClicked: popover.toggle()

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

    Process {
        id: fetch
        command: ["curl", "-s", "--max-time", "10", "wttr.in/?format=j1"]
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }

    Timer {
        interval: 30 * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: fetch.running = true
    }

    Popover {
        id: popover
        target: root

        Text {
            text: root.city || "…"
            color: Theme.fg
            font.pixelSize: Theme.fontSize
            font.bold: true
            font.family: Theme.fontFamily
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
