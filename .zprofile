export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libgtk3-nocsd.so.0

export EDITOR=nvim
export VISUAL=nvim
export MANPAGER='nvim -c MANPAGER -'

typeset -U path

path=(
    ~/.local/bin(N-/)
    ~/go/bin(N-/)
    ~/.cargo/bin(N-/)
    ~/bin(N-/)
    $path
)

export ZPLG_HOME=$HOME/.zplugin

export ANDROID_HOME="$HOME/Android/Sdk"

if [ -e /home/youxkei/.nix-profile/etc/profile.d/nix.sh ]; then
  source /home/youxkei/.nix-profile/etc/profile.d/nix.sh
fi
