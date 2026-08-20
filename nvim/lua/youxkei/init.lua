local fn = vim.fn
local g = vim.g
local opt = vim.opt
local opt_global = vim.opt_global
local opt_local = vim.opt_local

local cache_dir = fn.stdpath("cache")
-- mkdir with "p" is a no-op if the dir exists and creates cache_dir itself when
-- missing, so no isdirectory guard is needed (and fn.isdirectory returns 0/1,
-- both truthy in Lua, so the old guard was always taken anyway).
fn.mkdir(cache_dir .. "/backup", "p")
fn.mkdir(cache_dir .. "/undo", "p")
fn.mkdir(cache_dir .. "/swap", "p")

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

opt.cmdheight = 0
opt.showcmd = true
opt.showcmdloc = "statusline"

opt.ignorecase = true
opt.smartcase = true

opt.termguicolors = true
opt.background = "dark"
opt.ambiwidth = "single"
opt.hidden = true
opt.number = true
opt.wrap = false
opt.endofline = true
opt.hlsearch = true
opt.digraph = false
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

-- Under WSLg the Windows clipboard is bridged to Wayland, so wl-paste returns
-- CRLF line endings when text was copied from a Windows app. nvim splits on \n
-- and leaves a trailing \r on every line, which pastes as doubled newlines (^M).
-- Keep the fast wl-clipboard path but strip \r on paste.
if (vim.env.WAYLAND_DISPLAY or "") ~= "" and fn.executable("wl-copy") == 1 and fn.executable("wl-paste") == 1 then
  g.clipboard = {
    name = "wl-clipboard-strip-cr",
    copy = {
      ["+"] = { "wl-copy", "--type", "text/plain" },
      ["*"] = { "wl-copy", "--primary", "--type", "text/plain" },
    },
    paste = {
      ["+"] = { "sh", "-c", "wl-paste --no-newline | tr -d '\\r'" },
      ["*"] = { "sh", "-c", "wl-paste --no-newline --primary | tr -d '\\r'" },
    },
  }
end
opt.joinspaces = false
opt.sessionoptions = {
  "blank", "buffers", "curdir", "help", "tabpages", "winsize", "winpos", "terminal", "globals"
}

-- Smart terminal paste for the Claude Code TUI. When the OS clipboard holds an
-- image, forward a literal Ctrl-V (0x16) to the terminal job so the TUI reads the image
-- from the clipboard itself; otherwise fall back to the normal register paste (text).
-- Bound to <c-v> by default; macOS is the exception, where Cmd+V (<D-v>) takes the role so
-- <c-v> stays a plain text paste. Image detection: macOS via `osascript -e 'clipboard info'`
-- (a screenshot / copied image puts a PNGf class on the pasteboard); Wayland via
-- `wl-paste --list-types` (image/* MIME type).
local function clipboard_has_image()
  if fn.has("mac") == 1 then
    return fn.system({ "osascript", "-e", "clipboard info" }):find("PNGf", 1, true) ~= nil
  elseif (vim.env.WAYLAND_DISPLAY or "") ~= "" and fn.executable("wl-paste") == 1 then
    return fn.system({ "wl-paste", "--list-types" }):find("image/", 1, true) ~= nil
  end
  return false
end

-- WSLg bridges a copied Windows image to the Wayland clipboard only as image/bmp encoded with
-- BI_BITFIELDS compression. Claude Code fetches those bytes (its read chain includes
-- `wl-paste --type image/bmp`) but the bundled libvips silently fails to decode that BMP
-- variant, so the paste yields nothing. ImageMagick decodes it, so re-encode the clipboard
-- image to PNG -- which the TUI decodes fine -- before forwarding Ctrl-V. Skipped when a PNG is
-- already offered, so native Wayland apps (which put image/png on the clipboard) are untouched.
local function normalize_clipboard_image_to_png()
  if (vim.env.WAYLAND_DISPLAY or "") == "" or fn.executable("wl-copy") == 0 or fn.executable("magick") == 0 then
    return
  end
  if fn.system({ "wl-paste", "--list-types" }):find("image/png", 1, true) ~= nil then
    return
  end
  fn.system({ "sh", "-c",
    [[t=$(wl-paste --list-types | grep -m1 "^image/") && wl-paste --type "$t" | magick - png:- | wl-copy --type image/png]] })
end

local function smart_terminal_paste()
  local job = vim.b.terminal_job_id
  if job and clipboard_has_image() then
    normalize_clipboard_image_to_png()
    vim.api.nvim_chan_send(job, "\22") -- 0x16 = Ctrl-V; the TUI then pastes the clipboard image
  else
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<c-\\><c-n>pi", true, false, true), "n", false)
  end
end

if g.neovide then
  opt.guifont = "Moralerspace Krypton:h12"
  g.neovide_theme = "dark"

  -- Neovide forwards Cmd (sent by Karabiner from Home/End) as <D-...>, which has
  -- no default mapping; wire Cmd+Left/Right to start/end of line. Terminal nvim
  -- never sees these keys (the terminal emulator handles Cmd), hence neovide-only.
  for _, mode in ipairs { "n", "x", "i", "c" } do
    vim.keymap.set(mode, "<D-Left>", "<Home>")
    vim.keymap.set(mode, "<D-Right>", "<End>")
  end
  -- In :terminal the keys reach the shell, not Neovim. zsh runs the emacs keymap
  -- (bindkey -e) but does not bind Home/End, so send readline's beginning/end-of-line.
  vim.keymap.set("t", "<D-Left>", "<c-a>")
  vim.keymap.set("t", "<D-Right>", "<c-e>")

  -- Cmd+V smart-pastes into a terminal (Claude Code): image on the clipboard is
  -- forwarded to the TUI, text falls back to the register paste. <c-v> stays plain text
  -- paste on macOS (see below); Cmd+V is the macOS-native key, so it takes the image role.
  vim.keymap.set("t", "<D-v>", smart_terminal_paste, { desc = "Smart terminal paste (image or text)" })
end

g.mapleader = ","

local augroup = vim.api.nvim_create_augroup("youxkei", { clear = true })
vim.api.nvim_create_autocmd("BufWritePost", {
  group = augroup,
  pattern = "init.lua",
  callback = function()
    vim.cmd.luafile(fn.stdpath("config") .. "/lua/youxkei/init.lua")
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
if fn.has("mac") == 1 then
  -- macOS is the special case: it has a Cmd key, so Cmd+V (<D-v>, wired in the neovide
  -- block) is the smart-paste key and <c-v> stays a plain register (text) paste.
  vim.keymap.set("t", "<c-v>", [[<c-\><c-n>pi]])
else
  -- Everywhere else (WSLg/Wayland, Linux) has no Cmd key, so <c-v> is the smart-paste key:
  -- image on the clipboard is forwarded to the terminal TUI, text falls back to register paste.
  vim.keymap.set("t", "<c-v>", smart_terminal_paste, { desc = "Smart terminal paste (image or text)" })
end
