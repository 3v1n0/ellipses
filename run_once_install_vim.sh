#!/bin/bash
set -e

autoload_path="${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/

if [ -f "$autoload_path/plug.vim" ]; then
  exit 0
fi

echo "Setting up (neo)VIM (and vimplug)..."

mkdir -p "$autoload_path"
wget -O "$autoload_path/plug.vim" \
	"https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"

if ! command -v sudo &> /dev/null; then
  echo "No sudo, skipping actual vim installation..."
  exit 0
fi

if (command snap &> /dev/null) && [ -n "$SNAP_CHANNEL" ]; then
  sudo snap install nvim --classic --channel=$SNAP_CHANNEL
elif grep -qs debian /etc/os-release; then
  sudo apt-get -qy update
  sudo apt-get -y install neovim || sudo apt-get -y install vim
elif grep -qs fedora /etc/os-release; then
  sudo dnf 
  sudo dnf -y install neovim || sudo dnf -y install vim
fi

vim_cmd="$(command -v vim)"
if (command -v nvim &> /dev/null); then
  vim_cmd="$(command -v nvim)"

  if (command -v update-alternatives &> /dev/null); then
    sudo update-alternatives --set vi $vim_cmd
    sudo update-alternatives --set vim $vim_cmd
    sudo update-alternatives --set editor $vim_cmd
  fi
elif [ "$vim_cmd" ]; then
  mkdir -m700 -p "$HOME/.vim"

  ! [ -d "$HOME/.vim/autoload" ] && \
    ln -sf "$autoload_path" "$HOME/.vim/autoload"
fi

if [ -n "$vim_cmd" ]; then
  sudo ln -sf "$vim_cmd" /usr/local/bin/nano
  command -v curl &> /dev/null || sudo apt-get -y install curl # needed by vim-plug
  args=
  tty &> /dev/null || args="--headless"
  $vim_cmd $args +PlugInstall +qall
else
  echo "No vim installation possible, go with manual fire!"
fi
