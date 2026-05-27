#!/usr/bin/env zsh
set -eu pipefail
SCRIPT_DIR=$(cd "$(dirname "$0")"; pwd)

# Default XDG_CONFIG_HOME when unset (e.g. macOS does not set it by default).
: ${XDG_CONFIG_HOME:=$HOME/.config}

# source path (relative to $SCRIPT_DIR) -> destination path
# Cross-platform entries that apply to both Linux/WSL and macOS.
typeset -A PATHS
PATHS=(
    .profile $HOME/.profile
    .zprofile $HOME/.zprofile

    zsh $XDG_CONFIG_HOME/zsh
    nix $XDG_CONFIG_HOME/nix
    nvim $XDG_CONFIG_HOME/nvim
    git $XDG_CONFIG_HOME/git
    tig $XDG_CONFIG_HOME/tig
    tmux $XDG_CONFIG_HOME/tmux
    procs $XDG_CONFIG_HOME/procs
    alacritty $XDG_CONFIG_HOME/alacritty
    sheldon $XDG_CONFIG_HOME/sheldon
    starship.toml $XDG_CONFIG_HOME/starship.toml
    ghostty $XDG_CONFIG_HOME/ghostty

    bin/git-fixup $HOME/bin/git-fixup
    bin/git-wa $HOME/bin/git-wa
    bin/nvr $HOME/bin/nvr
    bin/get-review-comments $HOME/bin/get-review-comments
    bin/notify $HOME/bin/notify
)

# Linux/WSL-only entries: configs for Linux desktop tools (i3, dunst, compton,
# fontconfig, pipewire, systemd) and bin scripts that depend on Linux-only
# utilities (xrandr, xsel, xdotool, btrfs, wl-copy, mozc) or wrap Windows
# executables (ssh.exe, pwsh.exe, wslview). bin/pbcopy is here because macOS
# already provides a native pbcopy.
if [[ "$OSTYPE" != darwin* ]]; then
    PATHS+=(
        fontconfig $XDG_CONFIG_HOME/fontconfig
        i3 $XDG_CONFIG_HOME/i3
        i3status-rust $XDG_CONFIG_HOME/i3status-rust
        dunst $XDG_CONFIG_HOME/dunst
        compton.conf $XDG_CONFIG_HOME/compton.conf

        pipewire/start_carla.sh $HOME/bin/start_carla
        i3/i3_move.sh $HOME/bin/i3_move
        bin/talk $HOME/bin/talk
        bin/mozc_config $HOME/bin/mozc_config
        bin/clip $HOME/bin/clip
        bin/focus_on_mouse $HOME/bin/focus_on_mouse
        bin/fullhd.sh $HOME/bin/fullhd
        bin/touhou.sh $HOME/bin/touhou
        bin/4k.sh $HOME/bin/4k
        bin/screenshot.sh $HOME/bin/screenshot
        bin/backup.sh $HOME/bin/backup
        bin/nicolive-comment-viewer.sh $HOME/bin/nicolive-comment-viewer
        bin/ssh $HOME/bin/ssh
        bin/ssh-add $HOME/bin/ssh-add
        bin/pbcopy $HOME/bin/pbcopy
        bin/wslview $HOME/bin/wslview
        bin/gnome-keyring-start $HOME/bin/gnome-keyring-start

        systemd/user/gnome-keyring-daemon.service.d/unlock.conf $XDG_CONFIG_HOME/systemd/user/gnome-keyring-daemon.service.d/unlock.conf
    )
fi

# macOS-only entries: configs for macOS-specific tools (karabiner-elements,
# komorebi-for-mac, linearmouse). The tools themselves are installed out of
# band (e.g. Homebrew); this only links their config and verifies the source
# exists, the same as the nix entry above.
if [[ "$OSTYPE" == darwin* ]]; then
    PATHS+=(
        karabiner $XDG_CONFIG_HOME/karabiner
        linearmouse $XDG_CONFIG_HOME/linearmouse

        bin/watch-komorebi $HOME/bin/watch-komorebi
        bin/start-komorebi $HOME/bin/start-komorebi
    )
fi

# source path (relative to $SCRIPT_DIR) -> destination path
typeset -A TEMPLATE_PATHS
TEMPLATE_PATHS=(
    .profile_host.template $HOME/.profile_host
)

# Check whether the source paths exist in $SCRIPT_DIR
for src_path in "${(@k)PATHS}"; do
    if [[ ! -e $SCRIPT_DIR/$src_path ]]; then
        echo "Error: $src_path does not exist in $SCRIPT_DIR" >&2
        exit 1
    fi
done

# Create symlinks for $PATHS
for src_path in "${(@k)PATHS}"; do
    src=$SCRIPT_DIR/$src_path
    dst=${PATHS[$src_path]}

    if [[ -e $dst ]]; then
        if [[ -L $dst ]]; then
            echo "Link $dst -> $src"
            rm "$dst"
            ln -s "$src" "$dst"
        else
            echo "Error: $dst exists and is not a symlink" >&2
            exit 1
        fi
    else
        if [[ ! -d $(dirname "$dst") ]]; then
            mkdir -p "$(dirname "$dst")"
        fi

        echo "Link $dst -> $src"
        ln -s "$src" "$dst"
    fi
done

typeset -a copied_templates
copied_templates=()

# Copy $TEMPLATE_FILES to $HOME
for template_path in "${(@k)TEMPLATE_PATHS}"; do
    src=$SCRIPT_DIR/$template_path
    dst=${TEMPLATE_PATHS[$template_path]}

    if [[ -e $dst ]]; then
        echo "$dst already exists. Skip copying"
    else
        echo "Copy $src -> $dst"
        cp "$src" "$dst"

        copied_templates+=("$dst")
    fi
done

if [[ ${#copied_templates[@]} -gt 0 ]]; then
    echo
    echo "Please edit following config files for this host:"
    for copied_template in "${copied_templates[@]}"; do
        echo "$copied_template"
    done
fi

# WSL: enable linger and wire gnome-keyring-daemon into default.target so the
# login keyring is unlocked automatically by the systemd user service.
if command -v wslvar >/dev/null 2>&1; then
    if [[ "$(loginctl show-user "$USER" --property=Linger 2>/dev/null)" != "Linger=yes" ]]; then
        echo "Enable linger for $USER (requires sudo)"
        sudo loginctl enable-linger "$USER"
    else
        echo "Linger already enabled for $USER"
    fi

    echo "Reload systemd user manager"
    systemctl --user daemon-reload

    echo "Wire gnome-keyring-daemon.service into default.target"
    systemctl --user add-wants default.target gnome-keyring-daemon.service
fi
