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

# command {{{
zplugin ice lucid from"gh-r" wait"0" as"program" bpick"*x86_64*musl*" mv"tokei -> ${ZPFX}/bin/tokei"
zplugin light Aaronepower/tokei

zplugin ice lucid wait"0" from"gh-r" as"program" mv"fzf -> ${ZPFX}/bin/fzf"
zplugin light junegunn/fzf-bin
export FZF_DEFAULT_OPTS="--reverse --ansi"

zplugin ice lucid from"gh-r" wait"0" as"program" bpick"*x86_64*musl*" mv"ripgrep*/rg -> ${ZPFX}/bin/rg"
zplugin light BurntSushi/ripgrep

zplugin ice lucid from"gh-r" wait"0" as"program" bpick"*linux*amd64*" mv"hub*/bin/hub -> ${ZPFX}/bin/hub"
zplugin light github/hub

zplugin ice lucid from"gh-r" wait"0" as"program" bpick"*x86_64*musl*" mv"fd*/fd -> ${ZPFX}/bin/fd"
zplugin light sharkdp/fd

zplugin ice lucid from"gh-r" wait"0" as"program" bpick"*linux*x86_64*" mv"exa* -> ${ZPFX}/bin/exa"
zplugin light ogham/exa
# command }}}

# zplugin }}}

bindkey -e

setopt histignorealldups
setopt sharehistory
setopt inc_append_history
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




if [[ ! -d ~/.zplug ]]; then
  git clone https://github.com/zplug/zplug ~/.zplug
fi

source ~/.zplug/init.zsh


# command
zplug "soimort/translate-shell", at:stable, as:command, use:"build/*", hook-build:"make build"

zplug "creationix/nvm", use:nvm.sh


# extension
zplug "zplug/zplug", hook-build:"zplug --self-manage"

zplug "b4b4r07/enhancd", use:init.sh
export ENHANCD_COMMAND="cd"
export ENHANCD_FILTER="fzf"
export ENHANCD_DISABLE_DOT=1

zplug "zsh-users/zsh-history-substring-search"

zplug "zsh-users/zsh-autosuggestions"

zplug "zsh-users/zsh-syntax-highlighting", defer:2

zplug "zsh-users/zsh-completions", defer:2

zplug "momo-lab/zsh-abbrev-alias"

# theme
zplug "bhilburn/powerlevel9k", use:powerlevel9k.zsh-theme, as:theme
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

if ! zplug check; then
  echo; zplug install
fi

zplug load

if (( ${+commands[hub]} )); then
  eval "$(hub alias -s)"
  unalias git
  function git() { hub $@; }
fi

abbrev-alias -f CI="git tree --color | fzf | grep -Po '\\w.*$' | awk '{print \$1}'"
abbrev-alias -f B="git tree --color | fzf | grep -Po '\\w.*$' | awk '{print \$1}' | xargs -I{} bash -c \"git branch -av | grep {} | fzf -0 -1 | cut -c3- | awk '{print \\\$1}'\""

bindkey -M emacs '^P' history-substring-search-up
bindkey -M emacs '^N' history-substring-search-down

re-prompt() {
  zle .reset-prompt
  zle .accept-line
}

zle -N accept-line re-prompt
# vim:set expandtab shiftwidth=2 softtabstop=2 tabstop=2 foldenable foldmethod=marker:
