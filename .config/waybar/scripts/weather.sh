#!/usr/bin/env sh
# waybar custom/weather module — same wttr.in source and location override
# as the quickshell Weather.qml tile (shared weather_location.txt), so the
# two never disagree.
set -eu

LOC_FILE="$HOME/.config/driftwm/quickshell/weather_location.txt"
LOC=""
[ -f "$LOC_FILE" ] && LOC="$(cat "$LOC_FILE")"
LOC_ENC="$(jq -rn --arg loc "$LOC" '$loc|@uri')"

data="$(curl -s --max-time 10 "wttr.in/${LOC_ENC}?format=j1")" || exit 0
[ -n "$data" ] || exit 0

echo "$data" | jq -c '
    .current_condition[0] as $cur |
    .nearest_area[0].areaName[0].value as $city |
    {
        text: ($cur.temp_C + "°C"),
        tooltip: ($city + " — " + $cur.weatherDesc[0].value + "\nощущается " + $cur.FeelsLikeC + "°C, влажность " + $cur.humidity + "%, ветер " + $cur.windspeedKmph + " км/ч")
    }
'
