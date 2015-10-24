#zmodload zsh/zprof && zprof

export PATH="$HOME/.linuxbrew/bin:$PATH"
export PATH="$HOME/.anyenv/bin:$PATH"
export PATH="$HOME/.go/bin:$PATH"
export PATH="$HOME/Android/Sdk/platform-tools:$PATH"
export PATH="$HOME/android-studio/bin:$PATH"
export PATH="$HOME/bin:$PATH"

export MANPATH="$HOME/.linuxbrew/share/man:$MANPATH"
export INFOPATH="$HOME/.linuxbrew/share/info:$INFOPATH"

eval "$(anyenv init -)"
export GOPATH="$HOME/.go"
export NVIM_TUI_ENABLE_TRUE_COLOR=1
