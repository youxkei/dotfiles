bindkey -e

# zinit {{{
declare -A ZINIT=(
  BIN_DIR  $XDG_CACHE_HOME/zinit/bin
  HOME_DIR $XDG_CACHE_HOME/zinit
)

if [[ ! -d $ZINIT[BIN_DIR] ]]; then
  if whence git > /dev/null; then
    git clone --depth 1 https://github.com/zdharma-continuum/zinit.git $ZINIT[BIN_DIR]
  fi
fi

source $ZINIT[BIN_DIR]/zinit.zsh

# sync {{{
zinit light momo-lab/zsh-abbrev-alias
abbrev-alias -g -e CI='$(git tree --color | fzf | grep -Po "\\w.*$" | awk "{print \$1}")'
abbrev-alias -g -e B='$(git tree --color | fzf | grep -Po "\\w.*$" | awk "{print \$1}" | xargs -I{} bash -c "git branch -av | grep {} | fzf -0 -1 | cut -c3- | awk \"{print \\\$1}\"")'
abbrev-alias -g -e PS='$(procs -c always | fzf --header-lines 1 | awk "{print \$1}")'
abbrev-alias -g -e DP='$(docker ps | tail -n +2 | fzf | awk "{print \$1}")'
# sync }}}

# async {{{
zinit ice lucid wait"0"
zinit light zsh-users/zsh-history-substring-search

zinit ice lucid wait"0" atload'_zsh_autosuggest_start'
zinit light zsh-users/zsh-autosuggestions

zinit ice lucid wait"0"
zinit light zsh-users/zsh-syntax-highlighting

zinit ice lucid wait"0"
zinit light zsh-users/zsh-completions

zinit ice lucid wait"0" src"git-escape-magic"
zinit light knu/zsh-git-escape-magic

zinit ice lucid wait"0"
zinit light zpm-zsh/undollar
# async }}}

# zinit }}}

# zi is introduced by zinit
unalias zi


stty intr '^\'
stty quit undef
stty lnext undef

setopt auto_pushd
setopt hist_ignore_space
setopt histignorealldups
setopt inc_append_history
setopt sharehistory

HISTSIZE=100000
SAVEHIST=100000
export HISTFILE=$XDG_DATA_HOME/zsh/history

[[ -x "$(which mcfly)"     ]] && eval "$(mcfly init zsh)"
[[ -x "$(which starship)"  ]] && eval "$(starship init zsh)"
[[ -x "$(which zoxide)"    ]] && eval "$(zoxide init zsh)"
[[ -x "$(which direnv)"    ]] && eval "$(direnv hook zsh)"
[[ -x "$(which nix-build)" ]] && export LD_PRELOAD="$(nix-build '<nixpkgs>' -A stderred --no-out-link)/lib/libstderred.so${LD_PRELOAD:+:$LD_PRELOAD}"

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

autoload -Uz zmv
alias zmv='noglob zmv -W'

eval "$(dircolors -b | perl -pe 's/\b01\b/1/g; s/\b00\b/0/g')"
export EXA_COLORS="lp=1;36"
export FZF_DEFAULT_OPTS="--reverse --ansi"

export LESS='-SR'

alias ls='exa -h --color=auto'
alias ll='ls -al'
alias tmux="tmux -2"
alias cp="xcp"

function chpwd() { ls }

bindkey -M emacs '^P' history-substring-search-up
bindkey -M emacs '^N' history-substring-search-down

re-prompt() {
  starship_precmd
  zle .reset-prompt
  zle .accept-line
}

# zle -N accept-line re-prompt

function git() {
  git-branchless wrap -- $@
}

[[ -e $ZDOTDIR/.zshrc_host ]] && source $ZDOTDIR/.zshrc_host
# vim:set expandtab shiftwidth=2 softtabstop=2 tabstop=2 foldenable foldmethod=marker:
