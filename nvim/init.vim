augroup general
  autocmd!
augroup END

if !isdirectory(expand('~/.cache/nvim'))
  call mkdir(expand('~/.cache/nvim/backup'), 'p')
  call mkdir(expand('~/.cache/nvim/undo'),   'p')
  call mkdir(expand('~/.cache/nvim/swap'),   'p')
endif

" set {{{

set termguicolors

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
set shiftwidth=4
set softtabstop=4
set smarttab
set tabstop=4

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
set showtabline=2
set backspace=indent,eol,start

set cursorline
set cursorcolumn

set scrolloff=16
set sidescroll=1
"set sidescrolloff=32
set laststatus=2

set viewoptions=cursor
set wildmenu
set signcolumn=yes
set completeopt-=preview

set list
set listchars=tab:\|\ ,trail:-,nbsp:%

set modeline

set inccommand=nosplit

set autoread

set scrollback=2000
set synmaxcol=512

set updatetime=100

set iskeyword=@,48-57,_,192-255,$,@-@,-

set clipboard=unnamedplus

let loaded_matchparen = 1

let g:mapleader = ','
let g:tex_conceal = ''
let g:tex_flavor = 'latex'

" set }}}

" map {{{

nnoremap <Leader>w :w<CR>

nnoremap Q <NOP>
nnoremap <expr> i empty(getline('.')) ? "cc" : "i"
nnoremap <expr> a empty(getline('.')) ? "cc" : "a"
nnoremap <silent> <C-H> ^
vnoremap <silent> <C-G> <NOP>

tnoremap <ESC> <C-\><C-N>
tnoremap <C-W><C-H> <C-\><C-N><C-W><C-H>
tnoremap <C-W><C-J> <C-\><C-N><C-W><C-J>
tnoremap <C-W><C-K> <C-\><C-N><C-W><C-K>
tnoremap <C-W><C-L> <C-\><C-N><C-W><C-L>
tnoremap <C-W><C-T> <C-\><C-N><C-W><C-T>
tnoremap <C-W><C-V> <C-\><C-N><C-W><C-V>
tnoremap <C-W><C-S> <C-\><C-N><C-W><C-S>

nnoremap j gj
nnoremap k gk
nnoremap gj j
nnoremap gk k

noremap  <silent> <C-B>1 <ESC>1gt
noremap! <silent> <C-B>1 <ESC>1gt
noremap  <silent> <C-B>2 <ESC>2gt
noremap! <silent> <C-B>2 <ESC>2gt
noremap  <silent> <C-B>3 <ESC>3gt
noremap! <silent> <C-B>3 <ESC>3gt
noremap  <silent> <C-B>4 <ESC>4gt
noremap! <silent> <C-B>4 <ESC>4gt
noremap  <silent> <C-B>5 <ESC>5gt
noremap! <silent> <C-B>5 <ESC>5gt
noremap  <silent> <C-B>6 <ESC>6gt
noremap! <silent> <C-B>6 <ESC>6gt
noremap  <silent> <C-B>7 <ESC>7gt
noremap! <silent> <C-B>7 <ESC>7gt
noremap  <silent> <C-B>8 <ESC>8gt
noremap! <silent> <C-B>8 <ESC>8gt
noremap  <silent> <C-B>9 <ESC>:<C-U>tablast<CR>
noremap! <silent> <C-B>9 <ESC>:<C-U>tablast<CR>

" map }}}

" autocmd {{{

augroup general
  " autosource
  autocmd BufWritePost $MYVIMRC nested source $MYVIMRC
  autocmd BufWritePost $MYGVIMRC nested source $MYGVIMRC

  autocmd BufEnter * checktime

  autocmd BufEnter *.erl set sw=4 ts=4 sts=4

  autocmd BufEnter *.res set sw=2 ts=2 sts=2

  autocmd InsertLeave * call system('fcitx-remote -c')
augroup END

" autocmd }}}

" vim-plug {{{

if empty(glob('~/.local/share/nvim/site/autoload/plug.vim'))
  silent !curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.cache/nvim/vim-plug')

" plugins {{{
Plug 'thinca/vim-ambicmd'

Plug 'Shougo/deoplete.nvim'
let g:deoplete#enable_at_startup = 1

"Plug 'tbodt/deoplete-tabnine', { 'do': './install.sh' }

Plug 'ujihisa/neco-look'

Plug 'Shougo/neco-syntax'

Plug 'fszymanski/deoplete-emoji'

Plug 'Shougo/denite.nvim'
nnoremap <silent> <Leader>eu :<C-u>Denite file_mru -start-filter<CR>
nnoremap <silent> <Leader>ed :<C-u>Denite directory_mru -start-filter<CR>
nnoremap <silent> <Leader>eg :<C-u>Denite grep -start-filter<CR>
nnoremap <silent> <Leader>ef :<C-u>Denite file/rec -start-filter<CR>
nnoremap <silent> <Leader>eb :<C-u>Denite buffer -start-filter<CR>
nnoremap <silent> <Leader>ec :<C-u>Denite buffer/cd file/rec -start-filter<CR>
nnoremap <silent> <Leader>el :<C-u>Denite line -start-filter<CR>
nnoremap <silent> <Leader>er :<C-u>Denite -resume -refresh<CR>

augroup general
  autocmd FileType denite call s:set_mappings_for_denite()
  function! s:set_mappings_for_denite() abort
    nnoremap <silent><buffer><expr> <CR>  denite#do_map('do_action')
    nnoremap <silent><buffer><expr> d     denite#do_map('do_action', 'delete')
    nnoremap <silent><buffer><expr> p     denite#do_map('do_action', 'preview')
    nnoremap <silent><buffer><expr> q     denite#do_map('quit')
    nnoremap <silent><buffer><expr> <ESC> denite#do_map('quit')
    nnoremap <silent><buffer><expr> i     denite#do_map('open_filter_buffer')
  endfunction

  autocmd FileType denite-filter call s:set_mappings_for_denite_filter()
  function! s:set_mappings_for_denite_filter() abort
    imap <silent><buffer> <ESC> <Plug>(denite_filter_quit)
  endfunction
augroup END

Plug 'raghur/fruzzy', {'do': { -> fruzzy#install() }}
let g:fruzzy#usenative = 1

Plug 'liuchengxu/vim-clap', { 'do': ':Clap install-binary' }

Plug 'notomo/denite-keymap'

Plug 'Shougo/neomru.vim'

Plug 'easymotion/vim-easymotion'
let g:EasyMotion_keys = 'aoeuidhtns,.pgcr'
let g:EasyMotion_do_mapping = 0
let g:EasyMotion_smartcase = 1
let g:EasyMotion_use_smartsign_jp = 1

nmap s <Plug>(easymotion-overwin-f2)

Plug 'tyru/open-browser.vim'

Plug 'mattn/webapi-vim'

Plug 'mattn/gist-vim'

Plug 'itchyny/lightline.vim'
let g:lightline = {
\ 'colorscheme': 'nord',
\ 'active': {
\   'left': [
\     ['cwd', 'mode', 'paste'],
\     ['readonly', 'relativepath', 'modified', 'ale_wornings', 'ale_errors']
\   ],
\ },
\ 'tab': {
\   'active': ['tabnum', 'cwd'],
\   'inactive': ['tabnum', 'cwd'],
\  },
\ 'component': {
\   'readonly': '%{&readonly?"⌬":""}',
\ },
\ 'component_expand': {
\   'ale_warnings': 'lightline#ale#warnings',
\   'ale_errors': 'lightline#ale#errors',
\ },
\ 'component_type': {
\   'ale_warnings': 'warning',
\   'ale_errors': 'error',
\ },
\ 'tab_component_function': {
\   'cwd': 'LightlineCWD',
\ },
\ 'separator': { 'left': '', 'right': '' },
\ 'subseparator': { 'left': '', 'right': '' },
\}
function! LightlineCWD(n) abort
  let cwd = gettabvar(a:n, 'cwd')
  return fnamemodify(empty(cwd) ? getcwd() : cwd, ":t")
endfunction

Plug 'maximbaz/lightline-ale'

Plug 'kannokanno/previm'

Plug 'LeafCage/yankround.vim'
let g:yankround_dir = '~/.cache/nvim/yankround'
let g:yankround_max_history = 100

nmap p <Plug>(yankround-p)
xmap p <Plug>(yankround-p)
nmap P <Plug>(yankround-P)
nmap gp <Plug>(yankround-gp)
xmap gp <Plug>(yankround-gp)
nmap gP <Plug>(yankround-gP)
nmap <C-p> <Plug>(yankround-prev)
nmap <C-n> <Plug>(yankround-next)

Plug 'kana/vim-niceblock'

Plug 'luochen1990/rainbow'
let g:rainbow_active = 1
let g:rainbow_conf = {
\ 'guifgs': ['darkorange3', 'seagreen3', 'firebrick'],
\ 'ctermfgs': ['lightyellow', 'lightcyan', 'lightmagenta'],
\}

Plug 'tpope/vim-repeat'

Plug 'vim-scripts/VOoM'

Plug 'junegunn/vim-easy-align'
vmap <Enter> <Plug>(EasyAlign)

Plug 'deris/vim-rengbang'

Plug 'mbbill/undotree'
let g:undotree_WindowLayout = 3

Plug 'Yggdroot/indentLine'
let g:indentLine_char = '┊'
let g:indentLine_conceallevel = 1

Plug 'terryma/vim-multiple-cursors'

Plug 'AndrewRadev/inline_edit.vim'
let g:inline_edit_autowrite = 1

Plug 'airblade/vim-gitgutter'
let g:gitgutter_map_keys = 0

Plug 'Shougo/vinarise.vim'

Plug 'rhysd/committia.vim'

Plug 'derekwyatt/vim-fswitch'

augroup general
  autocmd BufEnter *.h let b:fswitchdst  = 'cpp,c'
  autocmd BufEnter *.h let b:fswitchlocs = 'reg:/include/src/'
  autocmd BufEnter *.cpp let b:fswitchdst  = 'h'
  autocmd BufEnter *.cpp let b:fswitchlocs = 'reg:/src/include/'

  autocmd BufEnter *.smi let b:fswitchdst  = 'sml'
  autocmd BufEnter *.smi let b:fswitchlocs  = '.'
  autocmd BufEnter *.sml let b:fswitchdst  = 'smi'
  autocmd BufEnter *.sml let b:fswitchlocs  = '.'

  autocmd BufEnter *.mli let b:fswitchdst  = 'ml'
  autocmd BufEnter *.mli let b:fswitchlocs  = '.'
  autocmd BufEnter *.ml let b:fswitchdst  = 'mli'
  autocmd BufEnter *.ml let b:fswitchlocs  = '.'
augroup END

Plug 'Shougo/context_filetype.vim'

Plug 'osyo-manga/vim-precious'

Plug 'kana/vim-tabpagecd'

Plug 't9md/vim-choosewin'
let g:choosewin_overlay_enable = 1
let g:choosewin_overlay_clear_multibyte = 1
let g:choosewin_blink_on_land = 0
let g:choosewin_statusline_replace = 0
let g:choosewin_tabline_replace = 0

nmap  <Leader>-  <Plug>(choosewin)

Plug 'w0rp/ale'
let g:ale_lint_on_save = 1
let g:ale_lint_on_text_changed = 1
let g:ale_erlang_erlc_options = '-I./deps/*/include'

let g:ale_linters = {
\ 'go': [],
\ 'rust': [],
\ 'erlang': ['syntaxerl'],
\}

let g:ale_fixers = {
\ '*': ['remove_trailing_lines', 'trim_whitespace'],
\ 'rust': ['rustfmt'],
\ 'go': ['gofmt', 'goimports'],
\ 'javascript': ['prettier'],
\}
let g:ale_fix_on_save = 1

nmap <silent> <C-k> <Plug>(ale_previous_wrap)
nmap <silent> <C-j> <Plug>(ale_next_wrap)

Plug 'machakann/vim-swap'
let g:swap_no_default_key_mappings = 1

nmap gs <Plug>(swap-interactive)
omap i, <Plug>(swap-textobject-i)
xmap i, <Plug>(swap-textobject-i)
omap a, <Plug>(swap-textobject-a)
xmap a, <Plug>(swap-textobject-a)

Plug 'lambdalisue/suda.vim'
let g:suda_smart_edit = 1

Plug 'sgur/vim-editorconfig'

Plug 'prakashdanish/vim-githubinator'

Plug 'lambdalisue/gina.vim'

Plug 'lambdalisue/vim-manpager', { 'on': 'MANPAGER' }

Plug 'majutsushi/tagbar'

Plug 'rhysd/clever-f.vim'

Plug 'haya14busa/is.vim'

Plug 'haya14busa/vim-asterisk'
map *  <Plug>(asterisk-z*)<Plug>(is-nohl-1)
map g* <Plug>(asterisk-gz*)<Plug>(is-nohl-1)
map #  <Plug>(asterisk-z#)<Plug>(is-nohl-1)
map g# <Plug>(asterisk-gz#)<Plug>(is-nohl-1)

let g:asterisk#keeppos = 1

Plug 'osyo-manga/vim-anzu'
map n <Plug>(is-nohl)<Plug>(anzu-n-with-echo)
map N <Plug>(is-nohl)<Plug>(anzu-N-with-echo)

Plug 'scrooloose/nerdtree'
nnoremap <silent> <Leader>f :<C-U>NERDTreeToggle<CR>

Plug 'prabirshrestha/async.vim'

Plug 'prabirshrestha/vim-lsp'

Plug 'mattn/vim-lsp-settings'

Plug 'lighttiger2505/deoplete-vim-lsp'

Plug 'junegunn/fzf'

Plug 'junegunn/fzf.vim'
nmap <silent> <C-B><Tab> <plug>(fzf-maps-n)
imap <silent> <C-B><Tab> <plug>(fzf-maps-i)
xmap <silent> <C-B><Tab> <plug>(fzf-maps-x)
omap <silent> <C-B><Tab> <plug>(fzf-maps-o)

Plug 'tpope/vim-fugitive'

Plug 'liuchengxu/vista.vim'
nnoremap <silent> <Leader>v :<C-U>Vista finder<CR>

Plug 'Shougo/deol.nvim'

Plug 'chaoren/vim-wordmotion'
let g:wordmotion_spaces = '_-.'
let g:wordmotion_mappings = {
\ 'W' : '',
\ 'B' : '',
\ 'E' : '',
\ 'GE' : '',
\ 'aW' : '',
\ 'iW' : ''
\ }
nnoremap W w
nnoremap B b
nnoremap E e
nnoremap gE ge
onoremap W w
xnoremap W w
onoremap B b
xnoremap B b
onoremap E e
xnoremap E e
onoremap GE ge
xnoremap GE ge
xnoremap iW iw
onoremap iW iw
xnoremap aW aw
onoremap aW aw

Plug 'tmsvg/pear-tree'
let g:pear_tree_repeatable_expand = 0
let g:pear_tree_ft_disabled = ['denite-filter']

Plug 'AndrewRadev/linediff.vim'

Plug 'thinca/vim-qfreplace'

Plug 'youxkei/vim-erlang-tags'

Plug 'inkarkat/vim-ingo-library'
Plug 'inkarkat/vim-mark'
let g:mw_no_mappings = 1
let g:mwDefaultHighlightingPalette = 'maximum'
nmap <Leader>m <Plug>MarkSet
vmap <Leader>m <Plug>MarkSet
nmap <Leader>n <Plug>MarkAllClear

" plugins }}}

" colorschemes {{{

Plug 'arcticicestudio/nord-vim'

" colorschemes }}}

" syntax {{{

Plug 'JesseKPhillips/d.vim'

Plug 'elzr/vim-json'
let g:vim_json_syntax_conceal = 0

Plug 'vim-scripts/lojban'

Plug 'qnighy/satysfi.vim'

Plug 'plasticboy/vim-markdown'
let g:vim_markdown_conceal = 0
let g:vim_markdown_conceal_code_blocks = 0
let g:vim_markdown_no_default_key_mappings = 1

Plug 'vim-erlang/vim-erlang-runtime'

Plug 'LnL7/vim-nix'

Plug 'amiralies/vim-rescript'

" syntax }}}

" text objects & operators {{{

Plug 'kana/vim-textobj-user'

Plug 'kana/vim-operator-user'

Plug 'kana/vim-textobj-indent'

Plug 'rhysd/vim-textobj-word-column'

Plug 'sgur/vim-textobj-parameter'

Plug 'kana/vim-operator-replace'
map _  <Plug>(operator-replace)

Plug 'kana/vim-textobj-entire'

Plug 'haya14busa/vim-operator-flashy'
map y <Plug>(operator-flashy)
nmap Y <Plug>(operator-flashy)$

Plug 'mopp/vim-operator-convert-case'
nmap <Leader>cl <Plug>(operator-convert-case-lower-camel)
nmap <Leader>cu <Plug>(operator-convert-case-upper-camel)
nmap <Leader>sl <Plug>(operator-convert-case-lower-snake)
nmap <Leader>su <Plug>(operator-convert-case-upper-snake)

Plug 'machakann/vim-sandwich'
let g:sandwich_no_default_key_mappings = 1
let g:operator_sandwich_no_default_key_mappings = 1

nmap <silent> <Leader>sd <Plug>(operator-sandwich-delete)<Plug>(operator-sandwich-release-count)<Plug>(textobj-sandwich-query-a)
nmap <silent> <Leader>sr <Plug>(operator-sandwich-replace)<Plug>(operator-sandwich-release-count)<Plug>(textobj-sandwich-query-a)
nmap <silent> <Leader>sdb <Plug>(operator-sandwich-delete)<Plug>(operator-sandwich-release-count)<Plug>(textobj-sandwich-auto-a)
nmap <silent> <Leader>srb <Plug>(operator-sandwich-replace)<Plug>(operator-sandwich-release-count)<Plug>(textobj-sandwich-auto-a)
nmap <Leader>sa <Plug>(operator-sandwich-add)
xmap <Leader>sa <Plug>(operator-sandwich-add)
omap <Leader>sa <Plug>(operator-sandwich-g@)
xmap <Leader>sd <Plug>(operator-sandwich-delete)
xmap <Leader>sr <Plug>(operator-sandwich-replace)

Plug 'tyru/caw.vim'
let g:caw_operator_keymappings = 1

" text objects & operators }}}

call plug#end()

function! s:is_installed(name)
  return exists('g:plugs') && has_key(g:plugs, a:name) && isdirectory(g:plugs[a:name].dir)
endfunction

if s:is_installed('vim-ambicmd')
  cnoremap <expr> <CR>    ambicmd#expand("\<CR>")
  cnoremap <expr> <Space> ambicmd#expand("\<Space>")
endif

if s:is_installed('deoplete.nvim')
  "call deoplete#custom#source('tabnine', 'rank', 1001)
  call deoplete#custom#source('lsp', 'rank', 1002)
endif

if s:is_installed('denite.nvim')
  call denite#custom#option('default', {'split': 'floating'})

  call denite#custom#filter('matcher/clap', 'clap_path', expand('~/.cache/nvim/vim-plug/vim-clap'))
  call denite#custom#source('_', 'matchers', ['matcher/clap'])
  "call denite#custom#source('line', 'matchers', ['matcher/fuzzy'])

  call denite#custom#var('file/rec', 'command', ['fd', '-H', '-E', '.git', '-t', 'f', '-t', 'l', '.'])

  call denite#custom#var('grep', 'command', ['rg'])
  call denite#custom#var('grep', 'default_opts', ['-i', '--vimgrep'])
  call denite#custom#var('grep', 'recursive_opts', [])
  call denite#custom#var('grep', 'pattern_opt', [])
  call denite#custom#var('grep', 'separator', ['--'])
  call denite#custom#var('grep', 'final_opts', [])

  call denite#custom#alias('source', 'buffer/cd', 'buffer')
  call denite#custom#source('buffer/cd', 'matchers', ['matcher/clap', 'matcher/project_files'])

endif

if s:is_installed('nord-vim')
  colorscheme nord
  hi Comment guifg=#6a7894
endif

if s:is_installed('vim-sandwich')
    let g:sandwich#recipes = deepcopy(g:sandwich#default_recipes)
endif

" vim-plug }}}

" vim:set expandtab shiftwidth=2 softtabstop=2 tabstop=2 foldenable foldmethod=marker:
