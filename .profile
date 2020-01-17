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

source ~/.opam/opam-init/init.zsh >/dev/null 2>/dev/null || true

if [ -e /home/youxkei/.nix-profile/etc/profile.d/nix.sh ]; then . /home/youxkei/.nix-profile/etc/profile.d/nix.sh; fi # added by Nix installer
if [ -e /home/youxkei/.nix-profile/etc/profile.d/nix.sh ]; then export LOCALE_ARCHIVE=$(nix-build '<nixpkgs>' -A glibcLocales)/lib/locale/locale-archive; fi
