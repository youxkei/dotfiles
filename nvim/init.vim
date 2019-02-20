set termguicolors

if !isdirectory(expand('~/.cache/nvim'))
  call mkdir(expand('~/.cache/nvim/backup'), 'p')
  call mkdir(expand('~/.cache/nvim/undo'),   'p')
  call mkdir(expand('~/.cache/nvim/swap'),   'p')
endif

set backupdir=~/.cache/nvim/backup
set undodir  =~/.cache/nvim/undo
set directory=~/.cache/nvim/swap

set undofile
set backup
set writebackup
set swapfile

set cindent
set cinoptions=L0,(2,U1,m1
set expandtab
set shiftwidth=2
set softtabstop=2
set smarttab
set tabstop=2

"set encoding=utf-8
set fileencodings=utf-8,sjis,cp932,euc-jp
set fileformats=unix,mac,dos

set nofoldenable
set foldmethod=indent

set ambiwidth=single
set cmdheight=2

set hidden
set number
set showmatch
set nowrap
set eol
set hls
set nodigraph
set showcmd
set backspace=indent,eol,start

set scrolloff=16
set sidescroll=1
"set sidescrolloff=32
set laststatus=2

set viewoptions=cursor
set wildmenu
set signcolumn=yes
set completeopt-=preview

set list
set listchars=tab:»-,trail:-,nbsp:%

set modeline

set inccommand=nosplit

set autoread

let loaded_matchparen = 1

let g:mapleader = ','
let g:tex_conceal = ''
let g:tex_flavor = 'latex'

function! SetFontSize(point)
  call GuiFont(join([split(g:GuiFont, "h")[0], a:point], "h"), 1)
endfunction

function! ChangeFontSize(point_diff)
  let split = split(g:GuiFont, "h")
  call GuiFont(join([split[0], split[1] + a:point_diff], "h"), 1)
endfunction

nnoremap <Leader>w :w<CR>

nnoremap Q <NOP>
nnoremap <expr> i len(getline('.')) == 0 ? "cc" : "i"
nnoremap <expr> a len(getline('.')) == 0 ? "cc" : "a"
nnoremap <silent> <C-+> :call ChangeFontSize(1)<CR>
nnoremap <silent> <C--> :call ChangeFontSize(-1)<CR>
nnoremap <silent> <C-0> :call SetFontSize(11)<CR>
inoremap <C-V> <C-r>+
vnoremap <C-C> "+y
tnoremap <Esc> <C-\><C-n>

augroup general
  autocmd!

  " autosource
  autocmd BufWritePost $MYVIMRC nested source $MYVIMRC
  autocmd BufWritePost $MYGVIMRC nested source $MYGVIMRC
  autocmd BufWritePost *.toml nested if count(s:dein_toml_sources, expand('%:p')) != 0 | source $MYVIMRC | endif

  autocmd BufEnter * checktime

  autocmd BufEnter *.erl set sw=4 ts=4 sts=4

  autocmd InsertLeave * call system('fcitx-remote -c')
augroup END

let s:plugin_directory = expand('~/.cache/nvim/dein')
let s:dein_directory = s:plugin_directory . '/repos/github.com/Shougo/dein.vim'

if has('vim_starting')
  if !isdirectory(s:dein_directory)
    execute '!git clone https://github.com/Shougo/dein.vim' s:dein_directory
  endif
  execute 'set runtimepath+=' . s:dein_directory
endif

let s:dein_toml_sources = [
\ fnamemodify($MYVIMRC, ':p:h').'/plugin.toml',
\ fnamemodify($MYVIMRC, ':p:h').'/plugin_textobj_operator.toml',
\ fnamemodify($MYVIMRC, ':p:h').'/plugin_syntax.toml',
\ fnamemodify($MYVIMRC, ':p:h').'/plugin_colorscheme.toml'
\]

if dein#load_state(s:plugin_directory)
  call dein#begin(s:plugin_directory)

  for toml_source in s:dein_toml_sources
    call dein#load_toml(toml_source)
  endfor

  call dein#end()
  call dein#save_state()
endif

if dein#check_install()
  call dein#install()
endif

syntax enable

set bg=dark
colorscheme gruvbox

filetype plugin indent on
