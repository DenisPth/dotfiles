#!/usr/bin/env sh
# Regenerates the wallpaper thumbnails the settings window's "обои" section
# shows. Run by hand after adding/changing a wallpaper.
#
# Uses `driftwm msg screenshot region` (a re-render straight from canvas
# coordinates, not a screen grab) at a point far from every real window, so
# nothing but the wallpaper itself ever ends up in a thumbnail. Still flips
# the *actual* active wallpaper through every file on this list — that part
# really does show up live for a moment each — but doesn't touch camera,
# zoom, or focus doing it, so it can't drag the viewport onto whatever's
# focused (that's what went wrong the first time this script ran).
#
# Each shot gets a near-black check (shaders can take a beat to compile) —
# a black one is retried a few times before being kept as-is.
set -eu

CONFIG="$HOME/.config/driftwm/config.toml"
WALLPAPERS="$HOME/.config/driftwm/wallpapers"
THUMBS="$WALLPAPERS/thumbs"
RAW="$(mktemp --suffix=.png)"
trap 'rm -f "$RAW"' EXIT

command -v magick >/dev/null 2>&1 || { echo "error: imagemagick (magick) not found" >&2; exit 1; }

mkdir -p "$THUMBS"
original="$(grep '^path = ' "$CONFIG" | head -n1 | sed -E 's/^path = "(.*)"$/\1/')"

find "$WALLPAPERS" -name '*.glsl' | sort | while IFS= read -r f; do
    rel="${f#"$WALLPAPERS"/}"
    name="$(echo "$rel" | tr '/' '_' | sed 's/\.glsl$//')"
    echo "==> $rel"
    sed -i "s|^path = \".*\"|path = \"~/.config/driftwm/wallpapers/$rel\"|" "$CONFIG"
    driftwm msg action reload-config >/dev/null

    tries=0
    while :; do
        tries=$((tries + 1))
        sleep 0.6
        driftwm msg screenshot region 20000 20000 400 220 -o "$RAW" >/dev/null
        mean="$(magick "$RAW" -colorspace Gray -format "%[fx:mean]" info:)"
        awk -v m="$mean" 'BEGIN { exit !(m > 0.02) }' && break
        [ "$tries" -ge 5 ] && { echo "    still black after $tries tries, keeping it anyway"; break; }
        echo "    black frame (mean=$mean), retrying"
    done
    magick "$RAW" -resize 280x160^ -gravity center -extent 280x160 "$THUMBS/$name.png"
done

sed -i "s|^path = \".*\"|path = \"$original\"|" "$CONFIG"
driftwm msg action reload-config >/dev/null
echo "==> restored $original"
