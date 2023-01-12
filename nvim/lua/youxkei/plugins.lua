return {
  { "nvim-lua/plenary.nvim", config = function()
    local Job = require("plenary.job")

    vim.keymap.set("v", "<leader>g", function()
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
    end, { desc = "Copy GitHub URL" })
  end },

  { "christianchiarulli/nvcode-color-schemes.vim",
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
  },

  { "thinca/vim-ambicmd", config = function()
    vim.keymap.set("c", "<cr>", [[ambicmd#expand("<cr>")]], { expr = true })
    vim.keymap.set("c", "<space>", [[ambicmd#expand("<space>")]], { expr = true })
  end },

  { "junegunn/vim-easy-align", config = function()
    vim.keymap.set("v", "<enter>", "<plug>(EasyAlign)", { remap = true })
  end },

  { "LeafCage/yankround.vim",
    init = function()
      vim.g.yankround_dir = vim.fn.stdpath("cache") .. "/yankround"
      vim.g.yankround_max_history = 100
    end,
    config = function()
      vim.keymap.set({ "n", "x" }, "p", "<plug>(yankround-p)", { remap = true })
      vim.keymap.set("n", "P", "<plug>(yankround-P)", { remap = true })
      vim.keymap.set({ "n", "x" }, "gp", "<plug>(yankround-gp)", { remap = true })
      vim.keymap.set("n", "gP", "<plug>(yankround-gP)", { remap = true })
      vim.keymap.set("n", "<C-p>", "<plug>(yankround-prev)", { remap = true })
      vim.keymap.set("n", "<C-n>", "<plug>(yankround-next)", { remap = true })
    end,
  },

  { "rhysd/committia.vim" },

  { "lambdalisue/suda.vim" },

  { "lambdalisue/vim-manpager" },

  { "chaoren/vim-wordmotion",
    init = function()
      vim.g.wordmotion_spaces = "_-."
      vim.g.wordmotion_mappings = {
        W = "",
        B = "",
        E = "",
        GE = "",
        aW = "",
        iW = "",
      }
    end,
    config = function()
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
    end,
  },

  { "inkarkat/vim-mark",
    dependencies = { "inkarkat/vim-ingo-library" },
    init = function()
      vim.g.mw_no_mappings = 1
      vim.g.mwDefaultHighlightingPalette = "maximum"
    end,
    config = function()
      vim.keymap.set({ "n", "v" }, "<leader>m", "<plug>MarkSet", { remap = true })
      vim.keymap.set("n", "<leader>n", "<plug>MarkAllClear", { remap = true })
    end,
  },

  { "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    dependencies = {
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
          enable = false,
        },
      }

      vim.g.matchup_matchparen_offscreen = { method = "" }
    end,
  },

  { "romgrk/nvim-treesitter-context", dependencies = { "nvim-treesitter/nvim-treesitter" }, config = function()
    require("treesitter-context").setup {
      enable = true,
    }
  end },

  { "mfussenegger/nvim-treehopper", dependencies = { "nvim-treesitter/nvim-treesitter" }, config = function()
    local tsht = require("tsht")

    tsht.config.hint_keys = {
      "e", "t", "u", "h", "o", "n", "a", "s", "i", "d", "p", "g", "y", "f", "c", "r", "l",
      "k", "m", "x", "b", "j", "w", "q", "v",
    }

    vim.keymap.set("o", "n", tsht.nodes, { desc = "Select treesitter node" })
    vim.keymap.set("v", "n", [[:lua require("tsht").nodes()<CR>]], { desc = "Select treesitter node" })
  end },

  { "David-Kunz/treesitter-unit", dependencies = { "nvim-treesitter/nvim-treesitter" }, config = function()
    local unit = require("treesitter-unit")

    vim.keymap.set("x", "iu", [[:lua require("treesitter-unit").select()<CR>]], { desc = "Select treesitter unit" })
    vim.keymap.set("x", "au", [[:lua require("treesitter-unit").select(true)<CR>]], { desc = "Select treesitter unit" })
    vim.keymap.set("o", "iu", function() unit.select() end, { desc = "Select treesitter unit" })
    vim.keymap.set("o", "au", function() unit.select(true) end, { desc = "Select treesitter unit" })
  end },

  { "kevinhwang91/nvim-ufo",
    dependencies = { "kevinhwang91/promise-async", "nvim-treesitter/nvim-treesitter" },
    config = function()
      local ufo = require("ufo")

      ufo.setup {}

      vim.opt_global.foldcolumn = "1"
      vim.opt_global.foldlevel = 99
      vim.opt_global.foldlevelstart = 99
      vim.opt_global.foldenable = true

      vim.keymap.set("n", "zR", ufo.openAllFolds, { desc = "Open all folds" })
      vim.keymap.set("n", "zM", ufo.closeAllFolds, { desc = "Close all folds" })
    end
  },

  { "rcarriga/nvim-notify", dependencies = { "nvim-telescope/telescope.nvim" }, config = function()
    local notify = require("notify")
    vim.notify = notify

    vim.keymap.set(
      "n", "<leader>tn",
      require('telescope').extensions.notify.notify,
      { desc = "Select from notifications with telescope" }
    )
  end },

  { "kevinhwang91/nvim-hlslens", config = function()
    require("hlslens").setup({
      calm_down = true,
    })

    vim.keymap.set("n", "n", [[<cmd>execute("normal! " . v:count1 . "n")<cr><cmd>lua require("hlslens").start()<cr>]])
    vim.keymap.set("n", "N", [[<cmd>execute("normal! " . v:count1 . "N")<cr><cmd>lua require("hlslens").start()<cr>]])
    vim.keymap.set("n", "*", [[*<cmd>lua require("hlslens").start()<cr>]])
    vim.keymap.set("n", "#", [[#<cmd>lua require("hlslens").start()<cr>]])
    vim.keymap.set("n", "g*", [[g*<cmd>lua require("hlslens").start()<cr>]])
    vim.keymap.set("n", "g#", [[g#<cmd>lua require("hlslens").start()<cr>]])
  end },

  { "haya14busa/vim-asterisk", dependencies = { "kevinhwang91/nvim-hlslens" }, config = function()
    vim.keymap.set(
      { "n", "v" }, "*",
      [[<plug>(asterisk-z*)<cmd>lua require("hlslens").start()<cr>]],
      { remap = true }
    )
    vim.keymap.set(
      { "n", "v" }, "#",
      [[<plug>(asterisk-z#)<cmd>lua require("hlslens").start()<cr>]],
      { remap = true }
    )
    vim.keymap.set(
      { "n", "v" }, "g*",
      [[<plug>(asterisk-gz*)<cmd>lua require("hlslens").start()<cr>]],
      { remap = true }
    )
    vim.keymap.set(
      { "n", "v" }, "g#",
      [[<plug>(asterisk-gz#)<cmd>lua require("hlslens").start()<cr>]],
      { remap = true }
    )
  end },

  { "neovim/nvim-lspconfig",
    dependencies = {
      { "hrsh7th/cmp-nvim-lsp", dependencies = { "hrsh7th/nvim-cmp" } },
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

        vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = bufnr, desc = "Hover with lsp" })
        vim.keymap.set("n", "<leader>ln", vim.lsp.buf.rename, { buffer = bufnr, desc = "Rename with lsp" })
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
  },

  { "ray-x/lsp_signature.nvim", dependencies = { "neovim/nvim-lspconfig" }, config = function()
    require("lsp_signature").setup {}
  end },

  { "hrsh7th/nvim-cmp",
    dependencies = {
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
        }),
        preselect = cmp.PreselectMode.None,
      }

      cmp.setup.cmdline(":", {
        sources = {
          { name = "cmdline" },
        },
      })
    end
  },

  { "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "rmagatti/session-lens",
    },
    config = function()
      local telescope = require("telescope")

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

      vim.keymap.set(
        "n", "<leader>tf",
        builtin.find_files,
        { desc = "Select from files with telescope" }
      )
      vim.keymap.set(
        "n", "<leader>tF",
        function() builtin.find_files { hidden = true } end,
        { desc = "Select from all files with telescope" }
      )
      vim.keymap.set(
        "n", "<leader>tg",
        builtin.live_grep,
        { desc = "Grep from files with telescope" }
      )
      vim.keymap.set(
        "n", "<leader>tG",
        function() builtin.live_grep { additional_args = { "-uuu" } } end,
        { desc = "Grep from all files with telescope" }
      )
      vim.keymap.set(
        "n", "<leader>tb",
        builtin.buffers,
        { desc = "Select from buffers with telescope" }
      )
      vim.keymap.set(
        "n", "<leader>tr",
        builtin.resume,
        { desc = "Select from previous selections with telescope" }
      )
      vim.keymap.set(
        "n", "<leader>lr",
        builtin.lsp_references,
        { desc = "Select from references with telescope" }
      )
      vim.keymap.set(
        "n", "<leader>li",
        builtin.lsp_implementations,
        { desc = "Select from implementations with telescope" }
      )
      vim.keymap.set(
        "n", "<leader>ls",
        function() builtin.lsp_document_symbols { symbol_width = 80 } end,
        { desc = "Select from symbols in buffer with telescope" }
      )
      vim.keymap.set(
        "n", "<leader>lS",
        function() builtin.lsp_dynamic_workspace_symbols { symbol_width = 80 } end,
        { desc = "Select from symbols in project with teselcope" }
      )
      vim.keymap.set(
        "n", "<leader>le",
        builtin.diagnostics,
        { desc = "Select from diagnostics with telescope" }
      )
      vim.keymap.set(
        "n", "<leader>ld",
        builtin.lsp_definitions,
        { desc = "Select from definitions with telescope" }
      )
    end,
  },

  { "nvim-telescope/telescope-file-browser.nvim",
    dependencies = { "nvim-telescope/telescope.nvim" },
    config = function()
      local telescope = require("telescope")

      telescope.load_extension("file_browser")

      vim.keymap.set(
        "n", "<leader>te",
        telescope.extensions.file_browser.file_browser,
        { desc = "Select with file browser" }
      )
    end,
  },

  { "rmagatti/auto-session", config = function()
    require("auto-session").setup {
      auto_session_suppress_dirs = { "~/repo" },
      pre_save_cmds = {
        function()
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
          vim.cmd("luafile " .. vim.fn.stdpath("config") .. "/lua/youxkei/init.lua")
        end,
      },
    }
  end },

  { "rmagatti/session-lens",
    dependencies = {
      "rmagatti/auto-session",
      "nvim-telescope/telescope.nvim",
    },
    config = function()
      local session_lens = require("session-lens")

      session_lens.setup {
        theme_conf = {
          layout_config = {
            width = function(_, max_columns, _)
              return math.min(max_columns, 140)
            end,
          },
        },
      }

      require("telescope").load_extension("session-lens")

      vim.keymap.set("n", "<leader>ts", session_lens.search_session, { desc = "Select from sessions with telescope" })
    end,
  },

  { "nvim-lualine/lualine.nvim",
    dependencies = {
      "rmagatti/auto-session",
      "nvim-tree/nvim-web-devicons",
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
        },
      }
    end
  },

  "f-person/git-blame.nvim",

  { "monaqa/dial.nvim", config = function()
    local dial = require("dial.map")

    vim.keymap.set("n", "<c-a>", dial.inc_normal(), { desc = "Increment" })
    vim.keymap.set("n", "<c-x>", dial.dec_normal(), { desc = "Decrement" })
    vim.keymap.set("v", "<c-a>", dial.inc_visual(), { desc = "Increment" })
    vim.keymap.set("v", "<c-x>", dial.dec_visual(), { desc = "Decrement" })
  end },

  { "Darazaki/indent-o-matic", config = function()
    require("indent-o-matic").setup {}
  end },


  { "iamcco/markdown-preview.nvim",
    build = function()
      vim.fn["mkdp#util#install"]()
    end,
  },

  { "nacro90/numb.nvim", config = function()
    require("numb").setup {}
  end },

  { "fgheng/winbar.nvim", config = function()
    require("winbar").setup {
      enabled = true,
      show_symbols = true,
    }
  end },


  { "akinsho/bufferline.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local bufferline = require("bufferline")

      bufferline.setup {}

      vim.keymap.set("n", "<c-q>s<tab>", function() bufferline.cycle(-1) end, { desc = "Go to the previous buffer" })
      vim.keymap.set("n", "<c-q><tab>", function() bufferline.cycle(1) end, { desc = "Go to the next buffer" })
      vim.keymap.set("n", "<c-s-tab>", function() bufferline.cycle(-1) end, { desc = "Go to the previous buffer" })
      vim.keymap.set("n", "<c-tab>", function() bufferline.cycle(1) end, { desc = "Go to the next buffer" })

      for i = 1, 9 do
        local lhs = "<c-q>" .. i
        local rhs = function() bufferline.go_to(i, true) end

        if i == 9 then
          rhs = function() bufferline.go_to(-1, true) end

          vim.keymap.set("n", lhs, rhs, { desc = "Go to the last buffer" })
          vim.keymap.set("i", lhs, rhs, { desc = "Go to the last buffer" })
        else
          vim.keymap.set("n", lhs, rhs, { desc = "Go to #" .. i .. " buffer" })
          vim.keymap.set("i", lhs, rhs, { desc = "Go to #" .. i .. " buffer" })
        end
      end

      vim.keymap.set(
        "n", "ZQ",
        function()
          local wins = vim.api.nvim_tabpage_list_wins(0)

          if #wins == 1 then
            vim.api.nvim_buf_delete(0, {})
          else
            vim.api.nvim_win_close(0, {})
          end
        end,
        { desc = "Close window or Delete buffer" }
      )
    end
  },

  { "phaazon/hop.nvim", config = function()
    local hop = require("hop")

    hop.setup {
      keys = "etuhonasidpgyfcrlkmxbjwqv",
      jump_on_sole_occurrence = false,
    }

    vim.keymap.set("n", "s", hop.hint_char2, { desc = "Jump with 2 chars" })
  end },

  { "akinsho/toggleterm.nvim", config = function()
    local toggleterm = require("toggleterm")

    toggleterm.setup {
      open_mapping = "<c-t>",
      direction = "float",
      float_opts = {
        border = "double",
      },
    }

    vim.keymap.set("n", "<c-t>", function() toggleterm.toggle(0) end, { desc = "Open terminal" })
  end },

  { "f-person/git-blame.nvim" },

  { "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local trouble = require("trouble")

      trouble.setup {}

      vim.keymap.set("n", "<leader>r", trouble.open, { desc = "Open diagnostics buffer" })
    end,
  },

  { "lewis6991/gitsigns.nvim", requires = "nvim-lua/plenary.nvim", config = function()
    require("gitsigns").setup()
  end },

  { "lukas-reineke/indent-blankline.nvim", dependencies = { "kevinhwang91/nvim-ufo" }, config = function()
    require("indent_blankline").setup {
      char = "¦",
      char_highlight_list = { "Indent1", "Indent2", "Indent3", "Indent4", "Indent5" },
      buftype_exclude = { "terminal" }
    }

    for _, keymap in pairs { "zo", "zO", "zc", "zC", "za", "zA", "zv", "zx", "zX", "zm", "zM", "zr", "zR" } do
      vim.keymap.set("n", keymap, keymap .. "<cmd>IndentBlanklineRefresh<cr>", { remap = true })
    end
  end },

  { "mbbill/undotree", init = function()
    vim.g.undotree_WindowLayout = 3
  end },

  { "folke/which-key.nvim", config = function()
    vim.o.timeout = true
    vim.o.timeoutlen = 300
    require("which-key").setup {}
  end },

  { "ckolkey/ts-node-action",
    dependencies = { "nvim-treesitter" },
    config = function()
      require("ts-node-action").setup {}

      vim.keymap.set({ "n" }, "<leader>ta", require("ts-node-action").node_action, { desc = "Trigger Node Action" })
    end
  },

  { "tpope/vim-repeat" },

  { "mizlan/iswap.nvim", dependencies = { "nvim-treesitter/nvim-treesitter" }, config = function()
    local iswap = require("iswap")
    iswap.setup {
      keys = "etuhonasidpgyfcrlkmxbjwqv"
    }

    vim.keymap.set("n", "gs", iswap.iswap_with, { desc = "Swap treesitter nodes" })
    vim.keymap.set("n", "gn", [[^<cmd>lua require("iswap").iswap_node_with()<cr>]], { desc = "Swap treesitter nodes" })
  end },

  { "sgur/vim-textobj-parameter", dependencies = { "kana/vim-textobj-user" } },

  { "kana/vim-textobj-entire", dependencies = { "kana/vim-textobj-user" } },

  { "kana/vim-niceblock" },

  { "kana/vim-operator-replace", dependencies = { "kana/vim-operator-user" }, config = function()
    vim.keymap.set({ "n", "v" }, "_", "<plug>(operator-replace)")
  end },

  { "haya14busa/vim-operator-flashy", dependencies = { "kana/vim-operator-user" }, config = function()
    vim.keymap.set({ "n", "v", "o" }, "y", "<plug>(operator-flashy)", { remap = true })
    vim.keymap.set("n", "Y", "<plug>(operator-flashy)$", { remap = true })
  end },

  { "machakann/vim-sandwich",
    init = function()
      vim.g.sandwich_no_default_key_mappings = true
    end,
    config = function()
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
    end
  },

  { "b3nj5m1n/kommentary",
    build = function()
      vim.g.kommentary_create_default_mappings = false
    end,
    config = function()
      vim.keymap.set("n", "<leader>cic", "<plug>kommentary_line_increase", { remap = true })
      vim.keymap.set("n", "<leader>ci", "<plug>kommentary_motion_increase", { remap = true })
      vim.keymap.set("x", "<leader>ci", "<plug>kommentary_visual_increase", { remap = true })
      vim.keymap.set("n", "<leader>cdc", "<plug>kommentary_line_decrease", { remap = true })
      vim.keymap.set("n", "<leader>cd", "<plug>kommentary_motion_decrease", { remap = true })
      vim.keymap.set("x", "<leader>cd", "<plug>kommentary_visual_decrease", { remap = true })
    end,
  },
}
