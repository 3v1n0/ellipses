#!/bin/bash
set -e

if [ "${SHELL##*/}" == "zsh" ]; then
  exit 0
fi

echo "Setting up ZSH..."

if ! command -v sudo &> /dev/null; then
  echo "No sudo, skipping ZSH setup..."
  exit 0
fi

if grep -qs debian /etc/os-release; then
  sudo apt-get -qy update
  sudo apt-get -y install zsh
elif grep -qs fedora /etc/os-release; then
  sudo dnf -y install zsh
fi

zsh_cmd="$(command -v zsh)";
if [ -z "$zsh_cmd" ]; then
  exit 1
fi

if [ -e "$HOME/.bash_history" ] || [ -e "$HOME/.bash_history_eternal_$HOSTNAME" ]; then
  set +e
  source "$HOME/.zshenv"
  set -e

  if [ "$(wc -l "$MY_ZSH_CONFIG_PATH/.zsh_history_eternal_$HOSTNAME")" -gt 100 ]; then
    exit 0
  fi

  MY_ZSH_CONFIG_PATH=${ZDOTDIR:-$HOME/.config/zsh}
  [ -e "$MY_ZSH_CONFIG_PATH" ] || MY_ZSH_CONFIG_PATH=$HOME

  for i in "$HOME/.bash_history"{,_$HOSTNAME} \
           "$HOME/.bash_history_eternal"{,_$HOSTNAME}; do
    cat "$i" >> "$MY_ZSH_CONFIG_PATH/.zsh_history_eternal_$HOSTNAME" || true
  done
fi

sudo chsh -s "$zsh_cmd"
