#!/usr/bin/env sh
# update.sh — relink configs from the current state of this repo into
# ~/.config and ~ (existing non-symlink files backed up, timestamped, never
# clobbered). No package installs, no prompts — just the "Configs" step of
# install.sh, callable on its own so a version-mismatch check (see .zshrc)
# can offer a quick update without re-running the whole installer.
set -eu

REPO_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
TS="$(date +%Y%m%d-%H%M%S)"

echo "==> Pulling latest from origin"
if ! git -C "$REPO_DIR" pull --ff-only; then
    echo "  pull failed (offline, or local commits diverge from origin) — continuing with the repo as it is locally" >&2
fi

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

echo "==> Configs (symlinked from this repo, existing files backed up)"
for d in driftwm waybar ghostty kitty fuzzel swaync swaylock cava btop kanshi \
         gtk-3.0 gtk-4.0 fastfetch; do
    link ".config/$d" "$CONFIG_HOME/$d"
done
link ".config/kdeglobals" "$CONFIG_HOME/kdeglobals"
link ".config/kcminputrc" "$CONFIG_HOME/kcminputrc"
link ".config/zed/settings.json" "$CONFIG_HOME/zed/settings.json"
link ".config/zed/themes/dark_sea.json" "$CONFIG_HOME/zed/themes/dark_sea.json"
link ".zshrc" "$HOME/.zshrc"
link ".p10k.zsh" "$HOME/.p10k.zsh"

chmod +x "$CONFIG_HOME"/driftwm/scripts/*.sh 2>/dev/null || true
chmod +x "$CONFIG_HOME"/driftwm/scripts/*.py 2>/dev/null || true
chmod +x "$CONFIG_HOME"/waybar/scripts/*.sh 2>/dev/null || true

git -C "$REPO_DIR" rev-parse HEAD > "$REPO_DIR/.installed_version"
echo "Done."
