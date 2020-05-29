function! SetColorScheme(scheme)
  try
    execute 'colorscheme ' . a:scheme
    return 0
  catch /^Vim\%((\a\+)\)\=:E185/
    return 1
  endtry
endfunction

let colorterm=$COLORTERM
if colorterm =~# 'truecolor' || colorterm =~# '24bit'
  set termguicolors
  "Theming"
  if has('nvim')
    "set background=dark
    "colorscheme solarized8
  endif

  "Not bad: base16-atelier-cave-light or base16-classic-light (mexico light as well
  "colorscheme PaperColor

  if (SetColorScheme('base16-harmonic-light'))
    set background=light
  endif
else
  "Nice dark base16-materia and base16-material, base16-harmonic-dark too!
  "colorscheme peachpuff
  if (SetColorScheme('PaperColor'))
    set background=light
  endif
endif

"let g:airline_theme='papercolor'
"
"let g:PaperColor_Theme_Options = {
"  \   'language': {
"  \     'python': {
"  \       'highlight_builtins' : 1
"  \     },
"  \     'cpp': {
"  \       'highlight_standard_library': 1
"  \     },
"  \     'c': {
"  \       'highlight_builtins' : 1
"  \     },
"  \     'meson': {
"  \       'highlight_builtins' : 1
"  \     }
"  \   }
"  \ }

