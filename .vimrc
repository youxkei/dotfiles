filetype off

let $PATH=system("echo \$PATH")

if isdirectory(expand('~/.vim/backup'))
    set backupdir=~/.vim/backup
    set undodir=~/.vim/backup
    set directory=~/.vim/backup

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

set encoding=utf-8
set fileencodings=utf-8,sjis,cp932,euc-jp
set fileformats=unix,mac,dos

set nofoldenable
set foldmethod=indent

set ambiwidth=single
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

set t_Co=256

set modeline

let g:mapleader=","

nnoremap zQ <NOP>
nnoremap <Leader>w :write<CR>

" 空行を追加
nnoremap <silent> <CR> :<C-u>for i in range(1, v:count1) \| call append(line('.'),   '') \| endfor \| silent! call repeat#set("<CR>", v:count1)<CR>

if has('vim_starting')
    set runtimepath+=~/.vim/bundle/neobundle.vim/
endif

let g:neobundle#types#git#default_protocol = 'git'

call neobundle#begin()

NeoBundleFetch 'Shougo/neobundle.vim'

NeoBundle 'mopp/mopkai.vim'
NeoBundle 'molokai'
NeoBundle 'thinca/vim-ambicmd'
NeoBundle 'Shougo/vimproc.vim', {'build' : {'unix' : 'make -f make_unix.mak' , 'mac' : 'make -f make_mac.mak' } }
NeoBundle 'Shougo/neocomplete.vim'
NeoBundle 'Shougo/'    .'unite.vim'
NeoBundle 'Shougo/'    .'unite-ssh'
NeoBundle 'Shougo/'    .'unite-outline'
NeoBundle 'Shougo/'    .'unite-session'
NeoBundle 'Shougo/'    .      'neomru.vim'
NeoBundle 'osyo-manga/'.'unite-fold'
NeoBundle 'thinca/vim-'.'unite-history'
NeoBundle 'mopp/'      .'unite-animemap'
NeoBundle 'Shougo/vimfiler.vim'
NeoBundle 'tpope/vim-fugitive'
NeoBundle 'gregsexton/gitv'
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
NeoBundle 'kana/vim-textobj-user'
NeoBundle 'kana/vim-textobj-function'
NeoBundle 'kana/vim-textobj-indent'
NeoBundle 'kana/vim-operator-user'
NeoBundle 'kana/vim-niceblock'
NeoBundle 'mbbill/undotree'
NeoBundle 'thinca/vim-fontzoom'
NeoBundle 'fcitx.vim'
NeoBundle 'nathanaelkane/vim-indent-guides'
NeoBundle 'luochen1990/rainbow'
NeoBundle 'tpope/vim-repeat'
NeoBundle 'rhysd/clever-f.vim'
NeoBundle 'osyo-manga/vim-textobj-blockwise'
NeoBundle 'VOoM'
NeoBundle 'idanarye/vim-vebugger'
NeoBundle 'junegunn/vim-easy-align'
NeoBundle 'thinca/vim-visualstar'
NeoBundle 'deris/vim-rengbang'
NeoBundle 'koron/codic-vim'
NeoBundle 'osyo-manga/vim-over'
NeoBundle "thinca/vim-quickrun"
NeoBundle "Shougo/vimproc"
NeoBundle "osyo-manga/shabadou.vim"
NeoBundle "osyo-manga/vim-watchdogs"
NeoBundle "cohama/vim-hier"
NeoBundle "dannyob/quickfixstatus"
NeoBundle 'KazuakiM/vim-qfstatusline'
NeoBundle 'sudo.vim'

NeoBundle 'rhysd/vim-textobj-word-column'
NeoBundle 'sgur/vim-textobj-parameter'
NeoBundle 'kana/vim-operator-replace'
NeoBundle 'rhysd/vim-operator-surround'
NeoBundle 'osyo-manga/vim-textobj-multiblock'
NeoBundle 'kana/vim-textobj-entire'

NeoBundle 'JesseKPhillips/d.vim'
NeoBundle 'digitaltoad/vim-jade'
NeoBundle 'derekwyatt/vim-scala'
NeoBundle 'kchmck/vim-coffee-script'
NeoBundle 'gf3/peg.vim'
NeoBundle 'pangloss/vim-javascript'
NeoBundle 'mxw/vim-jsx'

call neobundle#end()

filetype plugin indent on


" thinca/vim-ambicmd
cnoremap <expr> <CR>    ambicmd#expand("\<CR>")
cnoremap <expr> <Space> ambicmd#expand("\<Space>")

" Shougo/neocomplete.vim
inoremap <expr><BS> neocomplete#smart_close_popup()."\<C-h>"
let g:neocomplete#enable_at_startup = 1

" Shougo/unite.vim
nnoremap <silent> <Leader>uy :<C-u>Unite history/yank<CR>
nnoremap <silent> <Leader>ub :<C-u>Unite buffer<CR>
nnoremap <silent> <Leader>uf :<C-u>Unite -buffer-name=files file file/new<CR>
nnoremap <silent> <Leader>uu :<C-u>Unite file_mru<CR>
nnoremap <silent> <Leader>ur :<C-u>Unite -buffer-name=register register<CR>
let g:unite_enable_start_insert=1
let g:unite_source_history_yank_enable =1

" Shougo/vimfiler.vim
let g:vimfiler_as_default_explorer = 1
let g:vimfiler_safe_mode_by_default = 0
let g:vimfiler_tree_indentation = 2
let g:vimfiler_ignore_pattern = '\(^\(\.git\|\.\|\.\.\)$\)\|.pyc$'

" Lokaltog/vim-easymotion
nmap s <Plug>(easymotion-s2)
nmap g/ <Plug>(easymotion-sn)
let g:EasyMotion_do_mapping = 0 "Disable default mappings
let g:EasyMotion_enter_jump_first = 1

" kana/vim-submode
let g:submode_timeout = 0
call submode#enter_with('winsize', 'n', '', '<Leader><Leader>w')
call submode#map('winsize', 'n', '', '>', '<C-w>>')
call submode#map('winsize', 'n', '', '<', '<C-w><')
call submode#map('winsize', 'n', '', '-', '<C-w>-')
call submode#map('winsize', 'n', '', '+', '<C-w>+')

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
nmap P <Plug>(yankround-P)
nmap <C-p> <Plug>(yankround-prev)
nmap <C-n> <Plug>(yankround-next)
let g:yankround_dir = '~/.vim/backup'
let g:yankround_max_history = 100

" scrooloose/syntastic
let g:syntastic_check_on_open = 1
let g:syntastic_auto_loc_list = 1
"let g:syntastic_auto_jump = 2
let g:syntastic_auto_jump = 0
let g:syntastic_loc_list_height = 5
let g:syntastic_d_compiler_options = '-unittest, -debug'

" nathanaelkane/vim-indent-guides
let g:indent_guides_enable_on_vim_startup = 1

" luochen1990/rainbow
let g:rainbow_active = 1

" rhysd/vim-operator-surround
nmap <silent> zs <Plug>(operator-surround-append)

" osyo-manga/vim-textobj-multiblock
omap ab <Plug>(textobj-multiblock-a)
omap ib <Plug>(textobj-multiblock-i)
vmap ab <Plug>(textobj-multiblock-a)
vmap ib <Plug>(textobj-multiblock-i)

" nathanaelkane/vim-indent-guides
let g:indent_guides_guide_size=1

" osyo-manga/watchdogs
let g:watchdogs_check_BufWritePost_enable = 1
let g:watchdogs_check_CursorHold_enable = 1
let g:quickrun_config = {
\   'watchdogs_checker/_' : {
\       'outputter/quickfix/open_cmd' : '',
\       'hook/qfstatusline_update/enable_exit' : 1,
\       'hook/qfstatusline_update/priority_exit' : 4,
\   }
\ }

call watchdogs#setup(g:quickrun_config)

" KazuakiM/vim-qfstatusline
let g:Qfstatusline#UpdateCmd = function('lightline#update')

augroup general
    autocmd!

    " .vimrc
    autocmd BufWritePost $MYVIMRC nested source $MYVIMRC

    " 状態の保存と復元
    autocmd BufWinLeave ?* if(bufname('%')!='') | silent mkview! | endif
    autocmd BufWinEnter ?* if(bufname('%')!='') | silent loadview | endif

    autocmd BufLeave ?* if(!&readonly && &buftype == '' && filewritable(expand("%:p"))) | w | endif

    autocmd FileType coffee setlocal shiftwidth=2 softtabstop=2 tabstop=2
    autocmd FileType ruby setlocal shiftwidth=2 softtabstop=2 tabstop=2
augroup END

syntax enable

color mopkai
