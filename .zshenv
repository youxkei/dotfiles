#zmodload zsh/zprof && zprof

export PATH="$HOME/.anyenv/bin:$HOME/.linuxbrew/bin:$HOME/.go/bin:$PATH"
export MANPATH="$HOME/.linuxbrew/share/man:$MANPATH"
export INFOPATH="$HOME/.linuxbrew/share/info:$INFOPATH"

eval "$(anyenv init -)"
export GOPATH="$HOME/.go"
