#!/usr/bin/env zsh
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "$0")"; pwd)

# Default XDG_CONFIG_HOME when unset (e.g. macOS does not set it by default).
: ${XDG_CONFIG_HOME:=$HOME/.config}

# Detect environment. These dotfiles target macOS and WSL; the WSL-only entries
# wrap Windows executables (ssh.exe, pwsh.exe) and the Wayland clipboard, so they
# must not be installed on plain Linux.
IS_MACOS=0
IS_WSL=0
if [[ "$OSTYPE" == darwin* ]]; then IS_MACOS=1; fi
if grep -qiE 'microsoft|wsl' /proc/sys/kernel/osrelease 2>/dev/null || [[ -n "${WSL_DISTRO_NAME:-}" ]]; then IS_WSL=1; fi

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
    katnas $XDG_CONFIG_HOME/katnas

    bin/nvr $HOME/bin/nvr
    bin/notify $HOME/bin/notify
    bin/claude-notify $HOME/bin/claude-notify
)

# WSL-only entries: bin scripts that wrap Windows executables (ssh.exe, pwsh.exe)
# or the Wayland clipboard (wl-copy), plus the gnome-keyring-start helper and the
# systemd drop-in that auto-unlock the login keyring. bin/pbcopy is here because
# macOS already provides a native pbcopy.
if (( IS_WSL )); then
    PATHS+=(
        bin/ssh $HOME/bin/ssh
        bin/ssh-add $HOME/bin/ssh-add
        bin/pbcopy $HOME/bin/pbcopy
        bin/wslview $HOME/bin/wslview

        bin/gnome-keyring-start $HOME/bin/gnome-keyring-start
        systemd/user/gnome-keyring-daemon.service.d/unlock.conf $XDG_CONFIG_HOME/systemd/user/gnome-keyring-daemon.service.d/unlock.conf
    )
fi

# macOS-only entries: configs for macOS-specific tools (karabiner-elements,
# linearmouse). The tools themselves are installed out of band (e.g. Homebrew);
# this only links their config and verifies the source exists, the same as the
# nix entry above.
if (( IS_MACOS )); then
    PATHS+=(
        karabiner $XDG_CONFIG_HOME/karabiner
        linearmouse $XDG_CONFIG_HOME/linearmouse
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

    if [[ -e $dst || -L $dst ]]; then
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

# WSL: when the gnome-keyring-daemon user unit is available, enable linger and
# wire it into default.target so the login keyring is unlocked automatically by
# the systemd user service (bin/gnome-keyring-start). Skipped when gnome-keyring
# is not installed here (the unlock.conf drop-in has no base unit to extend).
if (( IS_WSL )) && systemctl --user cat gnome-keyring-daemon.service >/dev/null 2>&1; then
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
