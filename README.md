# dotfiles — dark_sea

A driftwm rice built around `dark_sea.glsl` (dark teal water, warm cream
foam) — carried through the compositor decorations, the quickshell home
dashboard, waybar, terminals, the launcher, notifications, the lock screen,
GTK/KDE, the shell prompt, and Zed.

## Install

```sh
git clone <this-repo-url> ~/dotfiles
cd ~/dotfiles
./install.sh
```

Needs [`yay`](https://github.com/Jguer/yay) (driftwm and a couple of other
pieces only exist on the AUR). The script installs every package these
configs expect, then symlinks the configs from this repo into `~/.config`
and `~` — existing files are backed up (timestamped) rather than
overwritten. Edit the live config afterward and you're editing this repo.

## What's here

- **driftwm** — compositor config, the quickshell home dashboard (clock,
  weather, battery/network/brightness/cpu/kbd/bluetooth/volume/ram/disk
  tiles, media player, app launcher, tea timer, pomodoro, notes, tray),
  a GNOME-Settings-shaped window (`mod+s`: wi-fi, bluetooth, sound, brightness
  & power, display resolution, wallpaper, keyboard layout, about, dotfiles
  update check), scripts (spotlight search, clipboard picker, battery
  notifications).
- **waybar** — a `custom/window` module reads driftwm's own IPC
  (`driftwm msg subscribe`) for the focused window title, since driftwm has
  no Hyprland/Sway-style workspaces to hook a stock module into.
- **foot / kitty** — Monocraft, dark_sea 16-color palette.
- **fuzzel** — launcher + `mod+v` clipboard picker (cliphist), Papirus-Dark
  icons.
- **swaync**, **swaylock**, **cava**, **btop**, **kanshi**, **GTK 3/4**,
  **kdeglobals/kcminputrc** (Bibata-Modern-Classic cursor, Papirus-Dark
  icons), **fastfetch**, **Zed** ("Dark Sea" theme).
- **.zshrc / .p10k.zsh** — Powerlevel10k + autosuggestions + syntax
  highlighting, dark_sea colors.

## Font

[Monocraft](https://github.com/IdreesInc/Monocraft) (Nerd Font patched) — a
monospace font styled after old Minecraft's pixel font. Not packaged;
`install.sh` fetches it from the upstream release.

## Not automated (needs root)

The `ly` login screen (`/etc/ly/config.ini`) — apply by hand:

```sh
sudo sed -i \
  -e 's/^bg = .*/bg = 0x002b323c/' \
  -e 's/^fg = .*/fg = 0x00c9c4ab/' \
  -e 's/^border_fg = .*/border_fg = 0x007089a0/' \
  -e 's/^animation = .*/animation = doom/' \
  -e 's/^doom_top_color = .*/doom_top_color = 0x002b323c/' \
  -e 's/^doom_middle_color = .*/doom_middle_color = 0x007089a0/' \
  -e 's/^doom_bottom_color = .*/doom_bottom_color = 0x00e2ddc4/' \
  /etc/ly/config.ini
```
