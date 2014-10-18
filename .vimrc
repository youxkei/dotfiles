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
set cursorline

set scrolloff=16
set sidescroll=1
"set sidescrolloff=32
set laststatus=2

set viewoptions=cursor,folds
set wildmenu

set list
set listchars=tab:»-,trail:-,nbsp:%

set t_Co=256

set spelllang+=cjk
set spell

let g:mapleader=","

nnoremap zQ <NOP>
nnoremap <Leader>w :write<CR>

" 空行を追加
nnoremap <silent> <CR> :<C-u>for i in range(1, v:count1) \| call append(line('.'),   '') \| endfor \| silent! call repeat#set("<CR>", v:count1)<CR>

if has('vim_starting')
    set runtimepath+=~/.vim/bundle/neobundle.vim/
endif

let g:neobundle#types#git#default_protocol = 'git'

call neobundle#rc(expand('~/.vim/bundle/'))

NeoBundleFetch 'Shougo/neobundle.vim'

NeoBundle 'mopp/mopkai.vim'

NeoBundle 'molokai'

NeoBundle 'JesseKPhillips/d.vim'

NeoBundle 'digitaltoad/vim-jade'

" 重すぎ笑えない
" NeoBundle 'Yggdroot/indentLine'
" let g:indentLine_color_term = 111
" let g:indentLine_color_gui = '#708090'
" let g:indentLine_char = '|'

NeoBundle 'thinca/vim-ambicmd'
cnoremap <expr> <CR>    ambicmd#expand("\<CR>")
cnoremap <expr> <Space> ambicmd#expand("\<Space>")

NeoBundle 'Shougo/vimproc.vim', {'build' : {'unix' : 'make -f make_unix.mak' , 'mac' : 'make -f make_mac.mak' } }

NeoBundle 'Shougo/neocomplete.vim'
let g:neocomplete#enable_at_startup = 1
inoremap <expr><BS> neocomplete#smart_close_popup()."\<C-h>"

NeoBundle 'Shougo/unite.vim'
let g:unite_enable_start_insert=1
let g:unite_source_history_yank_enable =1
nnoremap <silent> ,uy :<C-u>Unite history/yank<CR>
nnoremap <silent> ,ub :<C-u>Unite buffer<CR>
nnoremap <silent> ,uf :<C-u>Unite -buffer-name=files file file/new<CR>
nnoremap <silent> ,uu :<C-u>Unite file_mru<CR>
nnoremap <silent> ,ur :<C-u>Unite -buffer-name=register register<CR>

NeoBundle     'Shougo/unite-ssh'
NeoBundle 'osyo-manga/unite-fold'
NeoBundle 'thinca/vim-unite-history'
NeoBundle     'Shougo/unite-outline'
NeoBundle     'Shougo/unite-session'
NeoBundle           'Shougo/neomru.vim'

NeoBundle 'Shougo/vimfiler.vim'
let g:vimfiler_as_default_explorer = 1
let g:vimfiler_safe_mode_by_default = 0
let g:vimfiler_tree_indentation = 2
let g:vimfiler_ignore_pattern = '^\(.git\|\.\|\.\.\)$'

NeoBundle 'tpope/vim-surround'

NeoBundle 'tpope/vim-fugitive'

NeoBundle 'gregsexton/gitv'

NeoBundle 'ujihisa/neco-look'

NeoBundle 'Lokaltog/vim-easymotion'
let g:EasyMotion_do_mapping = 0 "Disable default mappings
nmap s <Plug>(easymotion-s2)
nmap g/ <Plug>(easymotion-sn)
let g:EasyMotion_enter_jump_first = 1

" 古い
" NeoBundle 'Rainbow-Parentheses-Improved-and2'
" let g:rainbow_active = 1
" let g:rainbow_operators = 1

NeoBundle 'kana/vim-smartchr'

NeoBundle 'kana/vim-smartinput'

NeoBundle 'kana/vim-submode'
let g:submode_timeout = 0
call submode#enter_with('winsize', 'n', '', '<Leader><Leader>w')
call submode#map('winsize', 'n', '', '>', '<C-w>>')
call submode#map('winsize', 'n', '', '<', '<C-w><')
call submode#map('winsize', 'n', '', '-', '<C-w>-')
call submode#map('winsize', 'n', '', '+', '<C-w>+')

NeoBundle 'basyura/TweetVim'
let g:w3m#command = 'w3m'

NeoBundle 'basyura/twibill.vim'

NeoBundle 'tyru/open-browser.vim'

NeoBundle 'mattn/gist-vim'

NeoBundle 'mattn/webapi-vim'

NeoBundle 'itchyny/lightline.vim'
let g:lightline = {
\   'colorscheme': 'wombat',
\   'active' : {
\       'left' : [
\           ['mode', 'paste'],
\           ['readonly', 'filename', 'modified']
\       ]
\   },
\   'component': {
\       'readonly': '%{&readonly?"⌬":""}',
\   },
\   'separator': { 'left': '', 'right': '' },
\   'subseparator': { 'left': '|', 'right': '|' },
\}

NeoBundle 'kannokanno/previm'

NeoBundle 'LeafCage/yankround.vim'
let g:yankround_dir = '~/.vim/backup'
let g:yankround_max_history = 100
nmap p <Plug>(yankround-p)
nmap P <Plug>(yankround-P)
nmap <C-p> <Plug>(yankround-prev)
nmap <C-n> <Plug>(yankround-next)


" Syntasticと相性が悪い
" NeoBundle 'mopp/shinchoku.vim'

NeoBundle 'kana/vim-textobj-user'

" 何故か動かない
" NeoBundle 'h1mesuke/textobj-wiw'
" let g:textobj_wiw_default_key_mappings_prefix = ","

NeoBundle 'kana/vim-textobj-function'

NeoBundle 'kana/vim-textobj-indent'

" いらない感すごい
" NeoBundle 't9md/vim-quickhl'
" let g:quickhl_cword_enable_at_startup = 2

NeoBundle 'kana/vim-operator-user'

NeoBundle 'mopp/unite-animemap'

NeoBundle 'kana/vim-niceblock'

" うーん、微妙に必要なさ気
" NeoBundle 'osyo-manga/vim-anzu'
" nmap n <Plug>(anzu-mode-n)
" nmap N <Plug>(anzu-mode-N)


NeoBundle 'mbbill/undotree'

NeoBundle 'derekwyatt/vim-scala'

NeoBundle 'thinca/vim-fontzoom'

NeoBundle 'fcitx.vim'

NeoBundle 'scrooloose/syntastic'
let g:syntastic_check_on_open = 1
let g:syntastic_auto_loc_list = 1
"let g:syntastic_auto_jump = 2
let g:syntastic_auto_jump = 0
let g:syntastic_loc_list_height = 5
let g:syntastic_d_compiler_options = '-unittest, -debug'

NeoBundle 'kchmck/vim-coffee-script'

NeoBundle 'nathanaelkane/vim-indent-guides'
let g:indent_guides_enable_on_vim_startup=1

NeoBundle 'oblitum/rainbow'

NeoBundle 'tpope/vim-repeat'

NeoBundle 'rhysd/clever-f.vim'

NeoBundle 'osyo-manga/vim-textobj-blockwise'

NeoBundle 'VOoM'

NeoBundle 'idanarye/vim-vebugger'

augroup general
    autocmd!

    " .vimrc
    autocmd BufWritePost $MYVIMRC nested source $MYVIMRC

    " 状態の保存と復元
    autocmd BufWinLeave ?* if(bufname('%')!='') | silent mkview! | endif
    autocmd BufWinEnter ?* if(bufname('%')!='') | silent loadview | endif

    autocmd BufLeave ?* if(!&readonly && &buftype == '') | w | endif

    autocmd FileType coffee setlocal shiftwidth=2 softtabstop=2 tabstop=2
    autocmd FileType ruby setlocal shiftwidth=2 softtabstop=2 tabstop=2
augroup END

filetype plugin indent on

syntax enable

color mopkai
