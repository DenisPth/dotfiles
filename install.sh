#!/usr/bin/env sh
# install.sh — full dark_sea rice setup, from a bare Arch/Manjaro or Fedora
# machine to this exact desktop: driftwm + every tool the configs in this
# repo expect, the configs themselves (symlinked in, so future edits land
# back in this repo), and the Monocraft font.
#
# Idempotent: existing targets are backed up (timestamped, never clobbered)
# before being replaced with a symlink into this repo.
set -eu

REPO_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
TS="$(date +%Y%m%d-%H%M%S)"

# ---------------------------------------------------------------- distro ---
DISTRO=""
if [ -f /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    case " ${ID:-} ${ID_LIKE:-} " in
        *" fedora "*) DISTRO=fedora ;;
        *" arch "*)   DISTRO=arch ;;
    esac
fi
[ -n "$DISTRO" ] || {
    echo "error: unrecognized distro (checked /etc/os-release ID/ID_LIKE for" >&2
    echo "  arch or fedora) — this installer only knows those two." >&2
    exit 1
}
echo "==> Detected distro: $DISTRO"

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

clone_if_missing() {
    # clone_if_missing <repo-url> <dest-dir>
    [ -d "$2" ] || git clone --depth 1 "$1" "$2"
}

# --------------------------------------------------------- driftwm (Fedora) --
# Fedora has no driftwm package (Arch's AUR does) — built from source per
# https://github.com/malbiruk/driftwm#build-from-source.
build_driftwm_from_source() {
    command -v driftwm >/dev/null 2>&1 && {
        echo "  driftwm already installed, skipping build"
        return 0
    }
    echo "==> driftwm (built from source — no Fedora package yet)"

    rust_ok=0
    if command -v rustc >/dev/null 2>&1; then
        minor="$(rustc --version | sed -n 's/^rustc 1\.\([0-9][0-9]*\).*/\1/p')"
        [ -n "$minor" ] && [ "$minor" -ge 88 ] && rust_ok=1
    fi
    if [ "$rust_ok" -eq 0 ]; then
        echo "  system rust is missing or older than 1.88 (driftwm needs edition 2024) — installing via rustup"
        curl -fsSL https://sh.rustup.rs | sh -s -- -y --profile minimal
        # shellcheck disable=SC1091
        . "$HOME/.cargo/env"
    fi

    src="$(mktemp -d)"
    git clone --depth 1 https://github.com/malbiruk/driftwm.git "$src/driftwm"
    (cd "$src/driftwm" && make build && sudo make install)
    rm -rf "$src"
}

# hyprshot is a single upstream shell script, not a reliable Fedora package.
install_hyprshot_fedora() {
    command -v hyprshot >/dev/null 2>&1 && return 0
    echo "==> hyprshot (no Fedora package — it's one upstream shell script)"
    mkdir -p "$HOME/.local/bin"
    curl -fsSL -o "$HOME/.local/bin/hyprshot" \
        https://raw.githubusercontent.com/Gustash/Hyprshot/main/hyprshot
    chmod +x "$HOME/.local/bin/hyprshot"
    case ":$PATH:" in
        *":$HOME/.local/bin:"*) ;;
        *) echo "  note: ~/.local/bin isn't on PATH in this shell — add it" ;;
    esac
}

install_packages_arch() {
    echo "==> Packages (pacman + AUR via yay)"
    command -v yay >/dev/null 2>&1 || {
        echo "error: yay (AUR helper) not found — driftwm only exists on the AUR." >&2
        echo "  Install yay first: https://github.com/Jguer/yay#installation" >&2
        exit 1
    }
    yay -S --needed --noconfirm \
        driftwm quickshell \
        waybar kanshi swaync swayosd \
        ghostty kitty fuzzel cliphist wl-clipboard thunar \
        cava btop fastfetch jq hyprshot swayidle swaylock \
        curl lm_sensors imagemagick \
        eza zoxide pkgfile \
        papirus-icon-theme bibata-cursor-git breeze-gtk

    echo "==> pkgfile database (powers the command-not-found zsh plugin)"
    sudo pkgfile --update
    sudo systemctl enable --now pkgfile-update.timer 2>/dev/null || true
}

install_packages_fedora() {
    echo "==> Packages (dnf + COPR)"
    sudo dnf install -y dnf-plugins-core PackageKit-command-not-found

    echo "==> COPR repos (driftwm's ecosystem isn't fully in Fedora's own repos yet)"
    sudo dnf copr enable -y erikreider/SwayNotificationCenter
    sudo dnf copr enable -y erikreider/swayosd
    sudo dnf copr enable -y alternateved/ghostty
    sudo dnf copr enable -y peterwu/rendezvous # bibata-cursor-themes

    sudo dnf install -y \
        quickshell \
        waybar kanshi SwayNotificationCenter swayosd \
        ghostty kitty fuzzel cliphist wl-clipboard thunar \
        cava btop fastfetch jq swayidle swaylock \
        curl lm_sensors ImageMagick \
        eza zoxide \
        papirus-icon-theme bibata-cursor-themes breeze-gtk \
        xwayland-satellite \
        git make gcc pkgconf-pkg-config rust cargo \
        libseat-devel libdisplay-info-devel libinput-devel \
        mesa-libgbm-devel libxkbcommon-devel wayland-devel

    install_hyprshot_fedora
    build_driftwm_from_source
}

install_sddm() {
    echo "==> sddm"
    case "$DISTRO" in
        arch) yay -S --needed --noconfirm sddm ;;
        fedora) sudo dnf install -y sddm ;;
    esac
    sudo systemctl enable sddm
}

# Theming applies the same sed this repo used to ask you to run by hand
# (see README.md history) against ly's actual config file, so it only runs
# once ly (and its default /etc/ly/config.ini) actually exists.
install_ly() {
    echo "==> ly"
    case "$DISTRO" in
        arch) yay -S --needed --noconfirm ly ;;
        fedora)
            sudo dnf copr enable -y fnux/ly
            sudo dnf install -y ly
            ;;
    esac
    # ly@.service is a template unit (runs on one tty, given as the
    # instance) on both Arch's and Fedora's packages — plain "ly" isn't a
    # real unit name. tty2 is upstream's own default; a getty there would
    # fight ly for the seat, so it has to go.
    sudo systemctl disable --now getty@tty2.service 2>/dev/null || true
    sudo systemctl enable ly@tty2.service

    if [ -f /etc/ly/config.ini ]; then
        echo "  theming /etc/ly/config.ini to dark_sea"
        sudo sed -i \
            -e 's/^bg = .*/bg = 0x002b323c/' \
            -e 's/^fg = .*/fg = 0x00c9c4ab/' \
            -e 's/^border_fg = .*/border_fg = 0x007089a0/' \
            -e 's/^animation = .*/animation = doom/' \
            -e 's/^doom_top_color = .*/doom_top_color = 0x002b323c/' \
            -e 's/^doom_middle_color = .*/doom_middle_color = 0x007089a0/' \
            -e 's/^doom_bottom_color = .*/doom_bottom_color = 0x00e2ddc4/' \
            /etc/ly/config.ini
    fi
}

choose_login_manager() {
    echo "==> Login manager (optional — skip if you already have one)"
    if [ ! -t 0 ]; then
        echo "  no tty to prompt on, skipping (install sddm or ly by hand later if you want one)"
        return 0
    fi
    printf '  [1] sddm   [2] ly (themed dark_sea)   [3] skip (default): '
    read -r choice
    case "$choice" in
        1) install_sddm ;;
        2) install_ly ;;
        *) echo "  skipping" ;;
    esac
}

case "$DISTRO" in
    arch) install_packages_arch ;;
    fedora) install_packages_fedora ;;
esac

choose_login_manager

echo "==> Oh My Zsh (framework the plugins in .zshrc expect)"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
else
    echo "  already installed, skipping"
fi

echo "==> Zsh plugins/theme (git-cloned — same on every distro, not a distro package)"
clone_if_missing https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
clone_if_missing https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
clone_if_missing https://github.com/romkatv/powerlevel10k "$ZSH_CUSTOM/themes/powerlevel10k"

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

cat <<EOF

Done. Log out and back into driftwm to pick everything up (or manually
restart waybar/swaync/qs and re-\`fc-cache\` if you're mid-session).
$(if [ "$DISTRO" = fedora ]; then cat <<'FED'

Fedora-specific notes:
  - swaync/swayosd/ghostty/bibata-cursor-themes came from third-party COPR
    repos (enabled above) rather than Fedora's own — review them if that
    matters to you: https://copr.fedorainfracloud.org/
  - driftwm was built from source into /usr/local (see `sudo make uninstall`
    in a fresh clone of https://github.com/malbiruk/driftwm to remove it).
FED
fi)
EOF
