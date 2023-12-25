#!/bin/bash
set -eu pipefail
SCRIPT_DIR=$(cd "$(dirname "$0")"; pwd)

# source path (relative to $SCRIPT_DIR) -> destination path
declare -A PATHS=(
    [.profile]=$HOME/.profile
    [.zprofile]=$HOME/.zprofile

    [zsh]=$XDG_CONFIG_HOME/zsh
    [fontconfig]=$XDG_CONFIG_HOME/fontconfig
    [nixpkgs]=$XDG_CONFIG_HOME/nixpkgs
    [nvim]=$XDG_CONFIG_HOME/nvim
    [i3]=$XDG_CONFIG_HOME/i3
    [i3status-rust]=$XDG_CONFIG_HOME/i3status-rust
    [git]=$XDG_CONFIG_HOME/git
    [tig]=$XDG_CONFIG_HOME/tig
    [tmux]=$XDG_CONFIG_HOME/tmux
    [procs]=$XDG_CONFIG_HOME/procs
    [alacritty]=$XDG_CONFIG_HOME/alacritty
    [dunst]=$XDG_CONFIG_HOME/dunst
    [compton.conf]=$XDG_CONFIG_HOME/compton.conf
    [starship.toml]=$XDG_CONFIG_HOME/starship.toml

    [pipewire/start_carla.sh]=$HOME/bin/start_carla
    [i3/i3_move.sh]=$HOME/bin/i3_move
    [bin/talk]=$HOME/bin/talk
    [bin/mozc_config]=$HOME/bin/mozc_config
    [bin/clip]=$HOME/bin/clip
    [bin/focus_on_mouse]=$HOME/bin/focus_on_mouse
    [bin/fullhd.sh]=$HOME/bin/fullhd
    [bin/touhou.sh]=$HOME/bin/touhou
    [bin/4k.sh]=$HOME/bin/4k
    [bin/screenshot.sh]=$HOME/bin/screenshot
    [bin/backup.sh]=$HOME/bin/backup
    [bin/nicolive-comment-viewer.sh]=$HOME/bin/nicolive-comment-viewer
    [bin/git-fixup]=$HOME/bin/git-fixup
    [bin/git-wa]=$HOME/bin/git-wa
)

# source path (relative to $SCRIPT_DIR) -> destination path
declare -A TEMPLATE_PATHS=(
    [.Xresources.template]=$HOME/.Xresources
    [.profile_host.template]=$HOME/.profile_host
)

# Check whether the source paths exist in $SCRIPT_DIR
for path in "${!PATHS[@]}"; do
    if [[ ! -e $SCRIPT_DIR/$path ]]; then
        echo "Error: $path does not exist in $SCRIPT_DIR" >&2
        exit 1
    fi
done

# Create symlinks for $PATHS
for path in "${!PATHS[@]}"; do
    src=$SCRIPT_DIR/$path
    dst=${PATHS[$path]}

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

declare -a copied_templates=()

# Copy $TEMPLATE_FILES to $HOME
for template_path in "${!TEMPLATE_PATHS[@]}"; do
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
