source ~/.vim/keybindings.vim
set viminfo+=n~/.vim/viminfo

"Enable line numbers
set number

set colorcolumn=80
set cursorline

"Global settings for all files (but may be overridden in ftplugin).
set tabstop=2
set shiftwidth=2
set noexpandtab

"file encoding
set encoding=utf-8

"Search options
set incsearch
set hlsearch
set ignorecase
set smartcase

"Enable spell checks
autocmd BufRead,BufNewFile *.md setlocal spell spelllang=en_us
autocmd BufRead,BufNewFile *.txt setlocal spell spelllang=en_us
autocmd BufRead,BufNewFile README setlocal spell spelllang=en_us
autocmd FileType gitcommit setlocal spell spelllang=en_us

"Make some chars visibles and handle trailing whitespaces
set list
set listchars=tab:▸\.,trail:·,extends:»,precedes:«
highlight ExtraWhitespace ctermbg=red guibg=red
match ExtraWhitespace /\s\+$/
"highlight NonText guifg=#4a4a59
"highlight SpecialKey guifg=#4a4a59

"Always show the completion menu
set completeopt=longest,menuone
inoremap <C-Space> <C-n>
inoremap <C-@> <C-Space>

source ~/.vim/wildignores.vim

"Ensure we have Plug plugin manager
if empty(glob("~/.vim/autoload/plug.vim"))
  execute '!mkdir -p ~/.vim/autoload'
  execute '!curl -fLo ~/.vim/autoload/plug.vim https://raw.github.com/junegunn/vim-plug/master/plug.vim'
endif

"Load all the plugins!
call plug#begin('~/.vim/plugged')
Plug 'NLKNguyen/papercolor-theme'
Plug 'rakr/vim-two-firewatch'
Plug 'lifepillar/vim-solarized8'
Plug 'igankevich/mesonic'
Plug 'vim-airline/vim-airline'
Plug 'chriskempson/base16-vim'
Plug 'vim-airline/vim-airline-themes'
Plug 'farmergreg/vim-lastplace'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'fisadev/vim-ctrlp-cmdpalette'
"Plug 'terryma/vim-multiple-cursors'
Plug 'mg979/vim-visual-multi'
Plug 'tpope/vim-sleuth'
Plug 'ntpeters/vim-better-whitespace'
"Plug 'vim-ctrlspace/vim-ctrlspace'
call plug#end()

source ~/.vim/theming.vim

"Enable visual multi undo/redo
"let g:VM_maps["Undo"] = 'u'
"let g:VM_maps["Redo"] = '<C-r>

"let g:VM_custom_remaps = {'<C-j>': '<C-n>'}

let g:ctrlp_root_markers = ['.ctrlp',
  \ '.vscode',
  \ 'compile_commands.json',
  \ 'meson_options.txt',
  \ 'package.json',
  \ 'build.gradle',
  \]

set mouse=a

"Start in insert mode with git commit
au! VimEnter COMMIT_EDITMSG exec 'norm gg' | startinsert!
