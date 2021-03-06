export EDITOR=nvim
export VISUAL=nvim
export MANPAGER='nvim -c MANPAGER -'

PATH=~/bin:$PATH
export PATH

export ANDROID_HOME=~/Android/Sdk

export XDG_CONFIG_HOME=~/.config
export XDG_CACHE_HOME=~/.cache
export XDG_DATA_HOME=~/.local/share

export ZDOTDIR=$XDG_CONFIG_HOME/zsh
export skip_global_compinit=1

export QT_AUTO_SCREEN_SCALE_FACTOR=0

if [ -x "$(which nix-build)" ]; then export LOCALE_ARCHIVE=$(nix-build '<nixpkgs>' -A glibcLocales)/lib/locale/locale-archive; fi
if [ -e ~/.profile_host ]; then . ~/.profile_host; fi
