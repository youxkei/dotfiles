# Set up the prompt

# autoload -Uz promptinit
# promptinit
# prompt adam1

# Use emacs keybindings even if our EDITOR is set to vi
bindkey -e

setopt histignorealldups sharehistory
setopt hist_ignore_space
HISTSIZE=1000
SAVEHIST=100000
HISTFILE=~/.zsh_history

# Use modern completion system
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

setopt auto_cd
setopt auto_pushd

alias ls='ls -hF --color=auto'
alias ll='ls -al'
alias la='ls -A'
alias l='ls -CF'
alias ainst="sudo apt-get install"
alias open="xdg-open"
alias tmux="tmux -2"

function chpwd() { ls }

if (which zprof > /dev/null) ;then
    zprof | less
fi

# OPAM configuration
. ~/.opam/opam-init/init.zsh > /dev/null 2> /dev/null || true

if [[ -f ~/repo/antigen/antigen.zsh ]]; then
    source ~/repo/antigen/antigen.zsh

    antigen use oh-my-zsh

    export ENHANCD_COMMAND="ecd"
    antigen bundle b4b4r07/enhancd
    antigen bundle mollifier/anyframe
    antigen bundle zsh-users/zsh-history-substring-search
    antigen bundle zsh-users/zsh-autosuggestions
    antigen bundle zsh-users/zsh-syntax-highlighting
    antigen bundle soimort/translate-shell

    antigen theme ys

    antigen apply

    bindkey -M emacs '^P' history-substring-search-up
    bindkey -M emacs '^N' history-substring-search-down
fi
