export LOCALE_ARCHIVE=/usr/lib/locale/locale-archive

export EDITOR=nvim
export VISUAL=nvim
export MANPAGER='nvim -c ASMANPAGER -'

export BROWSER=wslview

export ANDROID_HOME=~/Android/Sdk

export XDG_CONFIG_HOME=~/.config
export XDG_CACHE_HOME=~/.cache
export XDG_DATA_HOME=~/.local/share

export ZDOTDIR=$XDG_CONFIG_HOME/zsh
export skip_global_compinit=1

export QT_AUTO_SCREEN_SCALE_FACTOR=0

export GLFW_IM_MODULE=ibus

export PNPM_HOME=$XDG_DATA_HOME/pnpm

export OP_ACCOUNT=my.1password.com

if [ -e ~/.profile_host ]; then . ~/.profile_host; fi
if [ -e ~/.nix-profile/etc/profile.d/nix.sh ]; then . ~/.nix-profile/etc/profile.d/nix.sh; fi
if [ -e ~/.cargo/env ]; then . ~/.cargo/env; fi

if [ -x "$(which nix-build)" ]; then
    export LD_PRELOAD="$(nix-build '<nixpkgs>' -A stderred --no-out-link)/lib/libstderred.so${LD_PRELOAD:+:$LD_PRELOAD}"
fi

PATH=$PNPM_HOME:~/bin:~/go/bin:$PATH
export PATH

if [ ! -e ~/windows ] && [ -x "$(which wslvar)" ]; then
    ln -s "$(wslpath "$(wslvar USERPROFILE)")" ~/windows
fi

if [ -x "$(which op.exe)" ] && [ ! -e /dev/shm/gnome-keyring-daemon-launched ]; then
    op.exe read -n "op://development/wsl/password" | gnome-keyring-daemon --replace --unlock >/dev/null 2>&1
    touch /dev/shm/gnome-keyring-daemon-launched
fi
