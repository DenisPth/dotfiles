#!/usr/bin/env sh
# install.sh — full dark_sea rice setup, from a bare Arch/Manjaro machine to
# this exact desktop: driftwm + every tool the configs in this repo expect,
# the configs themselves (symlinked in, so future edits land back in this
# repo), and the Monocraft font.
#
# Idempotent: existing targets are backed up (timestamped, never clobbered)
# before being replaced with a symlink into this repo.
set -eu

REPO_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
TS="$(date +%Y%m%d-%H%M%S)"

if [ -f /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    case " ${ID:-} ${ID_LIKE:-} " in
        *" arch "*) ;;
        *)
            echo "error: this installer is Arch/Manjaro-only (found ID=${ID:-?})." >&2
            exit 1
            ;;
    esac
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

clone_if_missing() {
    # clone_if_missing <repo-url> <dest-dir>
    [ -d "$2" ] || git clone --depth 1 "$1" "$2"
}

# Personal apps a couple of keybindings spawn (mod+t, mod+a) but that aren't
# part of the rice itself — asked about individually rather than forced on,
# since someone reusing this repo may not want Denis's browser/chat.
choose_optional_apps() {
    echo "==> Optional apps (used by a couple of keybindings, not required for the rice itself)"
    EXTRA_PACKAGES=""
    if [ ! -t 0 ]; then
        echo "  no tty to prompt on, installing all of them by default"
        EXTRA_PACKAGES="zed telegram-desktop zen-browser-bin libreoffice-fresh throne-bin neovim"
        return 0
    fi
    ask() {
        # ask <prompt> <package>
        printf '  %s [Y/n] ' "$1"
        read -r reply
        case "$reply" in
            [Nn]*) ;;
            *) EXTRA_PACKAGES="$EXTRA_PACKAGES $2" ;;
        esac
    }
    ask "Zed editor?" zed
    ask "Telegram Desktop? (mod+t)" telegram-desktop
    ask "Zen Browser? (mod+a)" zen-browser-bin
    ask "LibreOffice?" libreoffice-fresh
    ask "Throne (VLESS/VMess/etc. proxy client)?" throne-bin
    ask "Neovim?" neovim
}

install_packages() {
    echo "==> Packages (pacman + AUR via yay)"
    command -v yay >/dev/null 2>&1 || {
        echo "error: yay (AUR helper) not found — driftwm only exists on the AUR." >&2
        echo "  Install yay first: https://github.com/Jguer/yay#installation" >&2
        exit 1
    }

    # pipewire-pulse declares Conflicts=pulseaudio in pacman itself — with
    # --noconfirm that removal prompt silently defaults to "no" and fails
    # the whole install. This repo's audio stack is pipewire, so pulseaudio
    # (if something else put it there) has to go first. Building the
    # removal list from what's *actually* installed, not a fixed guess —
    # pacman refuses to remove anything at all if even one named package in
    # the command isn't installed, which was silently eating this whole
    # step before.
    pulse_installed=""
    for p in pulseaudio pulseaudio-bluetooth pulseaudio-alsa pulseaudio-jack; do
        pacman -Qq "$p" >/dev/null 2>&1 && pulse_installed="$pulse_installed $p"
    done
    if [ -n "$pulse_installed" ]; then
        echo "  removing pulseaudio (conflicts with pipewire-pulse):$pulse_installed"
        # shellcheck disable=SC2086
        sudo pacman -Rdd --noconfirm $pulse_installed
    fi

    # shellcheck disable=SC2086
    yay -S --needed --noconfirm \
        driftwm quickshell matugen \
        waybar kanshi swaync swayosd wlr-randr networkmanager \
        ghostty kitty fuzzel cliphist wl-clipboard thunar \
        cava btop fastfetch jq hyprshot swayidle swaylock \
        curl lm_sensors imagemagick brightnessctl \
        slurp grim wf-recorder \
        eza zoxide pkgfile pacman-contrib \
        papirus-icon-theme bibata-cursor-git breeze-gtk \
        bluez bluez-utils pipewire pipewire-pulse pipewire-alsa wireplumber upower \
        power-profiles-daemon pavucontrol \
        $EXTRA_PACKAGES

    echo "==> pkgfile database (powers the command-not-found zsh plugin)"
    sudo pkgfile --update
    sudo systemctl enable --now pkgfile-update.timer 2>/dev/null || true

    # Bluetooth/Wi-Fi/battery tiles in quickshell talk to these over D-Bus
    # directly (Quickshell.Bluetooth/UPower services), not a CLI — so
    # nothing else in this script ever starts them.
    sudo systemctl enable --now NetworkManager bluetooth power-profiles-daemon 2>/dev/null || true
    systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true
}

install_sddm() {
    echo "==> sddm"
    yay -S --needed --noconfirm sddm
    sudo systemctl enable sddm
}

# Theming applies the same sed this repo used to ask you to run by hand
# (see README.md history) against ly's actual config file, so it only runs
# once ly (and its default /etc/ly/config.ini) actually exists.
install_ly() {
    echo "==> ly"
    yay -S --needed --noconfirm ly
    # ly@.service is a template unit (runs on one tty, given as the
    # instance) — plain "ly" isn't a real unit name. tty2 is upstream's own
    # default; a getty there would fight ly for the seat, so it has to go.
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

EXTRA_PACKAGES=""
choose_optional_apps
install_packages
choose_login_manager

echo "==> Oh My Zsh (framework the plugins in .zshrc expect)"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
else
    echo "  already installed, skipping"
fi

echo "==> Default shell"
current_shell="$(getent passwd "$(id -un)" | cut -d: -f7)"
# `command -v zsh` can resolve to /usr/sbin/zsh (a compat symlink on
# Arch) — chsh rejects anything not listed verbatim in /etc/shells, which
# only names /bin/zsh and /usr/bin/zsh. readlink -f follows the symlink to
# the real binary path, which is what's actually listed there.
zsh_path="$(readlink -f "$(command -v zsh)")"
if [ "$current_shell" != "$zsh_path" ]; then
    if grep -qxF "$zsh_path" /etc/shells; then
        echo "  switching from $current_shell to $zsh_path (takes effect next login)"
        chsh -s "$zsh_path"
    else
        echo "  $zsh_path isn't in /etc/shells, skipping — run chsh yourself"
    fi
else
    echo "  already zsh"
fi

echo "==> Zsh plugins/theme (git-cloned rather than a distro package, so it doesn't drift if pacman's copy moves)"
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
curl -fsL -o "$HOME/.local/share/fonts/Monocraft/Monocraft-nerd-fonts-patched.ttc" \
    "https://github.com/IdreesInc/Monocraft/releases/latest/download/Monocraft-nerd-fonts-patched.ttc"
fc-cache -f "$HOME/.local/share/fonts" >/dev/null

echo "==> GTK4/gsettings (icon theme, font, cursor)"
# The gtk-3.0/settings.ini just linked in covers GTK3 and Qt/KDE apps, but
# GTK4 apps mostly ignore that file and read these from gsettings instead —
# without this, icons/font/cursor silently fall back to stock GTK4 apps
# (and quickshell's own Theme.qml reads font-name from here too, so this is
# also why some quickshell text was falling back to a generic font).
if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
    gsettings set org.gnome.desktop.interface gtk-theme 'Breeze'
    gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Classic'
    gsettings set org.gnome.desktop.interface font-name 'Monocraft 10'
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
else
    echo "  gsettings not found, skipping (install gsettings-desktop-schemas/dconf)"
fi

echo "==> Display (only works if driftwm is already running — skipped on a bare-TTY first install)"
# Picks the mode with the highest resolution, then highest refresh rate at
# that resolution, applies it live, and asks for a scale factor — then
# writes both into config.toml's [[outputs]] and kanshi/config so they
# survive a reboot, the same two places DisplaySection.qml's own apply()
# writes to.
if command -v wlr-randr >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    best="$(wlr-randr --json 2>/dev/null | jq -r '
        .[] | select(.enabled) | .name as $n |
        (.modes | (map(.width * .height) | max)) as $maxres |
        ([.modes[] | select(.width * .height == $maxres)] | max_by(.refresh)) as $m |
        "\($n) \($m.width) \($m.height) \($m.refresh) \($m.refresh | round)"
    ' 2>/dev/null | head -n1)"
    if [ -n "$best" ]; then
        set -- $best
        out="$1" w="$2" h="$3" r="$4" r_int="$5"
        mode="${w}x${h}@${r_int}"
        echo "  $out: best mode is $mode"
        wlr-randr --output "$out" --mode "${w}x${h}@${r}Hz" 2>/dev/null || true

        scale="1.0"
        if [ -t 0 ]; then
            printf '  Scale? (e.g. 1.0, 1.25, 1.5, 2.0) [1.0]: '
            read -r reply
            case "$reply" in
                "") ;;
                [0-9]*.[0-9]*|[0-9]*) scale="$reply" ;;
                *) echo "  not a number, keeping 1.0" ;;
            esac
        fi
        wlr-randr --output "$out" --scale "$scale" 2>/dev/null || true

        sed -i \
            -e "s|^name = .*|name = \"$out\"|" \
            -e "s|^mode = .*|mode = \"$mode\"|" \
            -e "s|^scale = .*|scale = $scale|" \
            "$CONFIG_HOME/driftwm/config.toml"
        [ -f "$CONFIG_HOME/kanshi/config" ] && \
            sed -i "s|output [A-Za-z0-9-]* mode [0-9x@.]*|output $out mode $mode|" "$CONFIG_HOME/kanshi/config"
        kanshictl reload 2>/dev/null || true
    else
        echo "  no enabled output found (driftwm not running?), skipping"
    fi
else
    echo "  wlr-randr/jq not found, skipping"
fi

echo "==> Clipboard history watchers (for this session; the driftwm autostart entries in config.toml cover future logins)"
pgrep -f "wl-paste --type text --watch cliphist" >/dev/null 2>&1 || \
    (wl-paste --type text --watch cliphist store &) 2>/dev/null || true
pgrep -f "wl-paste --type image --watch cliphist" >/dev/null 2>&1 || \
    (wl-paste --type image --watch cliphist store &) 2>/dev/null || true

cat <<EOF

Done. Log out and back into driftwm to pick everything up (or manually
restart waybar/swaync/qs and re-\`fc-cache\` if you're mid-session).
EOF
