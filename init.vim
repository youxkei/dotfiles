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

if has('vim_starting')
    if !isdirectory(expand('~/.cache/nvim/bundle/neobundle.vim'))
        call mkdir(expand('~/.cache/nvim/bundle'), 'p')
        !git clone https://github.com/Shougo/neobundle.vim ~/.cache/nvim/bundle/neobundle.vim
    endif
    set runtimepath+=~/.cache/nvim/bundle/neobundle.vim/

    command -nargs=? Guifont call rpcnotify(0, 'Gui', 'SetFont', "<args>") | let g:Guifont="<args>"
endif

call neobundle#begin(expand('~/.cache/nvim/bundle/'))

NeoBundleFetch 'Shougo/neobundle.vim'

NeoBundle 'thinca/vim-ambicmd'
NeoBundle 'Shougo/vimproc.vim', {'build' : {'linux' : 'make' } }
NeoBundle 'Shougo/deoplete.nvim'
NeoBundle 'ujihisa/neco-look'
NeoBundle 'Shougo/neco-syntax'
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
NeoBundle 'VOoM'
NeoBundle 'idanarye/vim-vebugger'
NeoBundle 'junegunn/vim-easy-align'
NeoBundle 'thinca/vim-visualstar'
NeoBundle 'deris/vim-rengbang'
NeoBundle 'koron/codic-vim'
NeoBundle 'osyo-manga/vim-over'
NeoBundle 'thinca/vim-quickrun'
NeoBundle 'osyo-manga/shabadou.vim'
"NeoBundle 'osyo-manga/vim-watchdogs'
NeoBundle 'KazuakiM/vim-qfsigns'
NeoBundle 'dannyob/quickfixstatus'
NeoBundle 'KazuakiM/vim-qfstatusline'
NeoBundle 'sudo.vim'
NeoBundle 'mbbill/undotree'
NeoBundle 'Yggdroot/indentLine'
NeoBundle 'thinca/vim-qfreplace'
"NeoBundle 'lervag/vimtex'
NeoBundle 'rhysd/try-colorscheme.vim'
NeoBundle 'terryma/vim-multiple-cursors'
NeoBundle 'bkad/CamelCaseMotion'
NeoBundle 'AndrewRadev/inline_edit.vim'
NeoBundle 'airblade/vim-gitgutter'
NeoBundle 'lambdalisue/vim-gita'
NeoBundle 'csscomb/vim-csscomb'
NeoBundle 'wakatime/vim-wakatime'
"NeoBundle 'scrooloose/syntastic'
NeoBundle 'Shougo/vinarise.vim'
NeoBundle 'rhysd/committia.vim'
NeoBundle 'derekwyatt/vim-fswitch'
NeoBundle 'jiangmiao/auto-pairs'

NeoBundle 'kana/vim-textobj-user'
NeoBundle 'kana/vim-textobj-function'
NeoBundle 'kana/vim-textobj-indent'
NeoBundle 'rhysd/vim-textobj-word-column'
NeoBundle 'sgur/vim-textobj-parameter'
NeoBundle 'kana/vim-operator-replace'
NeoBundle 'rhysd/vim-operator-surround'
NeoBundle 'kana/vim-textobj-entire'
NeoBundle 'osyo-manga/vim-textobj-blockwise'
NeoBundle 'rhysd/vim-textobj-anyblock'
NeoBundle 'haya14busa/vim-operator-flashy'

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
NeoBundle 'joshdick/onedark.vim'
NeoBundle 'NLKNguyen/papercolor-theme'
NeoBundle 'morhetz/gruvbox'

call neobundle#end()

NeoBundleInstall

filetype plugin indent on


if neobundle#is_sourced('vim-ambicmd')
    cnoremap <expr> <CR>    ambicmd#expand("\<CR>")
    cnoremap <expr> <Space> ambicmd#expand("\<Space>")
endif

if neobundle#is_sourced('deoplete.nvim')
    let g:deoplete#enable_at_startup = 1
    let g:deoplete#omni_patterns = {}
endif

if neobundle#is_sourced('unite.vim')
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
endif

if neobundle#is_sourced('vimfiler.vim')
    let g:vimfiler_as_default_explorer = 1
    let g:vimfiler_tree_indentation = 2
    let g:vimfiler_ignore_pattern = '\(^\(\.git\|\.\|\.\.\)$\)\|.pyc$\|.o$'
    call vimfiler#custom#profile('default', 'context', { 'auto_cd': 1,  'safe': 0 })
endif

if neobundle#is_sourced('vim-easymotion')
    nmap <Leader>s <Plug>(easymotion-s2)
    nmap <Leader>gs <Plug>(easymotion-sn)
    let g:EasyMotion_do_mapping = 0 "Disable default mappings
    let g:EasyMotion_enter_jump_first = 1
endif

if neobundle#is_sourced('vim-submode')
    let g:submode_timeout = 0
    call submode#enter_with('winsize', 'n', '', '<Leader>ws')
    call submode#map('winsize', 'n', '', 'h', '<C-w><')
    call submode#map('winsize', 'n', '', 'j', '<C-w>-')
    call submode#map('winsize', 'n', '', 'k', '<C-w>+')
    call submode#map('winsize', 'n', '', 'l', '<C-w>>')
endif

if neobundle#is_sourced('TweetVim')
    let g:w3m#command = 'w3m'
endif

if neobundle#is_sourced('lightline.vim')
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
endif

if neobundle#is_sourced('yankround.vim')
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
endif

if neobundle#is_sourced('rainbow')
    let g:rainbow_active = 1
endif

if neobundle#is_sourced('vim-operator-surround')
    map <silent>sa <Plug>(operator-surround-append)
    map <silent>sd <Plug>(operator-surround-delete)
    map <silent>sr <Plug>(operator-surround-replace)

    if neobundle#is_sourced('vim-textobj-anyblock')
        nmap <silent>sdd <Plug>(operator-surround-delete)<Plug>(textobj-anyblock-a)
        nmap <silent>srr <Plug>(operator-surround-replace)<Plug>(textobj-anyblock-a)
    endif
endif

if neobundle#is_sourced('watchdogs')
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
endif

if neobundle#is_sourced('vim-qfstatusline')
    let g:Qfstatusline#UpdateCmd = function('lightline#update')
endif

if neobundle#is_sourced('undotree')
    let g:undotree_WindowLayout = 3
endif

if neobundle#is_sourced('indentLine')
    let g:indentLine_faster = 1
    let g:indentLine_noConcealCursor=""
endif

if neobundle#is_sourced('vim-easy-align')
    vmap <Enter> <Plug>(EasyAlign)
endif

if neobundle#is_sourced('vim-gitgutter')
    let g:gitgutter_map_keys = 0
endif

if neobundle#is_sourced('inline_edit.vim')
    let g:inline_edit_autowrite = 1
endif

if neobundle#is_sourced('vim-textobj-parameter')
    nmap <Leader>l "adi,"bdw"cdi,"cP"bp"ap
endif

if neobundle#is_sourced('vim-operator-flashy')
    map y <Plug>(operator-flashy)
    nmap Y <Plug>(operator-flashy)$
endif

if neobundle#is_sourced('syntastic')
    let g:syntastic_always_populate_loc_list = 1
    let g:syntastic_auto_loc_list = 0
    let g:syntastic_check_on_open = 1
    let g:syntastic_check_on_wq = 1
endif

if neobundle#is_sourced('vim-multiple-cursors')
    let g:multi_cursor_start_key='<F6>'
end

if neobundle#is_sourced('vim-fswitch')
    nnoremap <silent><Leader>f :FSHere<CR>
endif

augroup general
    au!

    " .vimrc
    au BufWritePost $MYVIMRC nested source $MYVIMRC

    " 状態の保存と復元
    "autocmd BufWinLeave ?* if(bufname('%')!='') | silent mkview! | endif
    "autocmd BufWinEnter ?* if(bufname('%')!='') | silent loadview | endif

    au BufEnter *.h let b:fswitchdst  = 'cpp,c'
    au BufEnter *.h let b:fswitchlocs = 'reg:/include/src/'

    au BufEnter *.cpp let b:fswitchdst  = 'h'
    au BufEnter *.cpp let b:fswitchlocs = 'reg:/src/include/'

    au BufLeave ?* if(!&readonly && &buftype == '' && filewritable(expand("%:p"))) | w | endif

    au FileType coffee setlocal shiftwidth=2 softtabstop=2 tabstop=2
    au FileType ruby setlocal shiftwidth=2 softtabstop=2 tabstop=2
augroup END

syntax enable

"if neobundle#is_sourced('papercolor-theme')
"    set background=dark
"    colorscheme PaperColor
"endif

if neobundle#is_sourced('gruvbox')
    set background=dark
    colorscheme gruvbox
endif

Guifont Ubuntu Mono:h8
