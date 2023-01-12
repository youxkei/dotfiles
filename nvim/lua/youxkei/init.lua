local cmd = vim.cmd
local fn = vim.fn
local g = vim.g
local opt = vim.opt
local opt_global = vim.opt_global
local opt_local = vim.opt_local

local cache_dir = fn.stdpath("cache")
if fn.isdirectory(cache_dir) then
  fn.mkdir(cache_dir .. "/backup", "p")
  fn.mkdir(cache_dir .. "/undo", "p")
  fn.mkdir(cache_dir .. "/swap", "p")
end

opt.backupdir = cache_dir .. "/backup"
opt.undodir = cache_dir .. "/undo"
opt.directory = cache_dir .. "/swap"

opt.undofile = true
opt.backup = true
opt.swapfile = true

opt.cindent = true
opt.cinoptions = { "L0", "(2", "U1", "m1" }

opt_global.expandtab = true
opt_global.smarttab = true
opt_global.shiftwidth = 4
opt_global.tabstop = 4
opt_global.softtabstop = 4

opt.fileencodings = { "ucs-bom", "utf-8", "sjis", "cp932", "euc-jp" }
opt.fileformats = { "unix", "dos", "mac" }

opt.showmatch = true
opt.matchtime = 1

opt.cursorline = true
opt.cursorcolumn = true

opt.scrolloff = 16
opt.sidescroll = 1

opt.list = true
opt.listchars = { tab = "･･", trail = "-", nbsp = "%" }

opt.termguicolors = true
opt.ambiwidth = "single"
opt.cmdheight = 0
opt.hidden = true
opt.number = true
opt.wrap = false
opt.endofline = true
opt.hlsearch = true
opt.digraph = false
opt.showcmd = true
opt.showtabline = 2
opt.backspace = { "indent", "eol", "start" }
opt.laststatus = 3
opt.wildmenu = true
opt.signcolumn = "yes"
opt.completeopt = { "menuone", "noselect" }
opt.modeline = true
opt.inccommand = "nosplit"
opt.autoread = true
opt.scrollback = 2000
opt.synmaxcol = 512
opt.updatetime = 100
opt.iskeyword = { "@", "48-57", "_", "192-255", "$", "@-@", "-" }
opt.clipboard = "unnamedplus"
opt.joinspaces = false
opt.sessionoptions = {
  "blank", "buffers", "curdir", "folds", "help", "tabpages", "winsize", "winpos", "terminal", "globals"
}

g.mapleader = ","

if fn.executable("win32yank.exe") then
  g.clipboard = {
    name = "myClipboard",
    copy = {
      ["+"] = "win32yank.exe -i --crlf",
      ["*"] = "win32yank.exe -i --crlf",
    },
    paste = {
      ["+"] = "win32yank.exe -o --lf",
      ["*"] = "win32yank.exe -o --lf",
    },
    cache_enabled = 1,
  }
end

local augroup = vim.api.nvim_create_augroup("youxkei", {})
vim.api.nvim_create_autocmd("BufWritePost", {
  group = augroup,
  pattern = "init.lua",
  callback = function()
    cmd("luafile " .. fn.stdpath("config") .. "/lua/youxkei/init.lua")
  end,
})
vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = { "rescript", "lua", "nix", "javascript", "ocaml", "text", "typescript", "typescriptreact" },
  callback = function()
    opt_local.shiftwidth = 2
    opt_local.tabstop = 2
    opt_local.softtabstop = 2
  end,
})
vim.api.nvim_create_autocmd("TermOpen", {
  group = augroup,
  pattern = "*",
  callback = function()
    vim.opt_local.scrollback = -1
  end,
})

vim.keymap.set("n", "j", "gj")
vim.keymap.set("n", "k", "gk")
vim.keymap.set("n", "gj", "j")
vim.keymap.set("n", "gk", "k")

vim.keymap.set("n", "<leader>w", "<cmd>w<cr>")
vim.keymap.set("n", "q", "<nop>")
vim.keymap.set("n", "Q", "q")
vim.keymap.set("n", "i", [[empty(getline(".")) ? "cc" : "i"]], { expr = true })
vim.keymap.set("n", "a", [[empty(getline(".")) ? "cc" : "a"]], { expr = true })
vim.keymap.set("n", "<c-j>", "<cmd>cnext<cr>")
vim.keymap.set("n", "<c-k>", "<cmd>cabove<cr>")
vim.keymap.set("t", "<c-v>", [[<c-\><c-n>pi]])
