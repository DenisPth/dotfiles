#!/usr/bin/env sh
# Toggle screen recording for TikTok clips: first press picks a region with
# slurp and starts wf-recorder into it, second press stops. A region (not
# the whole screen) so nothing outside the picked window/area ever ends up
# in a clip — same reasoning as the screenshot keybinds.
set -eu

OUT_DIR="$HOME/Videos/tiktok"
PID_FILE="/tmp/record_clip.pid"
mkdir -p "$OUT_DIR"

if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
	kill -INT "$(cat "$PID_FILE")"
	rm -f "$PID_FILE"
	notify-send "Recording stopped" "$OUT_DIR"
	exit 0
fi

REGION="$(slurp)"
FILE="$OUT_DIR/$(date +%Y%m%d-%H%M%S).mp4"

wf-recorder -g "$REGION" -f "$FILE" &
echo $! >"$PID_FILE"
notify-send "Recording started" "$(basename "$FILE")"
