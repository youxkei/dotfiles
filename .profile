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

if [ -e ~/.profile_host ]; then . ~/.profile_host; fi
if [ -e ~/.nix-profile/etc/profile.d/nix.sh ]; then . ~/.nix-profile/etc/profile.d/nix.sh; fi
if [ -e ~/.cargo/env ]; then . ~/.cargo/env; fi

if [ -x "$(which nix-build)" ]; then
    export LD_PRELOAD="$(nix-build '<nixpkgs>' -A stderred --no-out-link)/lib/libstderred.so${LD_PRELOAD:+:$LD_PRELOAD}"
fi

PATH=$PNPM_HOME:~/bin:~/go/bin:$PATH
export PATH

keychain -q --nogui ~/.ssh/id_ed25519
. ~/.keychain/$HOST-sh
