export EDITOR=nvim
export VISUAL=nvim
export MANPAGER='nvim -c MANPAGER -'

PATH=~/.local/bin:$PATH
PATH=~/go/bin:$PATH
PATH=~/.cargo/bin:$PATH
PATH=~/bin:$PATH
export PATH

export ZPLG_HOME=~/.zplugin
export ANDROID_HOME=~/Android/Sdk
export QT_AUTO_SCREEN_SCALE_FACTOR=0
export QT_SCALE_FACTOR=1.3

if [ -x "$(which nix-build)" ]; then export LOCALE_ARCHIVE=$(nix-build '<nixpkgs>' -A glibcLocales)/lib/locale/locale-archive; fi
if [ -e ~/.profile_host ]; then . ~/.profile_host; fi
