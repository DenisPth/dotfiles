#!/usr/bin/env sh
# waybar custom/power-profile module — backed by power-profiles-daemon,
# the same source PowerSection.qml's buttons read/write via PowerProfiles.
# No args: print the current profile (Russian label, matches Settings).
# --cycle: advance to the next profile powerprofilesctl actually lists.
set -eu

label() {
    case "$1" in
        power-saver) echo "экономия" ;;
        balanced) echo "баланс" ;;
        performance) echo "производительность" ;;
        *) echo "$1" ;;
    esac
}

if [ "${1:-}" = "--cycle" ]; then
    current="$(powerprofilesctl get 2>/dev/null || echo "")"
    available="$(powerprofilesctl list 2>/dev/null | grep -oE '^[* ]*[a-z-]+:' | tr -d '*: ')"
    [ -n "$available" ] || exit 0
    next=""
    found=0
    for p in $available; do
        [ "$found" = 1 ] && { next="$p"; break; }
        [ "$p" = "$current" ] && found=1
    done
    [ -z "$next" ] && next="$(printf '%s\n' "$available" | head -n1)"
    powerprofilesctl set "$next"
else
    label "$(powerprofilesctl get 2>/dev/null || echo "н/д")"
fi
