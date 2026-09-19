#!/usr/bin/env sh
# Toggles the focused window between fully opaque and its themed
# transparency — useful for video, since driftwm blends the whole window
# buffer and can't tell a video element inside it from the rest.
set -eu

current="$(driftwm msg opacity)"
# Anything already close to opaque flips to the rice's default translucency;
# anything else (including a rule-pinned value) flips to fully opaque.
awk -v c="$current" 'BEGIN { exit !(c > 0.97) }' \
    && driftwm msg opacity 0.78 \
    || driftwm msg opacity 1
