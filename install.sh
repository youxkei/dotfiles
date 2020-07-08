#!/bin/bash
set -eu pipefail
SCRIPT_DIR=$(cd $(dirname $0); pwd)

declare -a DOTFILES=(
  .profile
  .zprofile
  .zshrc
)

declare -a TEMPLATE_FILES=(
  .Xresources.template
)

declare -a CONFIG_PATHS=(
  fontconfig
  nixpkgs
  nvim
  i3
  i3status-rust
  git
  tig
  tmux
  procs
  alacritty
  compton.conf
)


# Check whether the $DOTFILES, $TEMPLATE_FILES, and $CONFIG_PATHS exist in $SCRIPT_DIR
for dotfile in ${DOTFILES[@]} ${TEMPLATE_FILES[@]} ${CONFIG_PATHS[@]}; do
  if [[ ! -e $dotfile ]]; then
    echo "$dotfile does not exist in $SCRIPT_DIR" >&2
    exit 1
  fi
done


# Create symlinks for $DOTFILES
for dotfile in ${DOTFILES[@]}; do
  # Remove existing file, directory, or link
  if [[ -e $HOME/$dotfile ]]; then
    rm -rf $HOME/$dotfile
  fi

  ln -s $SCRIPT_DIR/$dotfile $HOME
done

# Copy $TEMPLATE_FILES to $HOME
for template_file in ${TEMPLATE_FILES[@]}; do
  dotfile=${template_file%.template}

  if [[ ! -e $HOME/$dotfile ]]; then
      cp $SCRIPT_DIR/$template_file $HOME/$dotfile
  fi
done


# Create symlinks for $CONFIG_PATHS
for config_path in ${CONFIG_PATHS[@]}; do
  # Remove existing file, directory, or link
  if [[ -e $HOME/.config/$config_path ]]; then
    rm -rf $HOME/.config/$config_path
  fi

  ln -s $SCRIPT_DIR/$config_path $HOME/.config
done

echo "Plese edit following config files for this host:"
for template_file in ${TEMPLATE_FILES[@]}; do
  dotfile=${template_file%.template}

  echo $HOME/$dotfile
done
