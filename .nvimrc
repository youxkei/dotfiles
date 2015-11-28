filetype off

let $PATH=system("echo \$PATH")

if isdirectory(expand('~/.nvim/backup'))
    set backupdir=~/.nvim/backup
    set undodir=~/.nvim/backup
    set directory=~/.nvim/backup

    set undofile
    set backup
    set writebackup
    set swapfile
endif

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

let loaded_matchparen = 1

let g:mapleader=","

nnoremap zQ <NOP>
nnoremap <Leader>w :write<CR>
inoremap <C-V> <C-r>+
vnoremap <C-C> "+y

if has('vim_starting')
    set runtimepath+=~/.nvim/bundle/neobundle.vim/

    command -nargs=? Guifont call rpcnotify(0, 'Gui', 'SetFont', "<args>") | let g:Guifont="<args>"
endif

let g:neobundle#types#git#default_protocol = 'git'

call neobundle#begin(expand('~/.nvim/bundle/'))

NeoBundleFetch 'Shougo/neobundle.vim'

NeoBundle 'thinca/vim-ambicmd'
NeoBundle 'Shougo/vimproc.vim', {'build' : {'linux' : 'make' } }
NeoBundle 'Shougo/deoplete.nvim'
NeoBundle     'Shougo/unite.vim'
NeoBundle     'Shougo/unite-ssh'
NeoBundle     'Shougo/unite-outline'
NeoBundle     'Shougo/unite-session'
NeoBundle 'osyo-manga/unite-fold'
NeoBundle 'thinca/vim-unite-history'
NeoBundle       'mopp/unite-animemap'
NeoBundle    'ujihisa/unite-colorscheme'
NeoBundle      'rhysd/unite-codic.vim'
NeoBundle 'Shougo/neomru.vim'
NeoBundle 'Shougo/vimfiler.vim'
NeoBundle 'ujihisa/neco-look'
NeoBundle 'Lokaltog/vim-easymotion'
NeoBundle 'kana/vim-submode'
NeoBundle 'basyura/TweetVim'
NeoBundle 'basyura/twibill.vim'
NeoBundle 'tyru/open-browser.vim'
NeoBundle 'mattn/gist-vim'
NeoBundle 'mattn/webapi-vim'
NeoBundle 'itchyny/lightline.vim'
NeoBundle 'kannokanno/previm'
NeoBundle 'LeafCage/yankround.vim'
NeoBundle 'kana/vim-operator-user'
NeoBundle 'kana/vim-niceblock'
NeoBundle 'thinca/vim-fontzoom'
NeoBundle 'fcitx.vim'
NeoBundle 'luochen1990/rainbow'
NeoBundle 'tpope/vim-repeat'
"NeoBundle 'rhysd/clever-f.vim'
NeoBundle 'VOoM'
NeoBundle 'idanarye/vim-vebugger'
NeoBundle 'junegunn/vim-easy-align'
NeoBundle 'thinca/vim-visualstar'
NeoBundle 'deris/vim-rengbang'
NeoBundle 'koron/codic-vim'
NeoBundle 'osyo-manga/vim-over'
NeoBundle "thinca/vim-quickrun"
NeoBundle "osyo-manga/shabadou.vim"
NeoBundle "osyo-manga/vim-watchdogs"
NeoBundle 'KazuakiM/vim-qfsigns'
NeoBundle "dannyob/quickfixstatus"
NeoBundle 'KazuakiM/vim-qfstatusline'
NeoBundle 'sudo.vim'
NeoBundle 'mbbill/undotree'
NeoBundle 'Yggdroot/indentLine'
NeoBundle 'thinca/vim-qfreplace'
NeoBundle 'lervag/vimtex'
NeoBundle 'rhysd/try-colorscheme.vim'
NeoBundle 'terryma/vim-multiple-cursors'
NeoBundle 'bkad/CamelCaseMotion'
NeoBundle 'AndrewRadev/inline_edit.vim'
NeoBundle 'airblade/vim-gitgutter'
NeoBundle 'lambdalisue/vim-gita'
NeoBundle 'csscomb/vim-csscomb'

NeoBundle 'kana/vim-textobj-user'
NeoBundle 'kana/vim-textobj-function'
NeoBundle 'kana/vim-textobj-indent'
NeoBundle 'rhysd/vim-textobj-word-column'
NeoBundle 'sgur/vim-textobj-parameter'
NeoBundle 'kana/vim-operator-replace'
NeoBundle 'rhysd/vim-operator-surround'
NeoBundle 'osyo-manga/vim-textobj-multiblock'
NeoBundle 'kana/vim-textobj-entire'
NeoBundle 'osyo-manga/vim-textobj-blockwise'

NeoBundle 'JesseKPhillips/d.vim'
NeoBundle 'digitaltoad/vim-jade'
NeoBundle 'derekwyatt/vim-scala'
NeoBundle 'kchmck/vim-coffee-script'
NeoBundle 'gf3/peg.vim'
NeoBundle 'pangloss/vim-javascript'
NeoBundle 'mxw/vim-jsx'
NeoBundle 'elzr/vim-json'
NeoBundle 'leafgarland/typescript-vim'

NeoBundle 'mopp/mopkai.vim'
NeoBundle 'freeo/vim-kalisi'

call neobundle#end()

filetype plugin indent on


" thinca/vim-ambicmd
cnoremap <expr> <CR>    ambicmd#expand("\<CR>")
cnoremap <expr> <Space> ambicmd#expand("\<Space>")

" Shougo/deoplete.vim
"inoremap <expr><BS> neocomplete#smart_close_popup()."\<C-h>"
let g:deoplete#enable_at_startup = 1

" Shougo/unite.vim
nnoremap <silent> <Leader>uy :<C-u>Unite history/yank<CR>
nnoremap <silent> <Leader>ub :<C-u>Unite buffer<CR>
nnoremap <silent> <Leader>uf :<C-u>Unite -buffer-name=files file file/new<CR>
nnoremap <silent> <Leader>uu :<C-u>Unite file_mru<CR>
nnoremap <silent> <Leader>ur :<C-u>Unite -buffer-name=register register<CR>
nnoremap <silent> <Leader>ug :<C-u>Unite grep:.<CR>
"call unite#custom#source('grep', 'max_candidates', 0)
let g:unite_enable_start_insert=1
let g:unite_source_history_yank_enable =1

if executable('ag')
  "let g:unite_source_grep_command = 'ag'
  "let g:unite_source_grep_default_opts = '-i --nogroup --nocolor -S'
  "let g:unite_source_grep_recursive_opt = ''
endif

" Shougo/vimfiler.vim
let g:vimfiler_as_default_explorer = 1
let g:vimfiler_tree_indentation = 2
let g:vimfiler_ignore_pattern = '\(^\(\.git\|\.\|\.\.\)$\)\|.pyc$\|.o$'
call vimfiler#custom#profile('default', 'context', {
\ 'auto_cd': 1,
\ 'safe': 0,
\})

" Lokaltog/vim-easymotion
nmap s <Plug>(easymotion-s2)
nmap g/ <Plug>(easymotion-sn)
let g:EasyMotion_do_mapping = 0 "Disable default mappings
let g:EasyMotion_enter_jump_first = 1

" kana/vim-submode
let g:submode_timeout = 0
call submode#enter_with('winsize', 'n', '', '<Leader>s')
call submode#map('winsize', 'n', '', '>', '<C-w>>')
call submode#map('winsize', 'n', '', '<', '<C-w><')
call submode#map('winsize', 'n', '', '-', '<C-w>-')
call submode#map('winsize', 'n', '', '+', '<C-w>+')

nmap <Leader>l "ydi,ldi,F,Pw"yP
nmap <Leader>h "ydi,bdi,wP`[F,"yP

" basyura/TweetVim
let g:w3m#command = 'w3m'

" itchyny/lightline.vim
let g:lightline = {
\   'colorscheme': 'wombat',
\   'active' : {
\       'left' : [
\           ['mode', 'paste'],
\           ['syntaxcheck'],
\           ['readonly', 'filename', 'modified']
\       ],
\   },
\   'component': {
\       'readonly': '%{&readonly?"⌬":""}',
\   },
\   'component_expand': {
\       'syntaxcheck': 'qfstatusline#Update'
\   },
\   'component_type': {
\       'syntaxcheck': 'error'
\   },
\   'separator': { 'left': '', 'right': '' },
\   'subseparator': { 'left': '|', 'right': '|' },
\}

" LeafCage/yankround.vim
nmap p <Plug>(yankround-p)
xmap p <Plug>(yankround-p)
nmap P <Plug>(yankround-P)
nmap gp <Plug>(yankround-gp)
xmap gp <Plug>(yankround-gp)
nmap gP <Plug>(yankround-gP)
nmap <C-p> <Plug>(yankround-prev)
nmap <C-n> <Plug>(yankround-next)
let g:yankround_dir = '~/.nvim/backup'
let g:yankround_max_history = 100

" luochen1990/rainbow
let g:rainbow_active = 1

" rhysd/vim-operator-surround
nmap <silent> zs <Plug>(operator-surround-append)

" osyo-manga/vim-textobj-multiblock
omap ab <Plug>(textobj-multiblock-a)
omap ib <Plug>(textobj-multiblock-i)
vmap ab <Plug>(textobj-multiblock-a)
vmap ib <Plug>(textobj-multiblock-i)

" osyo-manga/watchdogs
let g:watchdogs_check_BufWritePost_enable = 1
let g:watchdogs_check_CursorHold_enable = 1
let g:quickrun_config = {
\   'watchdogs_checker/_' : {
\       'outputter/quickfix/open_cmd' : '',
\       'hook/qfsigns_update/enable_exit': 1,
\       'hook/qfsigns_update/priority_exit': 4,
\       'hook/qfstatusline_update/enable_exit' : 1,
\       'hook/qfstatusline_update/priority_exit' : 4,
\   }
\ }

call watchdogs#setup(g:quickrun_config)

" KazuakiM/vim-qfstatusline
let g:Qfstatusline#UpdateCmd = function('lightline#update')

" mbbill/undotree
let g:undotree_WindowLayout = 3

" Yggdroot/indentLine
let g:indentLine_faster = 1
let g:indentLine_noConcealCursor=""

" junegunn/vim-easy-align
vmap <Enter> <Plug>(EasyAlign)

" airblade/vim-gitgutter
let g:gitgutter_map_keys = 0

" AndrewRadev/inline_edit.vim
let g:inline_edit_autowrite = 1

augroup general
    autocmd!

    " .vimrc
    autocmd BufWritePost $MYVIMRC nested source $MYVIMRC

    " 状態の保存と復元
    "autocmd BufWinLeave ?* if(bufname('%')!='') | silent mkview! | endif
    "autocmd BufWinEnter ?* if(bufname('%')!='') | silent loadview | endif

    autocmd BufLeave ?* if(!&readonly && &buftype == '' && filewritable(expand("%:p"))) | w | endif

    autocmd FileType coffee setlocal shiftwidth=2 softtabstop=2 tabstop=2
    autocmd FileType ruby setlocal shiftwidth=2 softtabstop=2 tabstop=2
augroup END

syntax enable

colorscheme mopkai

Guifont Ubuntu Mono:h13
