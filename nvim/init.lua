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
opt.timeout = false
opt.sessionoptions = {
  "blank", "buffers", "curdir", "folds", "help", "tabpages", "winsize", "winpos", "terminal", "globals"
}

g.mapleader = ","
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

local augroup = vim.api.nvim_create_augroup("youxkei", {})
vim.api.nvim_create_autocmd("BufWritePost", {
  group = augroup,
  pattern = "init.lua",
  callback = function()
    cmd("luafile " .. fn.stdpath("config") .. "/init.lua")
    require("packer").compile()
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

vim.keymap.set("n", "j", "gj")
vim.keymap.set("n", "k", "gk")
vim.keymap.set("n", "gj", "j")
vim.keymap.set("n", "gk", "k")

vim.keymap.set("n", "<leader>w", "<cmd>w<cr>", { silent = true })
vim.keymap.set("n", "Q", "<nop>")
vim.keymap.set("n", "i", "empty(getline('.')) ? 'cc' : 'i'", { expr = true })
vim.keymap.set("n", "a", "empty(getline('.')) ? 'cc' : 'a'", { expr = true })
vim.keymap.set("n", "<c-j>", "<cmd>cnext<cr>", { silent = true })
vim.keymap.set("n", "<c-k>", "<cmd>cabove<cr>", { silent = true })
vim.keymap.set("t", "<c-v>", [[<c-\><c-n>pi]], { silent = true })

vim.keymap.set("n", "<c-q>s<tab>", "gT")
vim.keymap.set("n", "<c-q><tab>", "gt")
vim.keymap.set("n", "<c-s-tab>", "gT")
vim.keymap.set("n", "<c-tab>", "gt")

for i = 1, 9 do
  local lhs = "<c-q>" .. i
  local rhs = i .. "gt"

  if i == 9 then
    rhs = "<cmd>tablast<cr>"
  end

  vim.keymap.set("n", lhs, rhs)
  vim.keymap.set("i", lhs, rhs)
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
    on_exit = function(rev_parse_head_job)
      local ref = rev_parse_head_job:result()[1]

      Job:new {
        command = "git",
        args = { "ls-remote", "--get-url", "origin" },
        enabled_recording = true,
        on_exit = function(ls_remote_job)
          local url_head = "https://github.com/" .. ls_remote_job:result()[1]:match("^git@github.com:(.*).git$")

          Job:new {
            command = "git",
            args = { "rev-parse", "--show-toplevel" },
            enabled_recording = true,
            on_exit = function(rev_parse_toplevel_job)
              local git_root = rev_parse_toplevel_job:result()[1]
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

local install_path = fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"
local packer_bootstrap = false
if fn.empty(fn.glob(install_path)) > 0 then
  vim.o.runtimepath = fn.stdpath("data") .. "/site/pack/*/start/*," .. vim.o.runtimepath
  packer_bootstrap = fn.system({
    "git", "clone", "--depth", "1", "https://github.com/wbthomason/packer.nvim", install_path,
  })
end

require("packer").startup {
  function(use)
    use("wbthomason/packer.nvim")

    use("nvim-lua/plenary.nvim")

    use { "christianchiarulli/nvcode-color-schemes.vim",
      config = function()
        vim.cmd [[
          colorscheme nord

          highlight Indent1 guifg=#BF616A guibg=none gui=nocombine
          highlight Indent2 guifg=#D08770 guibg=none gui=nocombine
          highlight Indent3 guifg=#EBCB8B guibg=none gui=nocombine
          highlight Indent4 guifg=#A3BE8C guibg=none gui=nocombine
          highlight Indent5 guifg=#B48EAD guibg=none gui=nocombine
          highlight IndentBlanklineSpaceChar guifg=#434C5E guibg=none gui=nocombine
          highlight IndentBlanklineSpaceCharBlankline guifg=#434C5E guibg=none gui=nocombine

          highlight Comment gui=NONE cterm=NONE
        ]]
      end
    }

    use { "thinca/vim-ambicmd", config = function()
      vim.keymap.set("c", "<cr>", "ambicmd#expand('<cr>')", { expr = true })
      vim.keymap.set("c", "<space>", "ambicmd#expand('<space>')", { expr = true })
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

    use { "lambdalisue/suda.vim" }

    use { "sgur/vim-editorconfig" }

    use { "lambdalisue/vim-manpager", opt = true, cmd = "ASMANPAGER" }

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
      vim.g.mwDefaultHighlightingPalette = "maximum"

      vim.keymap.set({ "n", "v" }, "<leader>m", "<plug>MarkSet", { remap = true })
      vim.keymap.set("n", "<leader>n", "<plug>MarkAllClear", { remap = true })
    end }

    use {
      "nvim-treesitter/nvim-treesitter",
      run = ":TSUpdate",
      requires = {
        "p00f/nvim-ts-rainbow",
        "nvim-treesitter/nvim-treesitter-textobjects",
        "andymass/vim-matchup",
      },
      config = function()
        require("nvim-treesitter.configs").setup {
          ensure_installed = {
            "bash",
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
            additional_vim_regex_highlighting = false,
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
            select = {
              enable = true,
              lookahead = true,
              keymaps = {
                ["af"] = "@function.declaration",
              },
            },
            move = {
              enable = true,
              set_jumps = true,
              goto_next_start = {
                ["]m"] = "@function.declaration",
              },
              goto_next_end = {
                ["]M"] = "@function.declaration",
              },
              goto_previous_start = {
                ["[m"] = "@function.declaration",
              },
              goto_previous_end = {
                ["[M"] = "@function.declaration",
              },
            },
          },
          matchup = {
            enable = true,
          },
        }

        vim.api.nvim_create_autocmd("FileType", {
          group = "youxkei",
          pattern = {
            "sh",
            "dockerfile",
            "go",
            "html",
            "javascript",
            "json",
            "lua",
            "nix",
            "rust",
            "toml",
            "typescriptreact",
            "typescript",
            "yaml",
          },
          callback = function()
            vim.opt_local.foldmethod = "expr"
            vim.opt_local.foldexpr = "nvim_treesitter#foldexpr()"
          end,
        })

        vim.g.matchup_matchparen_offscreen = { method = "" }
      end,
    }

    use { "romgrk/nvim-treesitter-context", disable = true, config = function()
      require("treesitter-context").setup {
        enable = true,
      }
    end }

    use {
      "neovim/nvim-lspconfig",
      requires = {
        "hrsh7th/cmp-nvim-lsp",
        "amiralies/vim-rescript",
        "jose-elias-alvarez/null-ls.nvim",
      },
      config = function()
        local lspconfig = require("lspconfig")

        local augroup_lsp_format = vim.api.nvim_create_augroup("LspFormatting", {})
        local on_attach = function(client, bufnr)
          if client.supports_method("textDocument/formatting") then
            vim.api.nvim_clear_autocmds({ group = augroup_lsp_format, buffer = bufnr })
            vim.api.nvim_create_autocmd("BufWritePre", {
              group = augroup_lsp_format,
              buffer = bufnr,
              callback = function()
                vim.lsp.buf.format({
                  bufnr = bufnr,
                  timeout_ms = 10000,
                })
              end,
            })
          end

          vim.keymap.set("n", "K", vim.lsp.buf.hover, { silent = true, buffer = bufnr })
          vim.keymap.set("n", "<leader>ln", vim.lsp.buf.rename, { silent = true, buffer = bufnr })
        end

        local capabilities = require("cmp_nvim_lsp").default_capabilities()
        capabilities.textDocument.foldingRange = {
          dynamicRegistration = false,
          lineFoldingOnly = true
        }

        lspconfig.gopls.setup {
          capabilities = capabilities,
          on_attach = on_attach,
          settings = {
            gopls = {
              gofumpt = true,
            },
          },
        }

        lspconfig.rescriptls.setup {
          capabilities = capabilities,
          on_attach = on_attach,
          cmd = {
            "node",
            vim.fn.stdpath("data") .. "/site/pack/packer/start/vim-rescript/server/out/server.js",
            "--stdio",
          }
        }

        lspconfig.tsserver.setup {
          capabilities = capabilities,
          on_attach = function(client)
            client.resolved_capabilities.document_formatting = false
            on_attach(client)
          end,
          -- TODO: refine tsserver-path
          cmd = { "typescript-language-server", "--stdio", "--tsserver-path", "/home/youxkei/.nix-profile/bin/tsserver" },
        }

        lspconfig.sumneko_lua.setup {
          capabilities = capabilities,
          on_attach = on_attach,
          settings = {
            Lua = {
              diagnostics = {
                globals = { "vim" }
              }
            }
          }
        }

        lspconfig.ocamllsp.setup {
          capabilities = capabilities,
          on_attach = on_attach,
        }

        lspconfig.rust_analyzer.setup {
          capabilities = capabilities,
          on_attach = on_attach,
        }


        local null_ls = require("null-ls")
        null_ls.setup({
          on_attach = on_attach,
          sources = {
            null_ls.builtins.formatting.prettier.with {
              filetypes = {
                "javascript",
                "javascriptreact",
                "typescript",
                "typescriptreact",
                "html",
                "json",
              },
            },
            null_ls.builtins.formatting.goimports,
          },
        })
      end,
    }

    use {
      "nvim-telescope/telescope.nvim",
      requires = {
        "nvim-lua/popup.nvim",
        "nvim-lua/plenary.nvim",
        "nvim-telescope/telescope-file-browser.nvim",
        "rmagatti/session-lens",
      },
      config = function()
        local telescope = require("telescope")
        local session_lens = require("session-lens")

        telescope.load_extension("file_browser")
        telescope.load_extension("session-lens")

        telescope.setup {
          pickers = {
            buffers = {
              mappings = {
                n = {
                  d = "delete_buffer",
                },
              },
            },
          },
        }

        local builtin = require("telescope.builtin")

        vim.keymap.set("n", "<leader>tf", builtin.find_files)
        vim.keymap.set("n", "<leader>tF", function() builtin.find_files { hidden = true } end)
        vim.keymap.set("n", "<leader>tg", builtin.live_grep)
        vim.keymap.set("n", "<leader>tb", builtin.buffers)
        vim.keymap.set("n", "<leader>te", telescope.extensions.file_browser.file_browser)
        vim.keymap.set("n", "<leader>ts", session_lens.search_session)
        vim.keymap.set("n", "<leader>tr", builtin.resume)
        vim.keymap.set("n", "<leader>lr", builtin.lsp_references)
        vim.keymap.set("n", "<leader>li", builtin.lsp_implementations)
        vim.keymap.set("n", "<leader>ls", function() builtin.lsp_document_symbols { symbol_width = 80 } end)
        vim.keymap.set("n", "<leader>lS", function() builtin.lsp_dynamic_workspace_symbols { symbol_width = 80 } end)
        vim.keymap.set("n", "<leader>le", builtin.diagnostics)
        vim.keymap.set("n", "<leader>ld", builtin.lsp_definitions)
      end
    }

    use { "phaazon/hop.nvim", config = function()
      local hop = require("hop")

      hop.setup {
        keys = "etuhonasidpgyfcrlkmxbjwqv",
        jump_on_sole_occurrence = false,
      }

      vim.keymap.set("n", "s", hop.hint_char2)
    end }

    use { "lewis6991/gitsigns.nvim", requires = "nvim-lua/plenary.nvim", config = function()
      require("gitsigns").setup()
    end }

    use { "kevinhwang91/nvim-hlslens", config = function()
      require("hlslens").setup({
        calm_down = true,
      })

      vim.keymap.set(
        "n", "n",
        "<cmd>execute('normal! ' . v:count1 . 'n')<cr><cmd>lua require('hlslens').start()<cr>",
        { silent = true }
      )
      vim.keymap.set(
        "n", "N",
        "<cmd>execute('normal! ' . v:count1 . 'N')<cr><cmd>lua require('hlslens').start()<cr>",
        { silent = true }
      )
      vim.keymap.set("n", "*", "*<cmd>lua require('hlslens').start()<cr>")
      vim.keymap.set("n", "#", "#<cmd>lua require('hlslens').start()<cr>")
      vim.keymap.set("n", "g*", "g*<cmd>lua require('hlslens').start()<cr>")
      vim.keymap.set("n", "g#", "g#<cmd>lua require('hlslens').start()<cr>")
    end }

    use { "lukas-reineke/indent-blankline.nvim", config = function()
      require("indent_blankline").setup {
        char = "¦",
        char_highlight_list = { "Indent1", "Indent2", "Indent3", "Indent4", "Indent5" },
        buftype_exclude = { "terminal" }
      }
    end }

    use { "akinsho/toggleterm.nvim", config = function()
      require("toggleterm").setup {
        open_mapping = "<c-t>",
        direction = "float",
        float_opts = {
          border = "double",
        },
      }

      vim.keymap.set("n", "<c-t>", function() require("toggleterm").toggle(0) end, { silent = true })
    end }

    use { "karb94/neoscroll.nvim", disable = true, config = function()
      require("neoscroll").setup({
        mappings = { "<C-u>", "<C-d>" },
      })
    end }

    use { "github/copilot.vim", disable = true }

    use {
      "VonHeikemen/fine-cmdline.nvim",
      disable = true, -- disabled because it doesn't work with cmp-cmdline
      requires = "MunifTanjim/nui.nvim",
      config = function()
        vim.keymap.set("n", ":", require("fine-cmdline").open)
      end
    }

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
        --"hrsh7th/cmp-nvim-lsp-signature-help",
        --"tzachar/cmp-tabnine",
      },
      config = function()
        local cmp = require("cmp")
        cmp.setup {
          snippet = {
            expand = function(args)
              require("luasnip").lsp_expand(args.body)
            end
          },
          window = {
            completion = cmp.config.window.bordered(),
            -- documentation = cmp.config.window.bordered(),
          },
          mapping = cmp.mapping.preset.insert({}),
          sources = cmp.config.sources({
            { name = "nvim_lsp" },
            { name = "luasnip" },
            { name = "path" },
            { name = "buffer" },
            { name = "look" },
            --{ name = "nvim_lsp_signature_help" },
            --{ name = "cmp_tabnine" },
          }),
          preselect = cmp.PreselectMode.None,
        }

        cmp.setup.cmdline(":", {
          sources = {
            { name = "cmdline" },
          },
        })
      end
    }

    use { "tzachar/cmp-tabnine", run = "./install.sh", disable = true, config = function()
      require("cmp_tabnine.config"):setup {}
    end }

    use {
      "folke/trouble.nvim",
      requires = { "kyazdani42/nvim-web-devicons" },
      config = function()
        local trouble = require("trouble")
        trouble.setup {}

        vim.keymap.set("n", "<leader>r", trouble.open)
      end,
    }

    use { "ellisonleao/glow.nvim" }

    use { "hoschi/yode-nvim", requires = "nvim-lua/plenary.nvim", config = function()
      require("yode-nvim").setup({})

      vim.keymap.set("v", "<leader>yc", ":YodeCreateSeditorFloating<cr>")
    end }

    use { "https://gitlab.com/yorickpeterse/nvim-window", config = function()
      require("nvim-window").setup({
        chars = {
          "e", "t", "u", "h", "o", "n", "a", "s", "i", "d", "p", "g", "y", "f", "c", "r", "l",
          "k", "m", "x", "b", "j", "w", "q", "v",
        },
        normal_hl = "Normal",
        hint_hl = "Bold",
        border = "single"
      })

      vim.keymap.set("n", "<leader>h", require("nvim-window").pick)
    end }

    use { "b0o/incline.nvim", disable = true, config = function()
      require("incline").setup {}
    end }

    use {
      "rmagatti/auto-session",
      config = function()
        require("auto-session").setup {
          auto_session_suppress_dirs = { "~/repo" },
          pre_save_cmds = {
            function()
              -- close floating window
              for _, win in ipairs(vim.api.nvim_list_wins()) do
                local config = vim.api.nvim_win_get_config(win)
                if config.relative ~= "" then
                  vim.api.nvim_win_close(win, true)
                end
              end
            end,
          },
          post_restore_cmds = {
            function()
              vim.cmd("luafile " .. vim.fn.stdpath("config") .. "/init.lua")
            end,
          },
        }
      end
    }

    use {
      "rmagatti/session-lens",
      requires = { "rmagatti/auto-session" },
      config = function()
        require("session-lens").setup {
          theme_conf = {
            layout_config = {
              width = function(_, max_columns, _)
                return math.min(max_columns, 140)
              end,
            },
          },
        }
      end
    }

    use {
      "nvim-lualine/lualine.nvim",
      requires = {
        "kyazdani42/nvim-web-devicons",
        "rmagatti/auto-session",
      },
      config = function()
        require("lualine").setup {
          options = {
            component_separators = { left = "\u{e0b5}", right = "\u{e0b7}" },
            section_separators = { left = "\u{e0b4}", right = "\u{e0b6}" },
          },
          sections = {
            lualine_b = {
              require("auto-session-library").current_session_name,
              { "branch", icon = "" },
              "diff",
              "diagnostics",
            },
            lualine_c = {
              { "filename", path = 1 --[[ relative path --]] }
            }
          },
          tabline = {
            lualine_c = { { 'tabs', mode = 2 } },
          },
        }

      end
    }

    use { "mizlan/iswap.nvim", config = function()
      local iswap = require("iswap")
      iswap.setup {
        keys = "etuhonasidpgyfcrlkmxbjwqv"
      }

      vim.keymap.set("n", "gs", iswap.iswap_with)
      vim.keymap.set("n", "gn", [[^<cmd>lua require("iswap").iswap_node_with()<cr>]])
    end }

    use { "f-person/git-blame.nvim" }

    -- languages, text objects, operators

    use { "amiralies/vim-rescript" }

    use { "sgur/vim-textobj-parameter", requires = "kana/vim-textobj-user" }

    use { "kana/vim-textobj-entire", requires = "kana/vim-textobj-user" }

    use { "kana/vim-operator-replace", requires = "kana/vim-operator-user", config = function()
      vim.keymap.set({ "n", "v" }, "_", "<plug>(operator-replace)")
    end }

    use { "haya14busa/vim-operator-flashy", config = function()
      vim.keymap.set({ "n", "v", "o" }, "y", "<plug>(operator-flashy)", { remap = true })
      vim.keymap.set("n", "Y", "<plug>(operator-flashy)$", { remap = true })
    end }

    use { "machakann/vim-sandwich", config = function()
      vim.g.sandwich_no_default_key_mappings = true
      vim.g["sandwich#recipes"] = vim.g["sandwich#default_recipes"]

      vim.keymap.set(
        "n", "<leader>sd",
        "<plug>(operator-sandwich-delete)<plug>(operator-sandwich-release-count)<plug>(textobj-sandwich-query-a)",
        { remap = true }
      )
      vim.keymap.set(
        "n", "<leader>sr",
        "<plug>(operator-sandwich-replace)<plug>(operator-sandwich-release-count)<plug>(textobj-sandwich-query-a)",
        { remap = true }
      )
      vim.keymap.set(
        "n", "<leader>sdb",
        "<plug>(operator-sandwich-delete)<plug>(operator-sandwich-release-count)<plug>(textobj-sandwich-auto-a)",
        { remap = true }
      )
      vim.keymap.set(
        "n", "<leader>srb",
        "<plug>(operator-sandwich-replace)<plug>(operator-sandwich-release-count)<plug>(textobj-sandwich-auto-a)",
        { remap = true }
      )
      vim.keymap.set("n", "<leader>sa", "<plug>(operator-sandwich-add)")

      vim.keymap.set("x", "<leader>sa", "<plug>(operator-sandwich-add)", { remap = true })
      vim.keymap.set("o", "<leader>sa", "<plug>(operator-sandwich-g@)", { remap = true })
      vim.keymap.set("x", "<leader>sd", "<plug>(operator-sandwich-delete)", { remap = true })
      vim.keymap.set("x", "<leader>sr", "<plug>(operator-sandwich-replace)", { remap = true })

      vim.keymap.set({ "x", "o" }, "ib", "<plug>(textobj-sandwich-auto-i)", { remap = true })
      vim.keymap.set({ "x", "o" }, "ab", "<plug>(textobj-sandwich-auto-a)", { remap = true })
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

    use { "mfussenegger/nvim-treehopper", config = function()
      local tsht = require("tsht")

      tsht.config.hint_keys = {
        "e", "t", "u", "h", "o", "n", "a", "s", "i", "d", "p", "g", "y", "f", "c", "r", "l",
        "k", "m", "x", "b", "j", "w", "q", "v",
      }

      vim.keymap.set("o", "n", tsht.nodes)
      vim.keymap.set("v", "n", [[:lua require("tsht").nodes()<CR>]])
    end }

    use { "David-Kunz/treesitter-unit", config = function()
      local unit = require("treesitter-unit")

      vim.keymap.set("x", "iu", [[:lua require("treesitter-unit").select()<CR>]])
      vim.keymap.set("x", "au", [[:lua require("treesitter-unit").select(true)<CR>]])
      vim.keymap.set("o", "iu", function() unit.select() end)
      vim.keymap.set("o", "au", function() unit.select(true) end)
    end }

    if packer_bootstrap then
      require("packer").sync()
    end
  end
}
