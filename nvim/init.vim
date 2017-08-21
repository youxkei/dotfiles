filetype off

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

set ambiwidth=double
set cmdheight=2

set number
set showmatch
set nowrap
set eol
set hls
set nodigraph
set noea
set showcmd
set backspace=indent,eol,start

set scrolloff=16
set sidescroll=1
"set sidescrolloff=32
set laststatus=2

set viewoptions=cursor
set wildmenu

set list
set listchars=tab:»-,trail:-,nbsp:%

set modeline

set inccommand=nosplit

set autoread

let loaded_matchparen = 1

let g:mapleader=","
let g:tex_conceal=''

nnoremap <Leader>w :w<CR>
nnoremap Q <NOP>
inoremap <C-V> <C-r>+
vnoremap <C-C> "+y
tnoremap <Esc> <C-\><C-n>
nnoremap <Leader>d <C-w>s<C-w>v<C-w>j<C-w>v<C-w>t<C-w>=

let s:plugin_directory = expand('~/.cache/nvim/dein')
let s:dein_directory = s:plugin_directory . '/repos/github.com/Shougo/dein.vim'

if has('vim_starting')
  if !isdirectory(s:dein_directory)
    execute '!git clone https://github.com/Shougo/dein.vim' s:dein_directory
  endif
  execute 'set runtimepath+=' . s:dein_directory
endif

if dein#load_state(s:plugin_directory)
  call dein#begin(s:plugin_directory)

  call dein#load_toml(expand('~/.config/nvim/plugin.toml'))
  call dein#load_toml(expand('~/.config/nvim/plugin_textobj_operator.toml'))
  call dein#load_toml(expand('~/.config/nvim/plugin_syntax.toml'))
  call dein#load_toml(expand('~/.config/nvim/plugin_colorscheme.toml'))

  call dein#end()
  call dein#save_state()
endif

if dein#check_install()
  call dein#install()
endif

filetype plugin indent on

augroup general
  autocmd!

  " autosource
  autocmd BufWritePost $MYVIMRC nested source $MYVIMRC
  autocmd BufWritePost $MYGVIMRC nested source $MYGVIMRC

  " fswitch
  autocmd BufEnter *.h let b:fswitchdst  = 'cpp,c'
  autocmd BufEnter *.h let b:fswitchlocs = 'reg:/include/src/'
  autocmd BufEnter *.cpp let b:fswitchdst  = 'h'
  autocmd BufEnter *.cpp let b:fswitchlocs = 'reg:/src/include/'

  autocmd BufEnter *.smi let b:fswitchdst  = 'sml'
  autocmd BufEnter *.smi let b:fswitchlocs  = '.'
  autocmd BufEnter *.sml let b:fswitchdst  = 'smi'
  autocmd BufEnter *.sml let b:fswitchlocs  = '.'

  autocmd BufEnter * checktime
  autocmd BufEnter * execute ":lcd " . expand("%:p:h") 
augroup END

syntax enable

set bg=dark
colorscheme gruvbox
