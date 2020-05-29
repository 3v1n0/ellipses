source ~/.vim/keybindings.vim
source ~/.vim/theming.vim

set runtimepath^=~/.vim/plugged/base16-vim
"set runtimepath^=~/.vim/plugged/material.vim
"set runtimepath^=~/.vim/plugged/molokai
"set runtimepath^=~/.vim/plugged/vim-solarized8
set runtimepath^=~/.vim/plugged/mesonic

set background=dark
colorscheme base16-material

nnoremap <Esc> :q<CR>
nnoremap <C-c> :q<CR>

"Search options
set incsearch
set hlsearch
set ignorecase
set smartcase

"set nobackup
set mouse=
"set ttymouse=

set ft= syn=
