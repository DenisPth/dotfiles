#!/usr/bin/env sh
# Стримит заголовок активного окна для custom/window в waybar.
# driftwm — не Hyprland/Sway, дискретных workspace'ов у него нет (бесконечный
# канвас), поэтому вместо hyprland/window берём это через его собственный IPC.
exec driftwm msg subscribe --json | jq --unbuffered -r '
  (
    .State.windows[]?
    | select(.is_focused)
    | .title // .app_id
    | gsub("\n"; " ")
  ) // "канвас"
'
