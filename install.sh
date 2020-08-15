#!/bin/bash
set -eu pipefail
SCRIPT_DIR=$(cd $(dirname $0); pwd)

# source path (relative to $SCRIPT_DIR) -> destination path (relative to home directory)
declare -A PATHS=(
    [.profile]=.profile
    [.zprofile]=.zprofile

    [zsh]=.config/zsh
    [fontconfig]=.config/fontconfig
    [nixpkgs]=.config/nixpkgs
    [nvim]=.config/nvim
    [i3]=.config/i3
    [i3status-rust]=.config/i3status-rust
    [git]=.config/git
    [tig]=.config/tig
    [tmux]=.config/tmux
    [procs]=.config/procs
    [alacritty]=.config/alacritty
    [compton.conf]=.config/compton.conf
    [starship.toml]=.config/starship.toml

    [jack/start_jack.sh]=bin/start_jack.sh
    [i3/i3_move.sh]=bin/i3_move.sh
)

# source path (relative to $SCRIPT_DIR) -> destination path (relative to home directory)
declare -A TEMPLATE_PATHS=(
    [.Xresources.template]=.Xresources
)

# Check whether the source paths exist in $SCRIPT_DIR
for path in ${!PATHS[@]}; do
    if [[ ! -e $SCRIPT_DIR/$path ]]; then
        echo "Error: $path does not exist in $SCRIPT_DIR" >&2
        exit 1
    fi
done

# Create symlinks for $PATHS
for path in ${!PATHS[@]}; do
    src=$SCRIPT_DIR/$path
    dst=~/${PATHS[$path]}

    # Remove links
    if [[ -e $dst ]]; then
        if [[ -L $dst ]]; then
            echo "Link $dst -> $src"
            unlink $dst
            ln -s $src $dst
        else
            echo "Error: $dst exists and is not a symlink" >&2
            exit 1
        fi
    else
        if [[ ! -d $(dirname $dst) ]]; then
            mkdir -p $(dirname $dst)
        fi

        echo "Link $dst -> $src"
        ln -s $src $dst
    fi
done

# Copy $TEMPLATE_FILES to $HOME
for template_path in ${!TEMPLATE_PATHS[@]}; do
    src=$SCRIPT_DIR/$template_path
    dst=~/${TEMPLATE_PATHS[$template_path]}

    if [[ -e $dst ]]; then
        echo "$dst already exists. Skip copying"
    else
        echo "Copy $src -> $dst"
        cp $src $dst
    fi
done

echo "Please edit following config files for this host:"
for template_path in ${!TEMPLATE_PATHS[@]}; do
    echo ~/${TEMPLATE_PATHS[$template_path]}
done
