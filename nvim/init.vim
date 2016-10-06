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
set cinoptions=L0,(0,U1,m1
set expandtab
set shiftwidth=4
set softtabstop=4
set smarttab
set tabstop=4

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

set cursorline
set cursorcolumn

let loaded_matchparen = 1

let g:mapleader=","
let g:tex_conceal=''

nnoremap <Leader>w :w<CR>
nnoremap Q <NOP>
inoremap <C-V> <C-r>+
vnoremap <C-C> "+y
tnoremap <Esc> <C-\><C-n>

let s:plugin_directory = expand('~/.cache/nvim/dein')
let s:dein_directory = s:plugin_directory . '/repos/github.com/Shougo/dein.vim'

if has('vim_starting')
    if !isdirectory(s:dein_directory)
        execute '!git clone https://github.com/Shougo/dein.vim' s:dein_directory
    endif
    execute 'set runtimepath+=' . s:dein_directory

    command -nargs=? Guifont call rpcnotify(0, 'Gui', 'SetFont', "<args>") | let g:Guifont="<args>"
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

    " .vimrc
    autocmd BufWritePost $MYVIMRC nested source $MYVIMRC

    " 状態の保存と復元
    "autocmd BufWinLeave ?* if(bufname('%')!='') | silent mkview! | endif
    "autocmd BufWinEnter ?* if(bufname('%')!='') | silent loadview | endif

    " fswitch
    autocmd BufEnter *.h let b:fswitchdst  = 'cpp,c'
    autocmd BufEnter *.h let b:fswitchlocs = 'reg:/include/src/'
    autocmd BufEnter *.cpp let b:fswitchdst  = 'h'
    autocmd BufEnter *.cpp let b:fswitchlocs = 'reg:/src/include/'

    " auto save
    autocmd BufLeave ?* if(!&readonly && &buftype == '' && filewritable(expand("%:p"))) | w | endif

    autocmd FileType coffee setlocal shiftwidth=2 softtabstop=2 tabstop=2
    autocmd FileType ruby setlocal shiftwidth=2 softtabstop=2 tabstop=2
augroup END

syntax enable

"if dein#is_sourced('papercolor-theme')
"    set background=dark
"    colorscheme PaperColor
"endif

if dein#is_sourced('gruvbox')
    set background=dark
    colorscheme gruvbox
endif

Guifont Ubuntu Mono:h8
