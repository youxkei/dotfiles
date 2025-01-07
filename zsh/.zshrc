bindkey -e

setopt auto_pushd
setopt hist_ignore_space
setopt histignorealldups
setopt inc_append_history
setopt sharehistory

HISTSIZE=100000
SAVEHIST=100000
export HISTFILE=$XDG_DATA_HOME/zsh/history

[[ ! -d $XDG_CACHE_HOME/zsh ]] && mkdir -p $XDG_CACHE_HOME/zsh

autoload -Uz compinit && compinit -d $XDG_CACHE_HOME/zsh/compdump

zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete _correct _approximate
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' menu select=2
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

[[ -x "$(which mcfly)"    ]] && eval "$(mcfly init zsh)"
[[ -x "$(which starship)" ]] && eval "$(starship init zsh)"
[[ -x "$(which zoxide)"   ]] && eval "$(zoxide init zsh)"
[[ -x "$(which direnv)"   ]] && eval "$(direnv hook zsh)"
[[ -x "$(which eza)"      ]] && alias ls='eza -h --color=auto'
[[ -x "$(which xcp)"      ]] && alias cp="xcp"

if [[ -x "$(which sheldon)"  ]]; then
  eval "$(sheldon source)"

  abbrev-alias -g -e CI='$(git tree --color | fzf | grep -Po "\\w.*$" | awk "{print \$1}")'
  abbrev-alias -g -e B='$(git tree --color | fzf | grep -Po "\\w.*$" | awk "{print \$1}" | xargs -I{} bash -c "git branch -av | grep {} | fzf -0 -1 | cut -c3- | awk \"{print \\\$1}\"")'
  abbrev-alias -g -e PS='$(procs -c always | fzf --header-lines 1 | awk "{print \$1}")'
  abbrev-alias -g -e DP='$(docker ps | tail -n +2 | fzf | awk "{print \$1}")'
fi

autoload -Uz zmv
alias zmv='noglob zmv -W'

autoload -U select-word-style
select-word-style bash

eval "$(dircolors -b | perl -pe 's/\b01\b/1/g; s/\b00\b/0/g')"
export EXA_COLORS="lp=1;36"
export FZF_DEFAULT_OPTS="--reverse --ansi"

export LESS='-SR'

# https://github.com/ajeetdsouza/zoxide/blob/18001773f35fba7bd46571c6edc0e8dfd7fd83ac/src/cmd/query.rs#L81-L101
# https://github.com/ajeetdsouza/zoxide/blob/18001773f35fba7bd46571c6edc0e8dfd7fd83ac/src/util.rs#L60-L81
export _ZO_FZF_OPTS='--no-sort --bind=ctrl-z:ignore,btab:up,tab:down --cycle --keep-right --border=sharp --height=45% --info=inline --layout=reverse --tabstop=1 --exit-0 --select-1 --preview="\\command -p ls -Cp --color=always --group-directories-first {2..}" --preview-window=down,30%,sharp'

alias ll='ls -al'
alias tmux="tmux -2"

function chpwd() { ls }

bindkey -M emacs '^P' history-substring-search-up
bindkey -M emacs '^N' history-substring-search-down

function re-prompt() {
  starship_precmd
  zle .reset-prompt
  zle .accept-line
}

# zle -N accept-line re-prompt

[[ -e $ZDOTDIR/.zshrc_host ]] && source $ZDOTDIR/.zshrc_host
# vim:set expandtab shiftwidth=2 softtabstop=2 tabstop=2 foldenable foldmethod=marker:
