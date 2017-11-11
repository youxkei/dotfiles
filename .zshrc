bindkey -e

setopt histignorealldups sharehistory
setopt hist_ignore_space
HISTSIZE=1000
SAVEHIST=100000
HISTFILE=~/.zsh_history

autoload -Uz compinit
compinit -C

zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete _correct _approximate
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' menu select=2
eval "$(dircolors -b)"
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
zstyle ':completion:*' menu select=long
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' verbose true

zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

setopt auto_pushd

alias ls='ls -hF --color=auto'
alias ll='ls -al'
alias la='ls -A'
alias l='ls -CF'
alias open="xdg-open"
alias tmux="tmux -2"
alias tig="tig --all"

function chpwd() { ls }

source ~/.opam/opam-init/init.zsh > /dev/null 2> /dev/null || true

if (( ${+commands[hub]} )); then
  eval "$(hub alias -s)"
  unalias git
  function git() { hub $@; }
fi

if [[ ! -d ~/.zplug ]]; then
  git clone https://github.com/zplug/zplug ~/.zplug
fi

source ~/.zplug/init.zsh


# command
zplug "jhawthorn/fzy", as:command, use:fzy, hook-build:make
zplug "soimort/translate-shell", at:stable, as:command, use:"build/*", hook-build:"make build"

# extension
zplug "zplug/zplug", hook-build:"zplug --self-manage"

zplug "b4b4r07/enhancd", use:init.sh
ENHANCD_COMMAND="cd"
ENHANCD_FILTER="fzy"
ENHANCD_DISABLE_DOT=1

zplug "zsh-users/zsh-history-substring-search"

zplug "zsh-users/zsh-autosuggestions"

zplug "zsh-users/zsh-syntax-highlighting", defer:2

zplug "zsh-users/zsh-completions", defer:2

# theme
zplug "bhilburn/powerlevel9k", use:powerlevel9k.zsh-theme, as:theme
POWERLEVEL9K_PROMPT_ON_NEWLINE=true
POWERLEVEL9K_DIR_HOME_BACKGROUND="068"
POWERLEVEL9K_DIR_HOME_FOREGROUND="015"
POWERLEVEL9K_DIR_HOME_SUBFOLDER_BACKGROUND="068"
POWERLEVEL9K_DIR_HOME_SUBFOLDER_FOREGROUND="015"
POWERLEVEL9K_DIR_DEFAULT_BACKGROUND="068"
POWERLEVEL9K_DIR_DEFAULT_FOREGROUND="015"
POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX=""
POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX="$ "
POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=0
POWERLEVEL9K_COMMAND_EXECUTION_TIME_BACKGROUND="068"
POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND="015"
POWERLEVEL9K_EXECUTION_TIME_ICON="s"
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(context dir vcs time)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status command_execution_time root_indicator background_jobs history)

if ! zplug check; then
  echo; zplug install
fi

zplug load

bindkey -M emacs '^P' history-substring-search-up
bindkey -M emacs '^N' history-substring-search-down

re-prompt() {
    zle .reset-prompt
    zle .accept-line
}

zle -N accept-line re-prompt
