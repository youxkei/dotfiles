local cmd = vim.cmd
local fn = vim.fn
local g = vim.g
local opt = vim.opt

local cache_dir = fn.stdpath("cache")
if fn.isdirectory(cache_dir) then
  fn.mkdir(cache_dir .. "/backup", "p")
  fn.mkdir(cache_dir .. "/undo", "p")
  fn.mkdir(cache_dir .. "/swap", "p")
end

opt.termguicolors = true

opt.backupdir = cache_dir .. "/backup"
opt.undodir = cache_dir .. "/undo"
opt.directory = cache_dir .. "/swap"

opt.undofile = true
opt.backup = true
opt.swapfile = true

opt.cindent = true
opt.cinoptions = {"L0", "(2", "U1", "m1"}

opt.expandtab = true
opt.smarttab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.softtabstop = 4

opt.fileencodings = {"ucs-bom", "utf-8", "sjis", "cp932", "euc-jp"}
opt.fileformats = {"unix", "dos", "mac"}

opt.foldenable = false
opt.foldmethod = "indent"

opt.showmatch = true
opt.matchtime = 1

opt.cursorline = true
opt.cursorcolumn = true

opt.scrolloff = 16
opt.sidescroll = 1

opt.list = true
opt.listchars = {tab = "| ", trail = "-", nbsp = "%"}

opt.ambiwidth = "single"
opt.cmdheight = 2
opt.hidden = true
opt.number = true
opt.wrap = false
opt.endofline = true
opt.hlsearch = true
opt.digraph = false
opt.showcmd = true
opt.showtabline = 2
opt.backspace = {"indent", "eol", "start"}
opt.laststatus = 2
opt.wildmenu = true
opt.signcolumn = "yes"
opt.completeopt = {"menuone", "noselect"}
opt.modeline = true
opt.inccommand = "nosplit"
opt.autoread = true
opt.scrollback = 2000
opt.synmaxcol = 512
opt.updatetime = 100
opt.iskeyword = {"@", "48-57", "_", "192-255", "$", "@-@", "-"}
opt.clipboard = "unnamedplus"
opt.joinspaces = false

g.mapleader = ","

local packer_dir = fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"

if fn.empty(fn.glob(packer_dir)) > 0 then
  fn.system({"git", "clone", "https://github.com/wbthomason/packer.nvim", packer_dir})
  cmd("packadd packer.nvim")
end

require("packer").startup(function(use)
  use("wbthomason/packer.nvim")

  use{"tjdevries/astronauta.nvim", config = function()
    local keymap = require("astronauta.keymap")

    keymap.nnoremap{"j", "gj"}
    keymap.nnoremap{"k", "gk"}
    keymap.nnoremap{"gj", "j"}
    keymap.nnoremap{"gk", "k"}

    for i = 1, 9 do
      local lhs = "<c-b>" .. i
      local rhs = "<esc>" .. i .. "gt"

      if i == 9 then
        rhs = "<esc><cmd>tablast<cr>"
      end

      keymap.noremap{lhs, rhs, silent = true}
      keymap.inoremap{lhs, rhs, silent = true}
    end

    keymap.nnoremap{"<leader>w", "<cmd>w<cr>", silent = true}
    keymap.nnoremap{"Q", "<nop>"}
    keymap.nnoremap{"i", "empty(getline('.')) ? 'cc' : 'i'", expr = true}
    keymap.nnoremap{"a", "empty(getline('.')) ? 'cc' : 'a'", expr = true}
  end}

  use{"thinca/vim-ambicmd", config = function()
    local keymap = require("astronauta.keymap")

    keymap.cnoremap{"<cr>", "ambicmd#expand('<cr>')", expr = true}
    keymap.cnoremap{"<space>", "ambicmd#expand('<space>')", expr = true}
  end}

  use{"Shougo/denite.nvim", config = function()
    local keymap = require("astronauta.keymap")

    keymap.nnoremap{"<leader>ed", "<cmd>Denite directory_mru<cr>", silent = true}
    vim.fn["denite#custom#option"]("default", {split = "floating"})
  end}

  use{"itchyny/lightline.vim", config = function()
    vim.g.lightline = {
      colorscheme = "nord",
      active = {
        left = {
          {"cwd", "mode", "paste"},
          {"readonly", "relativepath", "modified"},
        },
      },
      tab = {
        active = {"tabnum", "cwd"},
        inactive = {"tabnum", "cwd"},
      },
      component = {
        readonly = "%{&readonly?'⌬':''}",
      },

      tab_component_function = {
        cwd = "LightlineCWD",
      },
      separator = {left = "", right = ""},
      subseparator = {left = "", right = ""},
    }

    vim.cmd[[
      function! LightlineCWD(n) abort
        let cwd = gettabvar(a:n, 'cwd')
        return fnamemodify(empty(cwd) ? getcwd() : cwd, ":t")
      endfunction
    ]]
  end}

  use{"LeafCage/yankround.vim", config = function()
    local keymap = require("astronauta.keymap")

    vim.g.yankround_dir = vim.fn.stdpath("cache") .. "/yankround"
    vim.g.yankround_max_history = 100

    keymap.nmap{"p", "<plug>(yankround-p)"}
    keymap.xmap{"p", "<plug>(yankround-p)"}
    keymap.nmap{"P", "<plug>(yankround-P)"}
    keymap.nmap{"gp", "<plug>(yankround-gp)"}
    keymap.xmap{"gp", "<plug>(yankround-gp)"}
    keymap.nmap{"gP", "<plug>(yankround-gP)"}
    keymap.nmap{"<C-p>", "<plug>(yankround-prev)"}
    keymap.nmap{"<C-n>", "<plug>(yankround-next)"}
  end}

  use{"kana/vim-niceblock"}

  use{"tpope/vim-repeat"}

  use{"junegunn/vim-easy-align", config = function()
    local keymap = require("astronauta.keymap")

    keymap.vmap{"<enter>", "<plug>(EasyAlign)"}
  end}

  use{"mbbill/undotree", config = function()
    vim.g.undotree_WindowLayout = 3
  end}

  use{"glepnir/indent-guides.nvim", config = function()
    require("indent_guides").setup{}
  end}

  use{"rhysd/committia.vim"}

  use{"kana/vim-tabpagecd"}

  use {"lewis6991/gitsigns.nvim", requires = "nvim-lua/plenary.nvim", config = function()
    require("gitsigns").setup()
  end}
end)

-- vim:set expandtab shiftwidth=2 softtabstop=2 tabstop=2:
