# Use powerline
USE_POWERLINE="true"
# Has weird character width
HAS_WIDECHARS="false"

# Source manjaro-zsh-configuration
if [[ -e /usr/share/zsh/manjaro-zsh-config ]]; then
  source /usr/share/zsh/manjaro-zsh-config
fi
# Use manjaro zsh prompt
if [[ -e /usr/share/zsh/manjaro-zsh-prompt ]]; then
  source /usr/share/zsh/manjaro-zsh-prompt
fi

# ПРИНУДИТЕЛЬНОЕ ЛЕЧЕНИЕ ОШИБКИ:
autoload -Uz compinit
compinit -i

# Подсветка синтаксиса — должна подключаться последней (после автоподсказок,
# которые уже тянет manjaro-zsh-prompt), иначе виджеты друг другу мешают.
if [[ -e /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# Powerlevel10k — цвета под тему dark_sea (та же палитра, что у всей системы).
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

