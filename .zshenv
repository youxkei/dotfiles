#zmodload zsh/zprof && zprof

path=(~/.anyenv/bin $path)
eval "$(anyenv init -)"

path=(
    ~/.go/bin
    ~/Android/Sdk/platform-tools
    ~/android-studio/bin
    ~/bin
    $path
)

eval "$(hub alias -s)"
unalias git
function git() { hub $@; }

export GOPATH="$HOME/.go"

export ANDROID_HOME="$HOME/Android/Sdk"

export XDG_CURRENT_DESKTOP="Unity"
