#!/bin/bash
set -eu pipefail
SCRIPT_DIR=$(cd $(dirname $0); pwd)

declare -a DOTFILES=(
  .i3
  .compton.conf
  .gitconfig
  .gitignore
  .i3status.conf
  .profile
  .zprofile
  .tigrc
  .zshrc
)

declare -a TEMPLATE_FILES=(
  .Xresources.template
)

declare -a CONFIG_DIRS=(
  fontconfig
  nixpkgs
  nvim
)


# Check whether the $DOTFILES, $TEMPLATE_FILES, and $CONFIG_DIRS exist in $SCRIPT_DIR
for dotfile in ${DOTFILES[@]} ${TEMPLATE_FILES[@]} ${CONFIG_DIRS[@]}; do
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

  # Remove existing file, directory, or link
  if [[ -e $HOME/$dotfile ]]; then
    rm -rf $HOME/$dotfile
  fi

  cp $SCRIPT_DIR/$template_file $HOME/$dotfile
done


# Create symlinks for $CONFIG_DIRS
for config_dir in ${CONFIG_DIRS[@]}; do
  # Remove existing file, directory, or link
  if [[ -e $HOME/.config/$config_dir ]]; then
    rm -rf $HOME/.config/$config_dir
  fi

  ln -s $SCRIPT_DIR/$config_dir $HOME/.config
done

echo "Plese edit following config files for this host:"
for template_file in ${TEMPLATE_FILES[@]}; do
  dotfile=${template_file%.template}

  echo $HOME/$dotfile
done
