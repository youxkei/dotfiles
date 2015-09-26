#zmodload zsh/zprof && zprof

export PATH="$HOME/.anyenv/bin:$HOME/.linuxbrew/bin:$HOME/.go/bin:$HOME/android-studio/bin:$PATH"
export MANPATH="$HOME/.linuxbrew/share/man:$MANPATH"
export INFOPATH="$HOME/.linuxbrew/share/info:$INFOPATH"

eval "$(anyenv init -)"
export GOPATH="$HOME/.go"
export NVIM_TUI_ENABLE_TRUE_COLOR=1
