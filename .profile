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

export CLAUDE_CODE_SKIP_WINDOWS_PROFILE=1

if [ -e ~/.profile_host ]; then . ~/.profile_host; fi
if [ -e ~/.nix-profile/etc/profile.d/nix.sh ]; then . ~/.nix-profile/etc/profile.d/nix.sh; fi
if [ -e ~/.cargo/env ]; then . ~/.cargo/env; fi

if [ -e ~/.nix-profile/lib/libstderred.so ]; then
    export LD_PRELOAD="$HOME/.nix-profile/lib/libstderred.so${LD_PRELOAD:+:$LD_PRELOAD}"
fi

PATH=:~/bin:~/go/bin:~/.local/bin:$PNPM_HOME:$PATH
export PATH

if [ -x "$(which wslvar)" ]; then
    export USERPROFILE="$(wslpath "$(wslvar USERPROFILE)")"
fi

if [ -n "$USERPROFILE" ] && [ ! -e ~/windows ]; then
    ln -s "$USERPROFILE" ~/windows
fi

if [ -x "$(which op.exe)" ] && [ ! -e /dev/shm/gnome-keyring-daemon-launched ]; then
    _i=0
    while [ "$_i" -lt 5 ]; do
        if _password="$(op.exe read -n "op://development/wsl/password" 2>/dev/null)"; then
            printf '%s' "$_password" | gnome-keyring-daemon --replace --unlock >/dev/null 2>&1
            touch /dev/shm/gnome-keyring-daemon-launched
            break
        fi
        if [ "$_i" -eq 0 ]; then
            1Password.exe >/dev/null 2>&1 & disown
        fi
        _i=$((_i + 1))
        sleep 2
    done
    unset _i _password
fi
