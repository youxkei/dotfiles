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

opt.foldenable = false
opt.foldmethod = "indent"

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
opt.cmdheight = 2
opt.hidden = true
opt.number = true
opt.wrap = false
opt.endofline = true
opt.hlsearch = true
opt.digraph = false
opt.showcmd = true
opt.showtabline = 2
opt.backspace = { "indent", "eol", "start" }
opt.laststatus = 2
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
opt.timeout = false

g.mapleader = ","

local augroup = vim.api.nvim_create_augroup("youxkei", {})
vim.api.nvim_create_autocmd("BufWritePost", { group = augroup,
  pattern = "init.lua",
  callback = function()
    cmd("luafile " .. fn.stdpath("config") .. "/init.lua")
    require("packer").compile()
  end,
})
vim.api.nvim_create_autocmd("FileType", { group = augroup,
  pattern = { "rescript", "lua", "nix", "javascript", "ocaml", "text" },
  callback = function()
    opt_local.shiftwidth = 2
    opt_local.tabstop = 2
    opt_local.softtabstop = 2
  end,
})

vim.keymap.set("n", "j", "gj")
vim.keymap.set("n", "k", "gk")
vim.keymap.set("n", "gj", "j")
vim.keymap.set("n", "gk", "k")

for i = 1, 9 do
  local lhs = "<c-b>" .. i
  local rhs = "<esc>" .. i .. "gt"

  if i == 9 then
    rhs = "<esc><cmd>tablast<cr>"
  end

  vim.keymap.set("n", lhs, rhs, { silent = true })
  vim.keymap.set("i", lhs, rhs, { silent = true })
end

vim.keymap.set("n", "<leader>w", "<cmd>w<cr>", { silent = true })
vim.keymap.set("n", "Q", "<nop>")
vim.keymap.set("n", "i", "empty(getline('.')) ? 'cc' : 'i'", { expr = true })
vim.keymap.set("n", "a", "empty(getline('.')) ? 'cc' : 'a'", { expr = true })
vim.keymap.set("n", "<c-j>", "<cmd>cnext<cr>", { silent = true })
vim.keymap.set("n", "<c-k>", "<cmd>cabove<cr>", { silent = true })
vim.keymap.set("t", "<c-v>", [[<c-\><c-n>pi]], { silent = true })

function Youxkei_toggleterm()
  local id = vim.t.youxkei_toggleterm_id

  if not vim.t.youxkei_toggleterm_id then
    id = Youxkei_next_toggleterm_unique_id or 1
    Youxkei_next_toggleterm_unique_id = id + 1

    vim.t.youxkei_toggleterm_id = id
  end

  require("toggleterm").toggle(id)
end

vim.keymap.set("v", "<leader>g", function()
  local Job = require("plenary.job")

  local full_path = vim.fn.expand("%:p")
  local mode = vim.api.nvim_get_mode().mode
  local startline = nil
  local endline = nil

  if mode == "v" or mode == "V" or mode == "" then
    startline = vim.fn.line("v")
    endline = vim.fn.line(".")

    if startline > endline then
      startline, endline = endline, startline
    end
  end

  Job:new {
    command = "git",
    args = { "rev-parse", "HEAD" },
    enabled_recording = true,
    on_exit = function(job)
      local ref = job:result()[1]

      Job:new {
        command = "git",
        args = { "ls-remote", "--get-url", "origin" },
        enabled_recording = true,
        on_exit = function(job)
          local url_head = "https://github.com/" .. job:result()[1]:match("^git@github.com:(.*).git$")

          Job:new {
            command = "git",
            args = { "rev-parse", "--show-toplevel" },
            enabled_recording = true,
            on_exit = function(job)
              local git_root = job:result()[1]
              local path = full_path:sub(#git_root + 2)
              local url = url_head .. "/blob/" .. ref .. "/" .. path

              if startline then
                if startline == endline then
                  url = url .. "#L" .. startline
                else
                  url = url .. "#L" .. startline .. "-L" .. endline
                end
              end

              vim.schedule(function()
                vim.fn.setreg("+", url)
                print("GitHub URL: " .. url)
              end)
            end,
          }:start()
        end,
      }:start()
    end,
  }:start()
end)

local install_path = fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'
local packer_bootstrap = false
if fn.empty(fn.glob(install_path)) > 0 then
  vim.o.runtimepath = fn.stdpath('data') .. '/site/pack/*/start/*,' .. vim.o.runtimepath
  packer_bootstrap = fn.system({ 'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path })
end

require("packer").startup {
  function(use)
    use("wbthomason/packer.nvim")

    use("nvim-lua/plenary.nvim")

    use { "christianchiarulli/nvcode-color-schemes.vim", after = "indent-blankline.nvim", config = function()
      vim.cmd [[colorscheme nord]]
    end }

    use { "thinca/vim-ambicmd", config = function()
      vim.keymap.set("c", "<cr>", "ambicmd#expand('<cr>')", { expr = true })
      vim.keymap.set("c", "<space>", "ambicmd#expand('<space>')", { expr = true })
    end }

    use { "itchyny/lightline.vim", config = function()
      vim.g.lightline = {
        colorscheme = "nord",
        active = {
          left = {
            { "cwd", "mode", "paste" },
            { "readonly", "relativepath", "modified" },
          },
        },
        tab = {
          active = { "tabnum", "cwd" },
          inactive = { "tabnum", "cwd" },
        },
        component = {
          readonly = "%{&readonly?'⌬':''}",
        },
        tab_component_function = {
          cwd = "LightlineCWD",
        },
        separator = { left = "\u{e0b4}", right = "\u{e0b6}" },
        subseparator = { left = "\u{e0b5}", right = "\u{e0b7}" },
      }

      vim.cmd [[
        function! LightlineCWD(n) abort
          let cwd = gettabvar(a:n, 'cwd')
          return fnamemodify(empty(cwd) ? getcwd() : cwd, ':t')
        endfunction
      ]]
    end }

    use { "previm/previm" }

    use { "LeafCage/yankround.vim", config = function()
      vim.g.yankround_dir = vim.fn.stdpath("cache") .. "/yankround"
      vim.g.yankround_max_history = 100

      vim.keymap.set({ "n", "x" }, "p", "<plug>(yankround-p)", { remap = true })
      vim.keymap.set("n", "P", "<plug>(yankround-P)", { remap = true })
      vim.keymap.set({ "n", "x" }, "gp", "<plug>(yankround-gp)", { remap = true })
      vim.keymap.set("n", "gP", "<plug>(yankround-gP)", { remap = true })
      vim.keymap.set("n", "<C-p>", "<plug>(yankround-prev)", { remap = true })
      vim.keymap.set("n", "<C-n>", "<plug>(yankround-next)", { remap = true })
    end }

    use { "kana/vim-niceblock" }

    use { "tpope/vim-repeat" }

    use { "junegunn/vim-easy-align", config = function()
      vim.keymap.set("v", "<enter>", "<plug>(EasyAlign)", { remap = true })
    end }

    use { "mbbill/undotree", config = function()
      vim.g.undotree_WindowLayout = 3
    end }

    use { "rhysd/committia.vim" }

    use { "kana/vim-tabpagecd" }

    use { "w0rp/ale", disable = true, config = function()
      vim.g.ale_lint_on_save = 0
      vim.g.ale_lint_on_text_changed = 0
      vim.g.ale_fix_on_save = 1

      vim.g.ale_fixers = {
        -- ["*"] = {"remove_trailing_lines", "trim_whitespace"},
        ["*"] = { "remove_trailing_lines" },
      }
    end }

    use { "machakann/vim-swap", config = function()
      vim.g.swap_no_default_key_mappings = true

      vim.keymap.set("n", "gs", "<plug>(swap-interactive)", { remap = true })
      vim.keymap.set({ "o", "x" }, "i,", "<plug>(swap-textobject-i)", { remap = true })
      vim.keymap.set({ "o", "x" }, "a,", "<plug>(swap-textobject-a)", { remap = true })
    end }

    use { "lambdalisue/suda.vim" }

    use { "sgur/vim-editorconfig" }

    use { "prakashdanish/vim-githubinator" }

    use { "lambdalisue/vim-manpager", opt = true, cmd = "MANPAGER" }

    use { "haya14busa/vim-asterisk", config = function()
      vim.keymap.set({ "n", "v" }, "*", "<plug>(asterisk-z*)<cmd>lua require('hlslens').start()<cr>", { remap = true })
      vim.keymap.set({ "n", "v" }, "#", "<plug>(asterisk-z#)<cmd>lua require('hlslens').start()<cr>", { remap = true })
      vim.keymap.set({ "n", "v" }, "g*", "<plug>(asterisk-gz*)<cmd>lua require('hlslens').start()<cr>", { remap = true })
      vim.keymap.set({ "n", "v" }, "g#", "<plug>(asterisk-gz#)<cmd>lua require('hlslens').start()<cr>", { remap = true })
    end }

    use { "chaoren/vim-wordmotion", config = function()
      vim.g.wordmotion_spaces = "_-."
      vim.g.wordmotion_mappings = {
        W = "",
        B = "",
        E = "",
        GE = "",
        aW = "",
        iW = "",
      }

      vim.keymap.set("n", "W", "w")
      vim.keymap.set("n", "B", "b")
      vim.keymap.set("n", "E", "e")
      vim.keymap.set("n", "gE", "ge")

      vim.keymap.set({ "o", "x" }, "W", "w")
      vim.keymap.set({ "o", "x" }, "B", "b")
      vim.keymap.set({ "o", "x" }, "E", "e")
      vim.keymap.set({ "o", "x" }, "GE", "ge")
      vim.keymap.set({ "o", "x" }, "iW", "iw")
      vim.keymap.set({ "o", "x" }, "aW", "aw")
    end }

    use { "inkarkat/vim-mark", requires = "inkarkat/vim-ingo-library", config = function()
      vim.g.mw_no_mappings = 1
      vim.g.mwDefaultHighlightingPalette = 'maximum'

      vim.keymap.set({ "n", "v" }, "<leader>m", "<plug>MarkSet", { remap = true })
      vim.keymap.set("n", "<leader>n", "<plug>MarkAllClear", { remap = true })
    end }

    use {
      "nvim-treesitter/nvim-treesitter",
      run = ":TSUpdate",
      requires = {
        "p00f/nvim-ts-rainbow",
        "nvim-treesitter/nvim-treesitter-textobjects",
      },
      config = function()
        require("nvim-treesitter.configs").setup {
          ensure_installed = {
            "bash",
            "comment",
            "dockerfile",
            "go",
            "gomod",
            "html",
            "javascript",
            "json",
            "lua",
            "nix",
            "rust",
            "toml",
            "tsx",
            "typescript",
            "yaml",
          },
          highlight = {
            enable = true,
          },
          indent = {
            enable = true
          },
          rainbow = {
            enable = true,
            extended_mode = true,
            max_file_lines = 1000,
          },
          textobjects = {
            move = {
              enable = true,
              set_jumps = true,
              goto_next_start = {
                ["]m"] = "@function.outer",
              },
              goto_next_end = {
                ["]M"] = "@function.outer",
              },
              goto_previous_start = {
                ["[m"] = "@function.outer",
              },
              goto_previous_end = {
                ["[M"] = "@function.outer",
              },
            },
          }, }

        vim.api.nvim_create_autocmd("FileType", { group = "youxkei",
          pattern = { "sh", "dockerfile", "go", "html", "javascript", "json", "lua", "nix", "rust", "toml", "typescriptreact", "typescript", "yaml" },
          callback = function()
            vim.opt_local.foldmethod = "expr"
            vim.opt_local.foldexpr = "nvim_treesitter#foldexpr()"
          end,
        })
      end,
    }

    use { "romgrk/nvim-treesitter-context", config = function()
      require("treesitter-context").setup {
        enable = true,
      }
    end }

    use {
      "neovim/nvim-lspconfig",
      requires = {
        "hrsh7th/cmp-nvim-lsp",
        "amiralies/vim-rescript",
      },
      config = function()
        local lspconfig = require("lspconfig")

        local capabilities = vim.lsp.protocol.make_client_capabilities()
        capabilities = require("cmp_nvim_lsp").update_capabilities(capabilities)

        lspconfig.gopls.setup {
          capabilities = capabilities,
        }

        lspconfig.rescriptls.setup {
          capabilities = capabilities,
          cmd = { "node", vim.fn.stdpath("data") .. "/site/pack/packer/start/vim-rescript/server/out/server.js", "--stdio" }
        }

        lspconfig.tsserver.setup {
          capabilities = capabilities,
        }

        lspconfig.sumneko_lua.setup {
          capabilities = capabilities,
          cmd = { "lua-language-server" },
          settings = {
            Lua = {
              diagnostics = {
                globals = { 'vim' }
              }
            }
          }
        }

        lspconfig.ocamllsp.setup {
          capabilities = capabilities,
        }

        vim.keymap.set("n", "<leader>ln", "<cmd>lua vim.lsp.buf.rename()<cr>", { silent = true })
        vim.keymap.set("n", "<leader>ld", "<cmd>lua vim.lsp.buf.definition()<cr>", { silent = true })

        vim.api.nvim_create_autocmd("BufWritePre", { group = "youxkei",
          pattern = { "*.go", "*.res", "*.js", "*.lua", "*.ml" },
          callback = function()
            vim.lsp.buf.formatting_sync(nil, 1000)
          end,
        })
      end,
    }

    use {
      "nvim-telescope/telescope.nvim",
      requires = {
        "nvim-lua/popup.nvim",
        "nvim-lua/plenary.nvim",
        "nvim-telescope/telescope-project.nvim",
        "nvim-telescope/telescope-file-browser.nvim",
      },
      config = function()
        local telescope = require("telescope")

        telescope.load_extension("project")
        telescope.load_extension("file_browser")

        telescope.setup {}

        local builtin = require("telescope.builtin")
        local project = function()
          telescope.extensions.project.project {
            attach_mappings = function(prompt_bufnr)
              require("telescope.actions").select_default:replace(function()
                require("telescope._extensions.project.actions").change_working_directory(prompt_bufnr)
              end)

              return true
            end
          }
        end

        vim.keymap.set("n", "<leader>tf", builtin.find_files)
        vim.keymap.set("n", "<leader>tF", function() builtin.find_files { hidden = true } end)
        vim.keymap.set("n", "<leader>tg", builtin.live_grep)
        vim.keymap.set("n", "<leader>tb", builtin.buffers)
        vim.keymap.set("n", "<leader>tp", project)
        vim.keymap.set("n", "<leader>te", telescope.extensions.file_browser.file_browser)
        vim.keymap.set("n", "<leader>tr", builtin.resume)
        vim.keymap.set("n", "<leader>lr", builtin.lsp_references)
        vim.keymap.set("n", "<leader>li", builtin.lsp_implementations)
        vim.keymap.set("n", "<leader>ls", builtin.lsp_document_symbols)
        vim.keymap.set("n", "<leader>le", builtin.diagnostics)
      end
    }

    use { "phaazon/hop.nvim", config = function()
      local hop = require("hop")

      hop.setup {
        keys = "etonaspgyfcrlkmxbjwqvuhid",
        jump_on_sole_occurrence = false,
      }

      vim.keymap.set("n", "s", hop.hint_char1)
    end }

    use { "lewis6991/gitsigns.nvim", requires = "nvim-lua/plenary.nvim", config = function()
      require("gitsigns").setup()
    end }

    use { 'kevinhwang91/nvim-hlslens', config = function()
      require("hlslens").setup({
        calm_down = true,
      })

      vim.keymap.set("n", "n", "<cmd>execute('normal! ' . v:count1 . 'n')<cr><cmd>lua require('hlslens').start()<cr>", { silent = true })
      vim.keymap.set("n", "N", "<cmd>execute('normal! ' . v:count1 . 'N')<cr><cmd>lua require('hlslens').start()<cr>", { silent = true })
      vim.keymap.set("n", "*", "*<cmd>lua require('hlslens').start()<cr>")
      vim.keymap.set("n", "#", "#<cmd>lua require('hlslens').start()<cr>")
      vim.keymap.set("n", "g*", "g*<cmd>lua require('hlslens').start()<cr>")
      vim.keymap.set("n", "g#", "g#<cmd>lua require('hlslens').start()<cr>")
    end }

    use { "lukas-reineke/indent-blankline.nvim", config = function()
      require("indent_blankline").setup {
        char = "│",
        char_highlight_list = { "Indent1", "Indent2", "Indent3", "Indent4", "Indent5" },
        buftype_exclude = { "terminal" }
      }

      vim.api.nvim_create_autocmd("ColorScheme", { group = "youxkei",
        pattern = "*",
        callback = function()
          vim.cmd [[
            highlight Indent1 guifg=#BF616A guibg=none gui=nocombine
            highlight Indent2 guifg=#D08770 guibg=none gui=nocombine
            highlight Indent3 guifg=#EBCB8B guibg=none gui=nocombine
            highlight Indent4 guifg=#A3BE8C guibg=none gui=nocombine
            highlight Indent5 guifg=#B48EAD guibg=none gui=nocombine
            highlight IndentBlanklineSpaceChar guifg=white guibg=none gui=nocombine
            highlight IndentBlanklineSpaceCharBlankline guifg=white guibg=none gui=nocombine
          ]]
        end,
      })
    end }

    use { "akinsho/toggleterm.nvim", config = function()
      require("toggleterm").setup {
        open_mapping = "<c-t>",
        direction = "float",
        float_opts = {
          border = "double",
        },
      }

      vim.keymap.set("n", "<c-t>", Youxkei_toggleterm, { silent = true })
    end }

    use { "karb94/neoscroll.nvim", config = function()
      require("neoscroll").setup({
        mappings = { "<C-u>", "<C-d>" },
      })
    end }

    use { "github/copilot.vim" }

    use { "VonHeikemen/fine-cmdline.nvim", disable = true, requires = "MunifTanjim/nui.nvim", config = function() -- disabled because it doesn't work with cmp-cmdline
      vim.keymap.set("n", ":", require("fine-cmdline").open)
    end }

    use {
      "hrsh7th/nvim-cmp",
      requires = {
        "L3MON4D3/LuaSnip",
        "saadparwaiz1/cmp_luasnip",
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-path",
        "hrsh7th/cmp-buffer",
        "octaltree/cmp-look",
        "hrsh7th/cmp-cmdline",
      },
      config = function()
        local cmp = require("cmp")
        cmp.setup {
          snippet = {
            expand = function(args)
              require("luasnip").lsp_expand(args.body)
            end
          },
          sources = cmp.config.sources({
            { name = "nvim_lsp" },
            { name = "luasnip" },
            { name = "path" },
            { name = "buffer" },
            { name = "look" },
          }),
          preselect = cmp.PreselectMode.None,
        }

        cmp.setup.cmdline(":", {
          sources = {
            { name = "cmdline" },
          },
        })
      end }

    use { "folke/trouble.nvim", config = function()
      local trouble = require("trouble")
      trouble.setup {}

      vim.keymap.set("n", "<leader>r", trouble.open)
    end }

    use { "ellisonleao/glow.nvim" }

    use { "hoschi/yode-nvim", requires = "nvim-lua/plenary.nvim", config = function()
      require('yode-nvim').setup({})

      vim.keymap.set("v", "<leader>yc", ":YodeCreateSeditorFloating<cr>")
    end }


    -- languages, text objects, operators

    use { "amiralies/vim-rescript" }

    use { "sgur/vim-textobj-parameter", requires = "kana/vim-textobj-user" }

    use { "kana/vim-textobj-entire", requires = "kana/vim-textobj-user" }

    use { "kana/vim-operator-replace", requires = "kana/vim-operator-user", config = function()
      vim.keymap.set({ "n", "v" }, "_", "<plug>(operator-replace)")
    end }

    use { "haya14busa/vim-operator-flashy", config = function()
      vim.keymap.set({ "n", "v" }, "y", "<plug>(operator-flashy)", { remap = true })
      vim.keymap.set("n", "Y", "<plug>(operator-flashy)$", { remap = true })
    end }

    use { "machakann/vim-sandwich", config = function()
      vim.g.sandwich_no_default_key_mappings = true
      vim.g.operator_sandwich_no_default_key_mappings = true
      vim.g["sandwich#recipes"] = vim.g["sandwich#default_recipes"]

      vim.keymap.set("n", "<leader>sd", "<plug>(operator-sandwich-delete)<plug>(operator-sandwich-release-count)<plug>(textobj-sandwich-query-a)", { remap = true })
      vim.keymap.set("n", "<leader>sr", "<plug>(operator-sandwich-replace)<plug>(operator-sandwich-release-count)<plug>(textobj-sandwich-query-a)", { remap = true })
      vim.keymap.set("n", "<leader>sdb", "<plug>(operator-sandwich-delete)<plug>(operator-sandwich-release-count)<plug>(textobj-sandwich-auto-a)", { remap = true })
      vim.keymap.set("n", "<leader>srb", "<plug>(operator-sandwich-replace)<plug>(operator-sandwich-release-count)<plug>(textobj-sandwich-auto-a)", { remap = true })
      vim.keymap.set("n", "<leader>sa", "<plug>(operator-sandwich-add)")

      vim.keymap.set("x", "<leader>sa", "<plug>(operator-sandwich-add)", { remap = true })
      vim.keymap.set("o", "<leader>sa", "<plug>(operator-sandwich-g@)", { remap = true })
      vim.keymap.set("x", "<leader>sd", "<plug>(operator-sandwich-delete)", { remap = true })
      vim.keymap.set("x", "<leader>sr", "<plug>(operator-sandwich-replace)", { remap = true })
    end }

    use { "b3nj5m1n/kommentary", config = function()
      vim.g.kommentary_create_default_mappings = false

      vim.keymap.set("n", "<leader>cic", "<plug>kommentary_line_increase", { remap = true })
      vim.keymap.set("n", "<leader>ci", "<plug>kommentary_motion_increase", { remap = true })
      vim.keymap.set("x", "<leader>ci", "<plug>kommentary_visual_increase", { remap = true })
      vim.keymap.set("n", "<leader>cdc", "<plug>kommentary_line_decrease", { remap = true })
      vim.keymap.set("n", "<leader>cd", "<plug>kommentary_motion_decrease", { remap = true })
      vim.keymap.set("x", "<leader>cd", "<plug>kommentary_visual_decrease", { remap = true })
    end }

    if packer_bootstrap then
      require('packer').sync()
    end
  end
}
