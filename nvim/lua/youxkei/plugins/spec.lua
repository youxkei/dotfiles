return {
  {
    "nvim-lua/plenary.nvim",
    config = function()
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
                local url_head = "https://github.com/" ..
                    ls_remote_job:result()[1]:match("^https://github.com/(.*).git$")

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
                      vim.notify("GitHub URL: " .. url, vim.log.levels.INFO)
                      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<esc>", true, false, true), "n", false)
                    end)
                  end,
                }:start()
              end,
            }:start()
          end,
        }:start()
      end, { desc = "Copy GitHub URL" })
    end
  },

  {
    "christianchiarulli/nvcode-color-schemes.vim",
    init = function()
      vim.cmd.colorscheme("nord")
      vim.api.nvim_set_hl(0, "Indent1", { fg = "#BF616A" })
      vim.api.nvim_set_hl(0, "Indent2", { fg = "#D08770" })
      vim.api.nvim_set_hl(0, "Indent3", { fg = "#EBCB8B" })
      vim.api.nvim_set_hl(0, "Indent4", { fg = "#A3BE8C" })
      vim.api.nvim_set_hl(0, "Indent5", { fg = "#B48EAD" })
      vim.api.nvim_set_hl(0, "IndentBlanklineSpaceChar", { fg = "#434C5E" })
      vim.api.nvim_set_hl(0, "IndentBlanklineSpaceCharBlankline", { fg = "#434C5E" })
      vim.api.nvim_set_hl(0, "SnacksPickerDir", { fg = "#616E88" })
      vim.api.nvim_set_hl(0, "SnacksPickerCursorLine", { bg = "#3B4252" })
      vim.api.nvim_set_hl(0, "SnacksPickerListCursorLine", { bg = "#3B4252" })
      vim.api.nvim_set_hl(0, "Comment", { fg = "#616E88", italic = false })
    end
  },

  {
    "thinca/vim-ambicmd",
    config = function()
      vim.keymap.set("c", "<cr>", [[ambicmd#expand("<cr>")]], { expr = true })
      vim.keymap.set("c", "<space>", [[ambicmd#expand("<space>")]], { expr = true })
    end
  },

  {
    "junegunn/vim-easy-align",
    config = function()
      vim.keymap.set("v", "<enter>", "<plug>(EasyAlign)", { remap = true })
    end
  },

  {
    "LeafCage/yankround.vim",
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

  {
    "chaoren/vim-wordmotion",
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

  {
    "inkarkat/vim-mark",
    dependencies = { "inkarkat/vim-ingo-library" },
    init = function()
      vim.g.mw_no_mappings = 1
      vim.g.mwDefaultHighlightingPalette = "maximum"
    end,
    config = function()
      vim.keymap.set({ "n", "v" }, "<leader>m", "<plug>MarkSet", { remap = true })
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
    dependencies = {
      {
        "nvim-treesitter/nvim-treesitter-textobjects",
        branch = "main",
      },
      "JoosepAlviste/nvim-ts-context-commentstring",
      {
        "hiphish/rainbow-delimiters.nvim",
        config = function()
          local rainbow_delimiters = require("rainbow-delimiters")
          vim.g.rainbow_delimiters = {
            strategy = {
              [""] = rainbow_delimiters.strategy["global"],
            },
            query = {
              tsx = "rainbow-parens",
            },
          }
        end
      },
    },
    init = function()
      vim.g.skip_ts_context_commentstring_module = true
      vim.g.matchup_matchparen_offscreen = { method = "" }
    end,
    config = function()
      require("nvim-treesitter").install {
        "bash", "cue", "dockerfile", "go", "gomod", "html",
        "javascript", "json", "lua", "nix", "rust",
        "terraform", "toml", "tsx", "typescript", "yaml",
      }

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("nvim-treesitter-start", {}),
        callback = function()
          pcall(vim.treesitter.start)
        end,
      })

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("nvim-treesitter-indent", {}),
        callback = function()
          vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })

      require("nvim-treesitter-textobjects").setup {
        select = { lookahead = true },
        move = { set_jumps = true },
      }

      vim.keymap.set({ "x", "o" }, "af", function()
        require("nvim-treesitter-textobjects.select").select_textobject("@function.declaration", "textobjects")
      end)

      vim.keymap.set({ "n", "x", "o" }, "]m", function()
        require("nvim-treesitter-textobjects.move").goto_next_start("@function.declaration", "textobjects")
      end)
      vim.keymap.set({ "n", "x", "o" }, "]M", function()
        require("nvim-treesitter-textobjects.move").goto_next_end("@function.declaration", "textobjects")
      end)
      vim.keymap.set({ "n", "x", "o" }, "[m", function()
        require("nvim-treesitter-textobjects.move").goto_previous_start("@function.declaration", "textobjects")
      end)
      vim.keymap.set({ "n", "x", "o" }, "[M", function()
        require("nvim-treesitter-textobjects.move").goto_previous_end("@function.declaration", "textobjects")
      end)

      require("ts_context_commentstring").setup {
        enable_autocmd = false,
      }
    end,
  },

  {
    "romgrk/nvim-treesitter-context",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("treesitter-context").setup {
        enable = true,
      }
    end
  },

  {
    "kevinhwang91/nvim-ufo",
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
    end,
  },

  {
    "Wansmer/treesj",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      local treesj = require("treesj")
      treesj.setup {
        use_default_keymaps = false,
      }

      vim.keymap.set("n", "<leader>j", treesj.toggle, { desc = "Togggle between split and join" })
    end,
  },

  {
    "kevinhwang91/nvim-hlslens",
    config = function()
      require("hlslens").setup {
        calm_down = true,
      }

      vim.keymap.set("n", "n", [[<cmd>execute("normal! " . v:count1 . "n")<cr><cmd>lua require("hlslens").start()<cr>]])
      vim.keymap.set("n", "N", [[<cmd>execute("normal! " . v:count1 . "N")<cr><cmd>lua require("hlslens").start()<cr>]])
      vim.keymap.set("n", "*", [[*<cmd>lua require("hlslens").start()<cr>]])
      vim.keymap.set("n", "#", [[#<cmd>lua require("hlslens").start()<cr>]])
      vim.keymap.set("n", "g*", [[g*<cmd>lua require("hlslens").start()<cr>]])
      vim.keymap.set("n", "g#", [[g#<cmd>lua require("hlslens").start()<cr>]])
    end
  },

  {
    "haya14busa/vim-asterisk",
    dependencies = { "kevinhwang91/nvim-hlslens" },
    config = function()
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
    end
  },

  {
    "neovim/nvim-lspconfig",
    dependencies = {
      { "hrsh7th/cmp-nvim-lsp", dependencies = { "hrsh7th/nvim-cmp" } },
      "nvimtools/none-ls.nvim",
      "SmiteshP/nvim-navic",
    },
    config = function()
      local augroup_lsp = vim.api.nvim_create_augroup("youxkei.lsp", { clear = true })
      local augroup_lsp_format = vim.api.nvim_create_augroup("youxkei.lsp.formatting", { clear = true })

      -- Global LspAttach autocmd (replaces on_attach)
      vim.api.nvim_create_autocmd("LspAttach", {
        group = augroup_lsp,
        callback = function(args)
          local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
          local bufnr = args.buf

          -- Auto-format on save
          if client:supports_method("textDocument/formatting") then
            vim.api.nvim_clear_autocmds { group = augroup_lsp_format, buffer = bufnr }
            vim.api.nvim_create_autocmd("BufWritePre", {
              group = augroup_lsp_format,
              buffer = bufnr,
              callback = function()
                vim.lsp.buf.format {
                  bufnr = bufnr,
                  timeout_ms = 10000,
                }
              end,
            })
          end

          -- Disable formatting for ts_ls (use prettierd via null-ls instead)
          if client.name == "ts_ls" then
            client.server_capabilities.documentFormattingProvider = false
            client.server_capabilities.documentRangeFormattingProvider = false
          end

          --[[ if client:supports_method("textDocument/documentSymbol") then
            require("nvim-navic").attach(client, bufnr)
          end ]]
          vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = bufnr, desc = "Hover with lsp" })
          vim.keymap.set("n", "<leader>ln", vim.lsp.buf.rename, { buffer = bufnr, desc = "Rename with lsp" })
        end,
      })

      -- Default capabilities for all LSP servers
      local capabilities = require("cmp_nvim_lsp").default_capabilities()
      capabilities.textDocument.foldingRange = {
        dynamicRegistration = false,
        lineFoldingOnly = true,
      }

      vim.lsp.config("*", {
        capabilities = capabilities,
      })

      vim.lsp.config.gopls = {
        settings = {
          gopls = {
            gofumpt = true,
          },
        },
      }

      vim.lsp.config.lua_ls = {
        settings = {
          Lua = {
            format = {
              enable = true,
              defaultConfig = {
                indent_style = "space",
                indent_size = "2",
                quote_style = "double",
                call_arg_parentheses = "remove_table_only",
                trailing_table_separator = "keep",
                space_before_function_call_single_arg = "true",
                space_inside_function_call_parentheses = "false",
                align_array_table = "false",
              },
            },
            diagnostics = {
              globals = { "vim" },
              neededFileStatus = {
                ["codestyle-check"] = "Any"
              },
            },
          },
        },
      }

      local null_ls = require("null-ls")
      null_ls.setup {
        sources = {
          null_ls.builtins.formatting.prettierd.with {
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
      }

      vim.lsp.enable { "gopls", "lua_ls", "rust_analyzer", "protols", "pyright" }

      vim.api.nvim_create_autocmd("FileType", {
        group = augroup_lsp,
        callback = function(ctx)
          if not vim.tbl_contains(
                { "javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx" },
                ctx.match
              ) then
            return
          end

          -- node
          if vim.fn.findfile("package.json", ".;") ~= "" then
            vim.lsp.start(vim.lsp.config.ts_ls)
            return
          end

          -- deno
          vim.lsp.start(vim.lsp.config.denols)
        end,
      })
    end,
  },

  {
    "ray-x/lsp_signature.nvim",
    dependencies = { "neovim/nvim-lspconfig" },
    config = function()
      require("lsp_signature").setup {}
    end
  },

  {
    "hrsh7th/nvim-cmp",
    enabled = false,
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-buffer",
      "octaltree/cmp-look",
      "hrsh7th/cmp-cmdline",
    },
    config = function()
      local has_words_before = function()
        if vim.api.nvim_buf_get_option(0, "buftype") == "prompt" then return false end
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0 and vim.api.nvim_buf_get_text(0, line - 1, 0, line - 1, col, {})[1]:match("^%s*$") == nil
      end

      local cmp = require("cmp")

      cmp.setup {
        window = {
          completion = cmp.config.window.bordered(),
          -- documentation = cmp.config.window.bordered(),
        },
        mapping = cmp.mapping.preset.insert {
          ["<Tab>"] = vim.schedule_wrap(function(fallback)
            if cmp.visible() and has_words_before() then
              cmp.select_next_item { behavior = cmp.SelectBehavior.Select }
            else
              fallback()
            end
          end),
          ["<c-a>"] = cmp.mapping.complete {
            config = {
              sources = {
                { name = "openai" },
                { name = "copilot" },
              },
            },
          },
        },
        sources = cmp.config.sources {
          { name = "nvim_lsp", group_index = 2 },
          { name = "snippy", group_index = 2 },
          { name = "path", group_index = 2 },
          { name = "buffer", group_index = 2 },
          -- { name = "look", group_index = 2 },
        },
        preselect = cmp.PreselectMode.None,
      }

      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = "path" }
        }, {
          {
            name = "cmdline",
            option = {
              ignore_cmds = { "Man", "!" }
            }
          }
        })
      })
    end,
  },

  {
    "folke/snacks.nvim",
    config = function()
      local snacks = require("snacks")

      snacks.setup {
        picker = {
          sources = {
            buffers = {
              win = {
                list = { keys = { ["d"] = "bufdelete" } },
              },
            },
          },
        },
        explorer = {},
        notifier = {},
      }

    end,
    keys = {
      { "<leader>tf", function() require("snacks").picker.files { hidden = true } end, desc = "Select from files" },
      { "<leader>tF", function() require("snacks").picker.files { hidden = true, ignored = true } end, desc = "Select from all files" },
      { "<leader>tg", function() require("snacks").picker.grep { hidden = true } end, desc = "Grep from files" },
      { "<leader>tG", function() require("snacks").picker.grep { hidden = true, ignored = true } end, desc = "Grep from all files" },
      { "<leader>tb", function() require("snacks").picker.buffers() end, desc = "Select from buffers" },
      { "<leader>tr", function() require("snacks").picker.resume() end, desc = "Select from previous selections" },
      { "<leader>lr", function() require("snacks").picker.lsp_references() end, desc = "Select from references" },
      { "<leader>li", function() require("snacks").picker.lsp_implementations() end, desc = "Select from implementations" },
      { "<leader>ls", function() require("snacks").picker.lsp_symbols() end, desc = "Select from symbols in buffer" },
      { "<leader>lS", function() require("snacks").picker.lsp_workspace_symbols() end, desc = "Select from symbols in project" },
      { "<leader>le", function() require("snacks").picker.diagnostics() end, desc = "Select from diagnostics" },
      { "<leader>ld", function() require("snacks").picker.lsp_definitions() end, desc = "Select from definitions" },
      { "<leader>te", function() require("snacks").picker.explorer() end, desc = "Select with file browser" },
      { "<leader>tn", function() require("snacks").picker.notifications() end, desc = "Select from notifications" },
    },
  },

  {
    "jedrzejboczar/possession.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "folke/snacks.nvim",
    },
    config = function()
      require("possession").setup {
        autosave = {
          current = true,
          cwd = true,
          on_load = true,
          on_quit = true,
        },
        plugins = {
          delete_hidden_buffers = false,
          stop_lsp_clients = true,
        },
        hooks = {
          before_save = function(name)
            vim.cmd("%argd")
            return {}
          end,
          after_load = function(name, user_data)
            vim.cmd.luafile(vim.fn.stdpath("config") .. "/lua/youxkei/init.lua")
          end,
        },
      }
    end,
    keys = {
      { "<leader>ts", "<cmd>PossessionPick<cr>", desc = "Select from sessions" },
    },
  },

  {
    "nvim-lualine/lualine.nvim",
    dependencies = {
      "jedrzejboczar/possession.nvim",
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
            function() return require("possession.session").get_session_name() or "" end,
            { "branch", icon = "" },
            "diff",
            "diagnostics",
          },
          lualine_x = { "%S", "encoding", "fileformat", "filetype" },
        },
      }
    end,
  },

  {
    "f-person/git-blame.nvim",
    config = function()
      local ignored_filetypes = { "octo", "toggleterm" }
      local gitblame = require("gitblame")
      gitblame.setup {
        ignored_filetypes = ignored_filetypes,
      }

      local augroup = vim.api.nvim_create_augroup("youxkei.git-blame", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        group = augroup,
        pattern = ignored_filetypes,
        callback = function()
          gitblame.disable()
          gitblame.enable()
        end,
      })
    end
  },

  {
    "monaqa/dial.nvim",
    config = function()
      local dial = require("dial.map")

      vim.keymap.set("n", "<c-a>", dial.inc_normal(), { desc = "Increment" })
      vim.keymap.set("n", "<c-x>", dial.dec_normal(), { desc = "Decrement" })
      vim.keymap.set("v", "<c-a>", dial.inc_visual(), { desc = "Increment" })
      vim.keymap.set("v", "<c-x>", dial.dec_visual(), { desc = "Decrement" })
    end
  },

  {
    "Darazaki/indent-o-matic",
    config = function()
      require("indent-o-matic").setup {}
    end
  },


  {
    "nacro90/numb.nvim",
    config = function()
      require("numb").setup {}
    end
  },

  {
    "akinsho/bufferline.nvim",
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

      -- vim.keymap.set(
      --   "n", "ZQ",
      --   function()
      --     local windows = vim.api.nvim_tabpage_list_wins(0)
      --     local window_count = 0
      --     for _, window in ipairs(windows) do
      --       if vim.api.nvim_win_get_config(window).relative == "" then
      --         window_count = window_count + 1
      --       end
      --     end

      --     if window_count == 1 then
      --       vim.api.nvim_buf_delete(0, {})
      --     else
      --       vim.api.nvim_win_close(0, {})
      --     end
      --   end,
      --   { desc = "Close window or Delete buffer" }
      -- )
    end,
  },

  {
    "phaazon/hop.nvim",
    enabled = false,
    config = function()
      local hop = require("hop")

      hop.setup {
        keys = "etuhonasidpgyfcrlkmxbjwqv",
        jump_on_sole_occurrence = false,
      }

      vim.keymap.set("n", "s", hop.hint_char2, { desc = "Jump with 2 chars" })
    end
  },

  {
    "akinsho/toggleterm.nvim",
    config = function()
      require("toggleterm").setup {
        open_mapping = "<c-t>",
        direction = "float",
        float_opts = {
          border = "double",
        },
      }
    end,
    keys = {
      {
        "gf",
        function()
          local cfile = vim.fn.expand("<cfile>")

          if cfile ~= "" then
            vim.notify("Open file: " .. cfile, "info")
            require("toggleterm").toggle()
            vim.cmd.edit(cfile)
          end
        end,
        ft = "toggleterm",
        desc = "Open file under cursor in toggleterm",
      },
      {
        "<c-l>",
        function()
          require("toggleterm").toggle()
          vim.cmd.ClaudeCode()
          vim.schedule(function()
            vim.cmd.startinsert()
          end)
        end,
        mode = "t",
        ft = "toggleterm",
        desc = "Open Claude in toggleterm",
      },
    },
  },

  { "f-person/git-blame.nvim" },

  {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local trouble = require("trouble")

      trouble.setup {}

      vim.keymap.set("n", "<leader>r", trouble.open, { desc = "Open diagnostics buffer" })
    end,
  },

  {
    "lewis6991/gitsigns.nvim",
    requires = "nvim-lua/plenary.nvim",
    config = function()
      require("gitsigns").setup()
    end
  },

  {
    "lukas-reineke/indent-blankline.nvim",
    dependencies = { "kevinhwang91/nvim-ufo" },
    config = function()
      require("ibl").setup {
        indent = {
          char = "┋",
          tab_char = "┋",
          highlight = { "Indent1", "Indent2", "Indent3", "Indent4", "Indent5" },
        },
        exclude = {
          buftypes = { "terminal" },
        },
        scope = {
          enabled = false,
        },
      }

      for _, keymap in pairs { "zo", "zO", "zc", "zC", "za", "zA", "zv", "zx", "zX", "zm", "zM", "zr", "zR" } do
        vim.keymap.set("n", keymap, keymap .. [[<cmd>lua require("ibl").debounced_refresh(0)<cr>]], { remap = true })
      end
    end
  },

  {
    "mbbill/undotree",
    init = function()
      vim.g.undotree_WindowLayout = 3
    end
  },

  {
    "folke/which-key.nvim",
    config = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 1000
      require("which-key").setup {}
    end
  },

  {
    "ckolkey/ts-node-action",
    dependencies = { "nvim-treesitter" },
    config = function()
      require("ts-node-action").setup {}

      vim.keymap.set({ "n" }, "<leader>ta", require("ts-node-action").node_action, { desc = "Trigger Node Action" })
    end,
  },

  { "tpope/vim-repeat" },
  {
    "utilyre/barbecue.nvim",
    dependencies = {
      "neovim/nvim-lspconfig",
      "SmiteshP/nvim-navic",
      "nvim-tree/nvim-web-devicons"
    },
    config = function()
      require("barbecue").setup {
        show_navic = false,
        attach_navic = false,
        show_modified = true,
      }
    end,
  },

  {
    "LeonHeidelbach/trailblazer.nvim",
    enabled = false,
    config = function()
      require("trailblazer").setup {
        mappings = {
          nv = {
            motions = {
              new_trail_mark = "<leader>bn",
              track_back = "<leader>bb",
              peek_move_next_down = "<leader>bj",
              peek_move_previous_up = "<leader>bk",
              toggle_trail_mark_list = "<nop>",
            },
            actions = {
              delete_all_trail_marks = "<leader>bd",
              paste_at_last_trail_mark = "<nop>",
              paste_at_all_trail_marks = "<nop>",
              set_trail_mark_select_mode = "<nop>",
              switch_to_next_trail_mark_stack = "<nop>",
              switch_to_previous_trail_mark_stack = "<nop>",
              set_trail_mark_stack_sort_mode = "<nop>",
            },
          },
        },
      }
    end,
  },

  {
    "folke/noice.nvim",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "folke/snacks.nvim",
    },
    config = function()
      require("noice").setup {
        lsp = {
          signature = {
            enabled = false,
          },
        },
      }
    end,
  },

  {
    "axkirillov/hbac.nvim",
    enabled = false,
    config = function()
      require("hbac").setup {
        autoclose = true,
        threshold = 6,
      }
    end
  },

  {
    "folke/flash.nvim",
    enabled = false,
    config = function()
      local flash = require("flash")

      flash.setup {
        label = {
          uppercase = false,
        },
        modes = {
          search = {
            enabled = false,
          },
        },
      }

      vim.keymap.set({ "n", "x", "o" }, "s", flash.jump, { desc = "Jump with flash" })
      vim.keymap.set({ "n", "x", "o" }, "S", function() flash.jump { continue = true } end, {
        desc = "Continue last jump with flash"
      })
      vim.keymap.set({ "n" }, "<leader>n", flash.treesitter, { desc = "Select treesitter node with flash" })
      vim.keymap.set({ "x", "o", }, "n", flash.treesitter, { desc = "Select treesitter node with flash" })
      vim.keymap.set("o", "r", flash.remote, { desc = "Do command in remote position with flash" })
    end
  },

  {
    "echasnovski/mini.bufremove",
    version = "*",
    config = function()
      local bufremove = require("mini.bufremove")

      bufremove.setup {}

      vim.keymap.set("n", "<leader>bw", bufremove.wipeout, { desc = "Wipeout buffer" })
    end
  },

  {
    "pwntester/octo.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "folke/snacks.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("octo").setup {
        picker = "snacks",
      }
    end
  },

  {
    "johmsalas/text-case.nvim",
    config = function()
      local textcase = require("textcase")
      textcase.setup {
        default_keymappings_enabled = false,
      }

      vim.keymap.set({ "n", "v" }, "gas", function() textcase.operator("to_snake_case") end,
        { desc = "Change to snake case" })
      vim.keymap.set({ "n", "v" }, "gac", function() textcase.operator("to_camel_case") end,
        { desc = "Change to lower camel case" })
      vim.keymap.set({ "n", "v" }, "gap", function() textcase.operator("to_pascal_case") end,
        { desc = "Change to pascal case" })
      vim.keymap.set({ "n", "v" }, "gak", function() textcase.operator("to_dash_case") end,
        { desc = "Change to kebab case" })
      vim.keymap.set({ "n", "v" }, "gam", function() textcase.operator("to_constant_case") end,
        { desc = "Change to macro case" })
    end
  },

  {
    "echasnovski/mini.jump2d",
    version = "*",
    config = function()
      local jump2d = require("mini.jump2d")

      jump2d.setup {
        labels = "hutenosadir,c.gpvqwjmkl:z;fybx"
      }
    end
  },

  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = function() vim.fn["mkdp#util#install"]() end,
  },

  {
    "stevearc/quicker.nvim",
    config = function()
      require("quicker").setup {}
    end,
  },

  {
    "coder/claudecode.nvim",
    dependencies = {
      "folke/snacks.nvim",
    },
    keys = {
      { "<leader>a", nil, desc = "AI/Claude Code" },
      { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
      { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
      { "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude" },
      { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },

      { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr><cmd>ClaudeCodeFocus<cr>", desc = "Accept diff" },
      { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr><cmd>ClaudeCodeFocus<cr>", desc = "Deny diff" },

      {
        "<c-l>",
        function()
          vim.cmd.ClaudeCodeSend()

          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_get_option(buf, "filetype") == "claudecode" then
              vim.schedule(function()
                vim.cmd.ClaudeCodeFocus()
              end)

              break
            end
          end
        end,
        mode = "v",
        desc = "Send to Claude",
      },

      { "<c-l>", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
      { "<c-l>", "<cmd>ClaudeCode<cr>", mode = "t", ft = "snacks_terminal", desc = "Toggle Claude" },
      {
        "<c-t>",
        function()
          vim.cmd.ClaudeCode()
          require("toggleterm").toggle()
        end,
        mode = "t",
        ft = "snacks_terminal",
        desc = "Toggle toggleterm in Claude"
      },
    },
    config = function()
      require("claudecode").setup {
        terminal_cmd = "claude --dangerously-skip-permissions",
      }

      local augroup = vim.api.nvim_create_augroup("youxkei.claudecode", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        group = augroup,
        pattern = "snacks_terminal",
        callback = function(args)
          vim.bo[args.buf].buflisted = false
        end,
      })
    end
  },

  {
    "A7Lavinraj/fyler.nvim",
    dependencies = { "nvim-mini/mini.icons" },
    branch = "stable",
  },

  { "sgur/vim-textobj-parameter", dependencies = { "kana/vim-textobj-user" } },
  { "kana/vim-textobj-entire", dependencies = { "kana/vim-textobj-user" } },

  { "kana/vim-niceblock" },
  {
    "kana/vim-operator-replace",
    dependencies = { "kana/vim-operator-user" },
    config = function()
      vim.keymap.set({ "n", "v" }, "_", "<plug>(operator-replace)")
    end
  },

  {
    "haya14busa/vim-operator-flashy",
    dependencies = { "kana/vim-operator-user" },
    config = function()
      vim.keymap.set({ "n", "v", "o" }, "y", "<plug>(operator-flashy)", { remap = true })
      vim.keymap.set("n", "Y", "<plug>(operator-flashy)$", { remap = true })
    end
  },

  {
    "machakann/vim-sandwich",
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
    end,
  },

  {
    "numToStr/Comment.nvim",
    dependencies = { "JoosepAlviste/nvim-ts-context-commentstring" },
    config = function()
      require("Comment").setup {
        mappings = {
          extra = false,
        },
        pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
      }
    end
  },
}
