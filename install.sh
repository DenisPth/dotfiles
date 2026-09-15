#!/usr/bin/env sh
# install.sh — full dark_sea rice setup, from a bare Manjaro/Arch machine to
# this exact desktop: driftwm + every tool the configs in this repo expect,
# the configs themselves (symlinked in, so future edits land back in this
# repo), and the Monocraft font.
#
# Idempotent: existing targets are backed up (timestamped, never clobbered)
# before being replaced with a symlink into this repo.
set -eu

REPO_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
TS="$(date +%Y%m%d-%H%M%S)"

need_yay() {
    command -v yay >/dev/null 2>&1 || {
        echo "error: yay (AUR helper) not found — driftwm only exists on the AUR." >&2
        echo "  Install yay first: https://github.com/Jguer/yay#installation" >&2
        exit 1
    }
}

link() {
    # link <repo-relative path> <absolute target path>
    src="$REPO_DIR/$1"
    dst="$2"
    [ -e "$src" ] || return 0
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        mv -- "$dst" "$dst.$TS.bak"
        echo "  backed up $dst -> $dst.$TS.bak"
    elif [ -L "$dst" ]; then
        rm -f -- "$dst"
    fi
    mkdir -p -- "$(dirname -- "$dst")"
    ln -s -- "$src" "$dst"
    echo "  linked $dst -> $src"
}

echo "==> Packages (pacman + AUR via yay)"
need_yay
yay -S --needed --noconfirm \
    driftwm quickshell \
    waybar kanshi swaync swayosd \
    ghostty kitty fuzzel cliphist wl-clipboard \
    cava btop fastfetch jq hyprshot swayidle swaylock \
    curl lm_sensors imagemagick \
    zsh-theme-powerlevel10k zsh-autosuggestions zsh-syntax-highlighting \
    eza zoxide pkgfile \
    papirus-icon-theme bibata-cursor-git breeze-gtk

echo "==> pkgfile database (powers the command-not-found zsh plugin)"
sudo pkgfile --update
sudo systemctl enable --now pkgfile-update.timer 2>/dev/null || true

echo "==> Oh My Zsh (framework the plugins in .zshrc expect)"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
else
    echo "  already installed, skipping"
fi

echo "==> Configs (symlinked from this repo, existing files backed up)"
for d in driftwm waybar ghostty kitty fuzzel swaync swaylock cava btop kanshi \
         gtk-3.0 gtk-4.0 fastfetch; do
    link ".config/$d" "$CONFIG_HOME/$d"
done
link ".config/kdeglobals" "$CONFIG_HOME/kdeglobals"
link ".config/kcminputrc" "$CONFIG_HOME/kcminputrc"
link ".config/zed/settings.json" "$CONFIG_HOME/zed/settings.json"
link ".zshrc" "$HOME/.zshrc"
link ".p10k.zsh" "$HOME/.p10k.zsh"

chmod +x "$CONFIG_HOME"/driftwm/scripts/*.sh 2>/dev/null || true
chmod +x "$CONFIG_HOME"/waybar/scripts/*.sh 2>/dev/null || true

echo "==> Monocraft (Nerd Font patched) — not packaged, fetched from upstream release"
mkdir -p "$HOME/.local/share/fonts/Monocraft"
curl -sL -o "$HOME/.local/share/fonts/Monocraft/Monocraft-nerd-fonts-patched.ttc" \
    "https://github.com/IdreesInc/Monocraft/releases/latest/download/Monocraft-nerd-fonts-patched.ttc"
fc-cache -f "$HOME/.local/share/fonts" >/dev/null

echo "==> Clipboard history watchers (for this session; the driftwm autostart entries in config.toml cover future logins)"
pgrep -f "wl-paste --type text --watch cliphist" >/dev/null 2>&1 || \
    (wl-paste --type text --watch cliphist store &) 2>/dev/null || true
pgrep -f "wl-paste --type image --watch cliphist" >/dev/null 2>&1 || \
    (wl-paste --type image --watch cliphist store &) 2>/dev/null || true

cat <<'EOF'

Done. Log out and back into driftwm to pick everything up (or manually
restart waybar/swaync/qs and re-`fc-cache` if you're mid-session).

Not automated here — needs root, apply by hand if you want it:
  - The ly login-screen colors (/etc/ly/config.ini). See README.md.
EOF
