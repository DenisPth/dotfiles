# ~/.zshrc — dark_sea

## Shell options (ex-manjaro-zsh-config; OMZ doesn't set these)
setopt correct                # Auto correct mistakes
setopt extendedglob           # Extended globbing — regex with *
setopt nocaseglob             # Case insensitive globbing
setopt rcexpandparam          # Array expansion with parameters
setopt nocheckjobs            # Don't warn about running jobs on exit
setopt numericglobsort        # Sort filenames numerically when it makes sense
setopt nobeep
setopt appendhistory
setopt histignorealldups
setopt autocd                 # A bare path cds into it
setopt inc_append_history
setopt histignorespace        # Leading-space commands are not saved

HISTFILE=~/.zhistory
HISTSIZE=10000
SAVEHIST=10000
WORDCHARS=${WORDCHARS//\/[&.;]}

## Completion styling
zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' rehash true
zstyle ':completion:*' menu select
zstyle ':completion:*' accept-exact '*(N)'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache

## Keybindings
bindkey -e
bindkey '^[[7~' beginning-of-line
bindkey '^[[H'  beginning-of-line
[[ -n "${terminfo[khome]}" ]] && bindkey "${terminfo[khome]}" beginning-of-line
bindkey '^[[8~' end-of-line
bindkey '^[[F'  end-of-line
[[ -n "${terminfo[kend]}" ]] && bindkey "${terminfo[kend]}" end-of-line
bindkey '^[[2~' overwrite-mode
bindkey '^[[3~' delete-char
bindkey '^[[C'  forward-char
bindkey '^[[D'  backward-char
bindkey '^[Oc' forward-word
bindkey '^[Od' backward-word
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word
bindkey '^H' backward-kill-word        # ctrl+backspace: delete previous word
bindkey '^[[Z' undo                    # shift+tab: undo

## Aliases
alias cp="cp -i"
alias df='df -h'
alias free='free -m'
alias gitu='git add . && git commit && git push'

## Colors — dircolors for completion lists (eza gets its own palette below)
eval "$(dircolors -b)"

# eza — file-type icons/colors matched to the dark_sea palette (same hues as
# foot/kitty/waybar/kdeglobals). 38;2;r;g;b = truecolor.
export EZA_COLORS="\
di=38;2;151;214;255:\
ln=38;2;127;166;160:\
ex=38;2;138;154;124:\
or=38;2;181;102;95:\
pi=38;2;154;138;160:\
so=38;2;201;185;138:\
bd=38;2;90;99;106:\
cd=38;2;90;99;106:\
su=38;2;181;102;95:\
sg=38;2;181;102;95:\
tw=38;2;181;102;95:\
ow=38;2;181;102;95"

## Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"

# eza plugin config (must precede the plugins= load below)
zstyle ':omz:plugins:eza' 'dirs-first' yes
zstyle ':omz:plugins:eza' 'icons' yes
zstyle ':omz:plugins:eza' 'git-status' yes

plugins=(
    git                     # git aliases (gst, gco, gcb, gp, gl…)
    sudo                    # Esc Esc: prepend sudo to the command
    extract                 # x archive.tar.gz
    colored-man-pages
    command-not-found       # backend auto-detected (pkgfile on Arch, dnf on Fedora)
    dirhistory              # alt+←/→/↑ through directory history
    copypath                # copy pwd/file path to the clipboard
    copyfile                # copy a file's contents to the clipboard
    web-search              # google "query"
    jsontools               # pp_json, is_json…
    encode64
    urltools                # urlencode/urldecode
    systemd                 # sc/scu/scr, jctl…
    fzf                     # ctrl+r/ctrl+t/alt+c fuzzy widgets
    eza                     # ls/ll/la… → eza, icons on
    zoxide                  # z — frecency-based cd
    history-substring-search
)
# pacman/yay short aliases — only make sense where pacman actually exists.
command -v pacman >/dev/null 2>&1 && plugins+=(archlinux)

# Theme is Powerlevel10k, but from the system package (not an OMZ custom
# theme) — loaded manually below, same as before this migration.
ZSH_THEME=""

source $ZSH/oh-my-zsh.sh

# Autosuggestions + syntax highlighting — prefer install.sh's git clone into
# $ZSH_CUSTOM (same path on every distro), fall back to the Arch package
# paths (/usr/share/...) if that clone was never run on this machine. Syntax
# highlighting must load last, after everything else that defines widgets
# (autosuggestions included), or the two fight over keybindings.
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#4b5560'
for f in \
    "$ZSH_CUSTOM/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" \
    "/usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
do
    [[ -e "$f" ]] && { source "$f"; break }
done
for f in \
    "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" \
    "/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
do
    [[ -e "$f" ]] && { source "$f"; break }
done

# Powerlevel10k — цвета под тему dark_sea (та же палитра, что у всей системы).
for f in \
    "$ZSH_CUSTOM/themes/powerlevel10k/powerlevel10k.zsh-theme" \
    "/usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme"
do
    [[ -e "$f" ]] && { source "$f"; break }
done
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

## dotfiles version check — repo (~/dotfiles) HEAD vs. what update.sh/
## install.sh last actually applied. Only interactive+tty shells get asked,
## so this stays silent under scp, VS Code remote, cron, etc.
if [[ -o interactive && -t 0 && -d ~/dotfiles/.git ]]; then
    _df_head="$(git -C ~/dotfiles rev-parse HEAD 2>/dev/null)"
    _df_installed="$(<~/dotfiles/.installed_version 2>/dev/null)"
    if [[ -n "$_df_head" && "$_df_head" != "$_df_installed" ]]; then
        _df_n="$(git -C ~/dotfiles rev-list --count "${_df_installed:-$_df_head}..$_df_head" 2>/dev/null)"
        echo "dotfiles: доступно обновление (${_df_n:-?} коммитов новее установленной версии)."
        printf "Обновить сейчас (симлинки конфигов, настройки сохранятся)? [y/N] "
        read -r _df_reply
        if [[ "$_df_reply" == [Yy]* ]]; then
            ~/dotfiles/update.sh
        fi
    fi
    unset _df_head _df_installed _df_n _df_reply
fi
