"Make possible to move around in insert mode without Escape"
" The <A.. seem to work only in neovim, add relatives for pure vim"

let hjklfriends = ['h','j','k','l','w','e','b','W','E','B', 'n', 'N', 'y', 'Y',
                   \ 'p', 'P', '$', '0', '%', '"', '(', ')']

" define if using alt (it works in neovim) or Escape key.
function! Meta(key)
  if has('nvim')
        return "<A-" . a:key . ">"
    else
        return "<Esc>" . a:key
    endif
endfunction

function! RemapAltKeyInInsertMode(key, ...)
  let newkey = get(a:, 1, a:key)
  execute 'inoremap ' . Meta(a:key) . ' <C-o>' . newkey
endfunction

function! RemapSelectionKey(key, action)
  execute 'inoremap ' . a:key . ' <C-o>v' . a:action
  execute 'vnoremap ' . a:key . ' ' . a:action
  execute 'nnoremap ' . a:key . ' v' . a:action
endfunction

execute 'noremap! ' . Meta('b') . ' <C-Left>'
execute 'noremap! ' . Meta('w') . ' <C-Right>'
execute 'noremap! ' . Meta('e') . ' <C-Right>'

for k in hjklfriends
  execute RemapAltKeyInInsertMode(k)
  if k =~ '^[a-z]$'
    execute RemapSelectionKey(Meta(toupper(k)), k)
  endif
endfor

for k in ['left', 'right', 'up', 'down', 'home', 'end', 'pageup', 'pagedown',
          \ 'C-left', 'C-right', 'C-home', 'C-end']
  execute RemapSelectionKey('<S-' . k . '>', '<' . k . '>')
endfor

execute 'noremap! ' . Meta('h') . ' <left>'
execute 'noremap! ' . Meta('j') . ' <down>'
execute 'noremap! ' . Meta('k') . ' <up>'
execute 'noremap! ' . Meta('l') . ' <right>'

" Move by line when wrapping
execute 'nnoremap <buffer> ' . Meta('j') . ' gj'
execute 'nnoremap <buffer> ' . Meta('k') . ' gk'
execute RemapAltKeyInInsertMode('j', 'gj')
execute RemapAltKeyInInsertMode('k', 'gk')
execute RemapSelectionKey(Meta(toupper('k')), 'gk')
execute RemapSelectionKey(Meta(toupper('j')), 'gj')

"inoremap! <C-h> <left>
"inoremap! <C-j> <down>
"inoremap! <C-k> <up>
"inoremap! <C-l> <right>

"Undo/Redo
execute RemapAltKeyInInsertMode('r', '<C-r>')
execute RemapAltKeyInInsertMode('u')

"Up/down and redo remap, bad guyyyy overriding stuff above!! :)
execute RemapAltKeyInInsertMode('z', 'u')
execute RemapAltKeyInInsertMode('Z', '<C-r>')
execute RemapAltKeyInInsertMode('U', 'u')
execute RemapAltKeyInInsertMode('R', '<C-r>')
execute RemapAltKeyInInsertMode('u', '<C-b>')
execute RemapAltKeyInInsertMode('n', '<C-f>')

execute 'noremap ' . Meta('u') . ' <C-b>'
execute RemapSelectionKey(Meta('U'), '<C-b>')
execute 'noremap ' . Meta('n') . ' <C-f>'
execute RemapSelectionKey(Meta('N'), '<C-f>')

"Just remove a line on alt+d in insert mode
execute RemapAltKeyInInsertMode('d', '"_dd')

"Improve move to end of word in insert mode
execute RemapAltKeyInInsertMode('e', 'e<C-o>a')

"Move between changed location history
execute RemapAltKeyInInsertMode('o', '<C-O>')
execute RemapAltKeyInInsertMode('i', '<C-I>')
execute RemapAltKeyInInsertMode('C-o', '<C-O>')
execute RemapAltKeyInInsertMode('C-i', '<C-I>')

"Add Ctrl+r, page moving...

"inoremap <Esc>d <

"Remap repeat in insert mode"
inoremap <C-r> <C-o><C-r>

"Use Ctrl+c to toggle insert mode
inoremap <C-c> <Esc>
nnoremap <C-c> i

""" Some Muscle-memory helpers to use stuff from normal editors """
"Tabbing around
nnoremap <Tab> >>_
nnoremap <S-Tab> <<_
inoremap <S-Tab> <C-D>
vnoremap <Tab> >gv
vnoremap <S-Tab> <gv

"Improve clipboard handling, use standard Ctrl+c/x/v in vmode
vnoremap <C-x> d
vnoremap <C-c> y
vnoremap <C-v> "_dP
nnoremap <C-x> dd
inoremap <C-x> <C-o>dd
inoremap <C-v> <C-o>p

"Don't move back cursor after yanking
vmap y ygv<Esc>

"Ctrl+z / y in insert mode"
inoremap <C-z> <C-o>u
inoremap <C-Z> <C-o><C-r>
inoremap <C-y> <C-Z>

"Search!
inoremap <C-f> <C-o>/
inoremap <F3> <C-o>n
inoremap <S-F3> <C-o>N
inoremap <C-g> <C-o>n
inoremap <C-G> <C-o>N

" Always use the system clipboard
set clipboard=unnamedplus

"Show an ui to select the register source on "p (and c-P)
nnoremap "p :reg <bar> exec 'normal! "'.input('> ').'p'<CR>
nnoremap <C-P> :reg <bar> exec 'normal! "'.input('> ').'p'<CR>
inoremap <C-P> <Esc> :reg <bar> exec 'normal! "'.input('> ').'p'<CR>

nnoremap <C-P> :CtrlPCmdPalette

"Remap Ctrl+Backspace to Ctrl+W to delete word"
noremap! <C-H> <C-w>
vnoremap <BS> "_d

"Use backspace in normal mode"
nnoremap <BS> X
nnoremap <Enter> i<Enter>

"Don't cut by default on Del
inoremap <Del> <C-o>"_x
noremap <Del> "_x

"Ctrl+del to remove a word
inoremap <C-Del> <C-o>"_dw
noremap <C-Del> "_dw
inoremap <S-Del> <C-o>"_dw
noremap <S-Del> "_dw

"Bracket moving
"inoremap <C-m> <C-o>%

"Delete (and forget) line
inoremap <C-K> <C-o>"_dd
nnoremap <C-K> "_dd

"Duplicate line or block"
inoremap <C-S-o> <Esc>YPji
nnoremap <C-S-o> YPj
vnoremap <C-S-o> "aY$`]"ap

"Not nice, solve of C-O / C-I (this one is blocked by Tab rempping)
nnoremap <C-o> <C-O>
nnoremap <C-i> <C-I>

"Start multiline editing on word
imap <C-j> <C-o><C-n>
nmap <C-j> <C-n>

"Move line
inoremap <C-S-up> <C-o>:m-2<CR>
nnoremap <C-S-up> :m-2<CR>
vnoremap <C-S-up> :m '>-2<CR> "FIXME
inoremap <C-S-down> <C-o>:m+1<CR>
nnoremap <C-S-down> :m+1<CR>
vnoremap <C-S-down> :m '>+1<CR>
""vnoremap <C-S-down> V"adj"ap

nnoremap <C-A-S-k> :m-2<CR>
inoremap <C-A-S-k> <C-o>:m-2<CR>
vnoremap <C-A-S-k> :m '>-2<CR> "FIXME
inoremap <C-A-S-j> <C-o>:m+1<CR>
nnoremap <C-A-S-j> :m+1<CR>
vnoremap <C-A-S-j> :m '>+1<CR>

"Support ctrl+S to save
nnoremap <C-s> :w<CR>
inoremap <C-s> <C-o>:w<CR>

""" End of VIM traitor side """


"Support linewrapping by default - To fix and use functions
noremap <silent> <Leader>w :call ToggleWrap()<CR>
function ToggleWrap()
  if &wrap
    echo "Wrap OFF"
    setlocal nowrap
    set virtualedit=all
    silent! nunmap <buffer> <Up>
    silent! nunmap <buffer> <Down>
    silent! nunmap <buffer> <Home>
    silent! nunmap <buffer> <End>
    silent! iunmap <buffer> <Up>
    silent! iunmap <buffer> <Down>
    silent! iunmap <buffer> <Home>
    silent! iunmap <buffer> <End>
  else
    echo "Wrap ON"
    setlocal wrap linebreak nolist
    set virtualedit=
    setlocal display+=lastline
    noremap  <buffer> <silent> <Up>   gk
    noremap  <buffer> <silent> <Down> gj
    noremap  <buffer> <silent> <Home> g<Home>
    noremap  <buffer> <silent> <End>  g<End>
    inoremap <buffer> <silent> <Up>   <C-o>gk
    inoremap <buffer> <silent> <Down> <C-o>gj
    inoremap <buffer> <silent> <Home> <C-o>g<Home>
    inoremap <buffer> <silent> <End>  <C-o>g<End>
  endif
endfunction

noremap  <buffer> k gk
noremap  <buffer> j gj
noremap  <buffer> <Up>   gk
noremap  <buffer> <Down> gj
noremap  <buffer> <Home> g<Home>
noremap  <buffer> <End>  g<End>
inoremap <buffer> <Up>   <C-o>gk
inoremap <buffer> <Down> <C-o>gj
inoremap <buffer> <Home> <C-o>g<Home>
inoremap <buffer> <End>  <C-o>g<End>


