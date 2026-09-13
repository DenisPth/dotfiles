# ~/.p10k.zsh — Powerlevel10k, цвета под тему dark_sea (та же палитра,
# что у foot/kitty/waybar/quickshell/Zed). Написан вручную, без визарда
# `p10k configure` — не переживёт `p10k configure`, только ручные правки.

'builtin' 'local' '-a' 'p10k_config_opts'
[[ ! -o 'aliases'         ]] || p10k_config_opts+=('aliases')
[[ ! -o 'sh_glob'         ]] || p10k_config_opts+=('sh_glob')
[[ ! -o 'no_brace_expand' ]] || p10k_config_opts+=('no_brace_expand')
'builtin' 'setopt' 'no_aliases' 'no_sh_glob' 'brace_expand'

() {
  emulate -L zsh -o extended_glob

  typeset -g POWERLEVEL9K_MODE=nerdfont-complete
  typeset -g POWERLEVEL9K_ICON_PADDING=moderate
  typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true

  typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir vcs newline prompt_char)
  typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status command_execution_time background_jobs time)

  typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX='%F{#4b5560}╭─%f'
  typeset -g POWERLEVEL9K_MULTILINE_NEWLINE_PROMPT_PREFIX='%F{#4b5560}├─%f'
  typeset -g POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX='%F{#4b5560}╰─%f'
  typeset -g POWERLEVEL9K_MULTILINE_LAST_PROMPT_SUFFIX=

  # dir
  typeset -g POWERLEVEL9K_DIR_BACKGROUND='#333b45'
  typeset -g POWERLEVEL9K_DIR_FOREGROUND='#e2ddc4'
  typeset -g POWERLEVEL9K_DIR_ANCHOR_FOREGROUND='#c9c4ab'
  typeset -g POWERLEVEL9K_SHORTEN_STRATEGY=truncate_to_unique
  typeset -g POWERLEVEL9K_SHORTEN_DIR_LENGTH=2

  # vcs (git)
  typeset -g POWERLEVEL9K_VCS_CLEAN_BACKGROUND='#8a9a7c'
  typeset -g POWERLEVEL9K_VCS_CLEAN_FOREGROUND='#2b323c'
  typeset -g POWERLEVEL9K_VCS_MODIFIED_BACKGROUND='#c9b98a'
  typeset -g POWERLEVEL9K_VCS_MODIFIED_FOREGROUND='#2b323c'
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_BACKGROUND='#7fa6a0'
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND='#2b323c'
  typeset -g POWERLEVEL9K_VCS_LOADING_BACKGROUND='#4b5560'
  typeset -g POWERLEVEL9K_VCS_LOADING_FOREGROUND='#c9c4ab'

  # prompt_char (цвет промпт-символа по коду выхода последней команды)
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND='#7089a0'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND='#b5665f'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIINS_CONTENT_EXPANSION='❯'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VICMD_CONTENT_EXPANSION='❮'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL=''

  # status / время выполнения / фоновые задачи / часы (правая часть)
  typeset -g POWERLEVEL9K_STATUS_OK=false
  typeset -g POWERLEVEL9K_STATUS_ERROR_BACKGROUND='#b5665f'
  typeset -g POWERLEVEL9K_STATUS_ERROR_FOREGROUND='#2b323c'

  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=3
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_BACKGROUND='#4b5560'
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND='#e2ddc4'

  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_BACKGROUND='#333b45'
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_FOREGROUND='#7fa6a0'

  typeset -g POWERLEVEL9K_TIME_BACKGROUND='#2b323c'
  typeset -g POWERLEVEL9K_TIME_FOREGROUND='#8f8a72'
  typeset -g POWERLEVEL9K_TIME_FORMAT='%D{%H:%M:%S}'

  typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
  typeset -g POWERLEVEL9K_DISABLE_HOT_RELOAD=true
}

(( ${#p10k_config_opts} )) && setopt ${p10k_config_opts[@]}
'builtin' 'unset' 'p10k_config_opts'
