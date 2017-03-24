#zmodload zsh/zprof && zprof

path=(
    ~/.anyenv/bin
    ~/.go/bin
    ~/Android/Sdk/platform-tools
    ~/android-studio/bin
    ~/bin
    $path
)

(( ${+commands[anyenv]} )) && eval "$(anyenv init -)"
if (( ${+commands[hub]} )); then
    eval "$(hub alias -s)"
    unalias git
    function git() { hub $@; }
fi

export GOPATH="$HOME/.go"

export ANDROID_HOME="$HOME/Android/Sdk"

export XDG_CURRENT_DESKTOP="Unity"
