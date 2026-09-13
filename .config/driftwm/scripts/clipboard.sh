#!/usr/bin/env sh
# История буфера обмена: cliphist хранит записи, fuzzel — уже готовый и
# оформленный под dark_sea выбиратель (см. ~/.config/fuzzel/fuzzel.ini).
cliphist list | fuzzel --dmenu --prompt "clip> " | cliphist decode | wl-copy
