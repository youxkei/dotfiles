#!/bin/bash
set -eu pipefail
SCRIPT_DIR=$(cd "$(dirname "$0")"; pwd)

# source path (relative to $SCRIPT_DIR) -> destination path
declare -A PATHS=(
    [.profile]=~/.profile
    [.zprofile]=~/.zprofile

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

    [jack/start_jack.sh]=~/bin/start_jack
    [i3/i3_move.sh]=~/bin/i3_move
    [bin/talk]=~/bin/talk
    [bin/mozc_config]=~/bin/mozc_config
    [bin/clip]=~/bin/clip
    [bin/focus_on_mouse]=~/bin/focus_on_mouse
    [bin/git-fixup]=~/bin/git-fixup
    [bin/fullhd.sh]=~/bin/fullhd
    [bin/touhou.sh]=~/bin/touhou
    [bin/4k.sh]=~/bin/4k
    [bin/screenshot.sh]=~/bin/screenshot
    [bin/backup.sh]=~/bin/backup
    [bin/nicolive-comment-viewer.sh]=~/bin/nicolive-comment-viewer
)

# source path (relative to $SCRIPT_DIR) -> destination path
declare -A TEMPLATE_PATHS=(
    [.Xresources.template]=~/.Xresources
    [.profile_host.template]=~/.profile_host
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
