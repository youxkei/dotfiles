export EDITOR=nvim
export VISUAL=nvim
export MANPAGER='nvim -c MANPAGER -'

typeset -U path

path=(
    ~/.local/bin(N-/)
    ~/.erlenv/bin(N-/)
    ~/go/bin(N-/)
    ~/.cabal/bin(N-/)
    ~/.cargo/bin(N-/)
    ~/Android/Sdk/platform-tools(N-/)
    ~/android-studio/bin(N-/)
    ~/bin(N-/)
    ~/repo/vdmc/bin(N-/)
    $path
)

ZPLG_HOME=$HOME/.zplugin

export ANDROID_HOME="$HOME/Android/Sdk"

export XDG_CURRENT_DESKTOP="Unity:Unity7"
