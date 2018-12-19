export EDITOR=nvim
export VISUAL=nvim
export MANPAGER='nvim -c MANPAGER -'

PATH=~/.local/bin:$PATH
PATH=~/go/bin:$PATH
PATH=~/.cargo/bin:$PATH
PATH=~/bin:$PATH
export PATH

export ZPLG_HOME=$HOME/.zplugin

export ANDROID_HOME="$HOME/Android/Sdk"

source ~/.nix-profile/etc/profile.d/nix.sh >/dev/null 2>/dev/null || true
source ~/.opam/opam-init/init.zsh >/dev/null 2>/dev/null || true
