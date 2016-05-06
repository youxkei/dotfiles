#zmodload zsh/zprof && zprof

path=(~/.anyenv/bin $path)
eval "$(anyenv init -)"

path=(
    ~/.linuxbrew/bin
    ~/.go/bin
    ~/Android/Sdk/platform-tools
    ~/android-studio/bin
    ~/bin
    $path
)

eval "$(hub alias -s)"

export MANPATH="$HOME/.linuxbrew/share/man:$MANPATH"
export INFOPATH="$HOME/.linuxbrew/share/info:$INFOPATH"

export GOPATH="$HOME/.go"

export ANDROID_HOME="$HOME/Android/Sdk"
