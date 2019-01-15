#!/bin/bash
set -eu pipefail
SCRIPT_DIR=$(cd $(dirname $0); pwd)

declare -a DOTFILES=(
  .i3
  .compton.conf
  .gitconfig
  .gitignore
  .i3status.conf
  .latexmkrc
  .profile
  .tigrc
  .zshrc
)

# Check whether the $DOTFILES exist in $SCRIPT_DIR
for dotfile in ${DOTFILES[@]}; do
  if [[ ! -e $dotfile ]]; then
    echo "$dotfile does not exist in $SCRIPT_DIR" >&2
    exit 1
  fi
done

# Create symlinks for $DOTFILES
for dotfile in ${DOTFILES[@]}; do
  # Remove existing file, directory, or link
  if [[ -e ~/$dotfile ]]; then
    rm -rf ~/$dotfile
  fi

  ln -s $SCRIPT_DIR/$dotfile ~
done

declare -a CONFIG_DIRS=(
  fontconfig
  nixpkgs
  nvim
)

# Check whether the $CONFIG_DIRS exist in $SCRIPT_DIR
for config_dir in ${CONFIG_DIRS[@]}; do
  if [[ ! -d $config_dir ]]; then
    echo "$config_dir does not exist in $SCRIPT_DIR" >&2
    exit 1
  fi
done

# Create symlinks for $CONFIG_DIRS
for config_dir in ${CONFIG_DIRS[@]}; do
  # Remove existing file, directory, or link
  if [[ -e ~/.config/$config_dir ]]; then
    rm -rf ~/.config/$config_dir
  fi

  ln -s $SCRIPT_DIR/$config_dir ~/.config
done
