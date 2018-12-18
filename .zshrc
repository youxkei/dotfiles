bindkey -e

# zplugin {{{

if [[ ! -d $ZPLG_HOME/bin ]]; then
  if whence git > /dev/null; then
    git clone --depth 1 https://github.com/zdharma/zplugin.git $ZPLG_HOME/bin
  fi
fi

if [[ ! -d $ZPFX ]]; then
  mkdir -p $ZPFX/bin
fi

if [[ ! -d $ZPLG_HOME/misc ]]; then
  mkdir -p $ZPLG_HOME/misc
fi

source $ZPLG_HOME/bin/zplugin.zsh

# sync {{{
zplugin light momo-lab/zsh-abbrev-alias
abbrev-alias -f CI="git tree --color | sk | grep -Po '\\w.*$' | awk '{print \$1}'"
abbrev-alias -f B="git tree --color | sk | grep -Po '\\w.*$' | awk '{print \$1}' | xargs -I{} bash -c \"git branch -av | grep {} | fzf -0 -1 | cut -c3- | awk '{print \\\$1}'\""
abbrev-alias -f PS="ps aux | tail -n +2 | sk | awk '{print \$2}'"
abbrev-alias -f DP="docker ps | tail -n +2 | sk | awk '{print \$1}'"

zplugin light bhilburn/powerlevel9k
export POWERLEVEL9K_PROMPT_ON_NEWLINE=true
export POWERLEVEL9K_PROMPT_ADD_NEWLINE=true
export POWERLEVEL9K_DIR_HOME_BACKGROUND="027"
export POWERLEVEL9K_DIR_HOME_FOREGROUND="015"
export POWERLEVEL9K_DIR_HOME_SUBFOLDER_BACKGROUND="027"
export POWERLEVEL9K_DIR_HOME_SUBFOLDER_FOREGROUND="015"
export POWERLEVEL9K_DIR_DEFAULT_BACKGROUND="027"
export POWERLEVEL9K_DIR_DEFAULT_FOREGROUND="015"
export POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX=""
export POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX="$ "
export POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=0
export POWERLEVEL9K_COMMAND_EXECUTION_TIME_BACKGROUND="027"
export POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND="015"
export POWERLEVEL9K_EXECUTION_TIME_ICON="s"
export POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(context dir vcs time)
export POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status command_execution_time root_indicator background_jobs history)

zplugin ice lucid wait"0"
zplugin light zsh-users/zsh-history-substring-search

zplugin ice lucid wait"0" atload'_zsh_autosuggest_start'
zplugin light zsh-users/zsh-autosuggestions

zplugin ice lucid wait"0"
zplugin light zsh-users/zsh-syntax-highlighting

zplugin ice lucid wait"0"
zplugin light zsh-users/zsh-completions
# sync }}}

# async {{{
zplugin ice lucid wait"0" pick"nvm.sh"
zplugin light creationix/nvm

zplugin ice lucid wait"0" pick"init.sh"
zplugin light b4b4r07/enhancd
export ENHANCD_COMMAND="cd"
export ENHANCD_FILTER="sk20"
export ENHANCD_DISABLE_DOT=1
# async }}}

# zplugin }}}

setopt auto_pushd
setopt auto_cd
setopt hist_ignore_space
setopt histignorealldups
setopt inc_append_history
setopt sharehistory

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

export SKIM_DEFAULT_OPTIONS="--reverse --ansi"

alias ls='ls -hF --color=auto'
alias ll='ls -al'
alias la='ls -A'
alias l='ls -CF'
alias open="xdg-open"
alias tmux="tmux -2"
alias tig="tig --all"
alias sk20="sk --height=20%"

function chpwd() { ls }

source ~/.opam/opam-init/init.zsh > /dev/null 2> /dev/null || true

bindkey -M emacs '^P' history-substring-search-up
bindkey -M emacs '^N' history-substring-search-down

re-prompt() {
  zle .reset-prompt
  zle .accept-line
}

zle -N accept-line re-prompt
# vim:set expandtab shiftwidth=2 softtabstop=2 tabstop=2 foldenable foldmethod=marker:
