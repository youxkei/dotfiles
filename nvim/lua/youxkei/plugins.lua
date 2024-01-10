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
    build = ":TSUpdate",
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
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
      require("nvim-treesitter.parsers").get_parser_configs().satysfi = {
        install_info = {
          url = "https://github.com/monaqa/tree-sitter-satysfi",
          files = { "src/parser.c", "src/scanner.c" }
        },
        filetype = "satysfi",
      }

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
          "satysfi",
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
          enable = true,
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
      }

      require("ts_context_commentstring").setup {}
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
    "mfussenegger/nvim-treehopper",
    enabled = false,
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      local tsht = require("tsht")

      tsht.config.hint_keys = {
        "e", "t", "u", "h", "o", "n", "a", "s", "i", "d", "p", "g", "y", "f", "c", "r", "l",
        "k", "m", "x", "b", "j", "w", "q", "v",
      }

      vim.keymap.set("o", "n", tsht.nodes, { desc = "Select treesitter node" })
      vim.keymap.set("v", "n", [[:lua require("tsht").nodes()<CR>]], { desc = "Select treesitter node" })
    end
  },

  {
    "David-Kunz/treesitter-unit",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      local unit = require("treesitter-unit")

      vim.keymap.set("x", "iu", [[:lua require("treesitter-unit").select()<CR>]], { desc = "Select treesitter unit" })
      vim.keymap.set("x", "au", [[:lua require("treesitter-unit").select(true)<CR>]], { desc = "Select treesitter unit" })
      vim.keymap.set("o", "iu", function() unit.select() end, { desc = "Select treesitter unit" })
      vim.keymap.set("o", "au", function() unit.select(true) end, { desc = "Select treesitter unit" })
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
    "rcarriga/nvim-notify",
    dependencies = { "nvim-telescope/telescope.nvim" },
    config = function()
      vim.keymap.set(
        "n", "<leader>tn",
        require("telescope").extensions.notify.notify,
        { desc = "Select from notifications with telescope" }
      )
    end
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
      "jose-elias-alvarez/null-ls.nvim",
      "SmiteshP/nvim-navic",
    },
    config = function()
      local lspconfig = require("lspconfig")

      local augroup_lsp_format = vim.api.nvim_create_augroup("LspFormatting", {})
      local on_attach = function(client, bufnr)
        if client.supports_method("textDocument/formatting") then
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

        --[[ if client.supports_method("textDocument/documentSymbol") then
          require("nvim-navic").attach(client, bufnr)
        end ]]
        vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = bufnr, desc = "Hover with lsp" })
        vim.keymap.set("n", "<leader>ln", vim.lsp.buf.rename, { buffer = bufnr, desc = "Rename with lsp" })
      end

      local capabilities = require("cmp_nvim_lsp").default_capabilities()
      capabilities.textDocument.foldingRange = {
        dynamicRegistration = false,
        lineFoldingOnly = true,
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
          client.server_capabilities.documentFormattingProvider = false
          client.server_capabilities.documentRangeFormattingProvider = false
          on_attach(client)
        end,
        cmd = { "typescript-language-server", "--stdio" },
      }

      lspconfig.lua_ls.setup {
        capabilities = capabilities,
        on_attach = on_attach,
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

      lspconfig.ocamllsp.setup {
        capabilities = capabilities,
        on_attach = on_attach,
      }

      lspconfig.rust_analyzer.setup {
        capabilities = capabilities,
        on_attach = on_attach,
      }


      local null_ls = require("null-ls")
      null_ls.setup {
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
      }
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
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-buffer",
      "octaltree/cmp-look",
      "hrsh7th/cmp-cmdline",
      "dcampos/nvim-snippy",
      "dcampos/cmp-snippy",
      "nvim-lua/plenary.nvim",
      "uga-rosa/utf8.nvim",
      "onsails/lspkind.nvim",
      {
        "zbirenbaum/copilot-cmp",
        dependencies = {
          {
            "zbirenbaum/copilot.lua",
            config = function()
              require("copilot").setup {
                suggestions = { enabled = false },
                panel = { enabled = false },
              }
            end
          },
        },
        config = function()
          require("copilot_cmp").setup {}
        end
      },
    },
    config = function()
      local lspkind = require("lspkind")
      local utf8 = require("utf8")

      local has_words_before = function()
        if vim.api.nvim_buf_get_option(0, "buftype") == "prompt" then return false end
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0 and vim.api.nvim_buf_get_text(0, line - 1, 0, line - 1, col, {})[1]:match("^%s*$") == nil
      end

      local utf8_sub = function(str, n)
        local utf8_chars = {}
        local count = 0

        for _, char in utf8.codes(str) do
          if count < n then
            table.insert(utf8_chars, char)
          else
            break
          end
          count = count + 1
        end

        return table.concat(utf8_chars)
      end

      local utf8_sub_last = function(str, n)
        local utf8_str = {}
        local utc8_chars = {}
        local len = utf8.len(str)

        for _, char in utf8.codes(str) do
          table.insert(utf8_str, char)
        end

        for i = #utf8_str - n, #utf8_str + 1 do
          table.insert(utc8_chars, utf8_str[i])
        end

        return table.concat(utc8_chars)
      end

      local source = {}
      source.new = function()
        local self = setmetatable({ cache = {} }, { __index = source })
        return self
      end
      source.get_trigger_characters = function()
        return { "\t", "\n", ".", ":", "(", ")", "'", [["]], "[", "]", ",", "#", "*", "@", "|", "=", "-", "{", "}", "/",
          "\\", " ", "+", "?", "`" }
      end
      source.complete = function(_, params, callback)
        local curl = require("plenary.curl")

        local row, col = unpack(vim.api.nvim_win_get_cursor(0))
        local current_line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
        local before_cursor_lines = vim.api.nvim_buf_get_lines(0, 0, row - 1, false)
        local after_cursor_lines = vim.api.nvim_buf_get_lines(0, row, -1, false)

        local before_cursor = table.concat(before_cursor_lines, "\n") .. "\n" .. string.sub(current_line, 1, col)
        local after_cursor = string.sub(current_line, col + 1) .. "\n" .. table.concat(after_cursor_lines, "\n")

        local json_payload = vim.fn.json_encode {
          model = "gpt-3.5-turbo-instruct",
          prompt = utf8_sub_last(before_cursor, 4093 * 2),
          suffix = utf8_sub(after_cursor, 256 * 2),
          max_tokens = 32,
          temperature = 0,
        }

        curl.post("https://api.openai.com/v1/completions", {
          headers = {
            content_type = "application/json",
            authorization = "Bearer " .. vim.env.OPENAI_API_KEY,
          },
          raw_body = json_payload,
          callback = function(result)
            if result.status == 200 then
              vim.schedule(function()
                if result.body == "" then
                  callback()
                  return
                end

                local body = vim.fn.json_decode(result.body)
                local text = body.choices[1].text

                if text == "" then
                  callback()
                  return
                end

                callback {
                  isIncomplete = true,
                  items = {
                    {
                      label = text,
                      documentation = {
                        kind = "markdown",
                        value = table.concat({
                          "```" .. params.context.filetype,
                          text,
                          "```"
                        }, "\n"),
                      }
                    },
                  },
                }
              end)
            else
              callback()
            end
          end,
        })
      end

      local cmp = require("cmp")
      cmp.register_source("openai_codex", source.new())

      cmp.setup {
        snippet = {
          expand = function(args)
            require("snippy").expand_snippet(args.body)
          end,
        },
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
        },
        sources = cmp.config.sources {
          { name = "copilot", group_index = 2 },
          { name = "openai_codex", group_index = 2 },
          { name = "nvim_lsp", group_index = 2 },
          { name = "snippy", group_index = 2 },
          { name = "path", group_index = 2 },
          { name = "buffer", group_index = 2 },
          -- { name = "look", group_index = 2 },
        },
        preselect = cmp.PreselectMode.None,
        formatting = {
          format = lspkind.cmp_format {
            mode = "symbol",
            max_width = 50,
            symbol_map = { Copilot = "" }
          }
        },
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
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
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

  {
    "nvim-telescope/telescope-file-browser.nvim",
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

  {
    "rmagatti/auto-session",
    dependencies = {
      "nvim-telescope/telescope.nvim",
    },
    config = function()
      require("auto-session").setup {
        auto_session_suppress_dirs = { "~/repo" },
        pre_save_cmds = { "%argd" },
        post_restore_cmds = {
          function()
            vim.cmd.luafile(vim.fn.stdpath("config") .. "/lua/youxkei/init.lua")
            vim.cmd.LspRestart("copilot")
          end,
        },

        session_lens = {
          buftypes_to_ignore = { "terminal" },
        }
      }

      vim.keymap.set(
        "n", "<leader>ts", require("auto-session.session-lens").search_session,
        { desc = "Select from sessions with telescope" }
      )
    end
  },

  {
    "nvim-lualine/lualine.nvim",
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
            require("auto-session.lib").current_session_name,
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

      local augroup = vim.api.nvim_create_augroup("YouxkeiGitBlame", { clear = true })
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
    "iamcco/markdown-preview.nvim",
    build = function()
      vim.fn["mkdp#util#install"]()
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
      local toggleterm = require("toggleterm")

      toggleterm.setup {
        open_mapping = "<c-t>",
        direction = "float",
        float_opts = {
          border = "double",
        },
      }

      vim.keymap.set("n", "<c-t>", function()
        if not YOUXKEI_TOGGLETERM_ID_MAP then
          YOUXKEI_TOGGLETERM_ID_MAP = {}
        end

        local cwd = vim.fn.getcwd()
        local id = YOUXKEI_TOGGLETERM_ID_MAP[cwd]

        if not id then
          id = YOUXKEI_TOGGLETERM_NEXT_ID or 1
          YOUXKEI_TOGGLETERM_ID_MAP[cwd] = id
          YOUXKEI_TOGGLETERM_NEXT_ID = id + 1
        end

        toggleterm.toggle(id)
      end, { desc = "Open terminal" })
    end
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
    main = "ibl",
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
        vim.keymap.set("n", keymap, keymap .. "<cmd>IndentBlanklineRefresh<cr>", { remap = true })
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
    "mizlan/iswap.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      local iswap = require("iswap")
      iswap.setup {
        keys = "etuhonasidpgyfcrlkmxbjwqv"
      }

      vim.keymap.set("n", "gs", iswap.iswap_with, { desc = "Swap treesitter nodes" })
      vim.keymap.set("n", "gn", [[^<cmd>lua require("iswap").iswap_node_with()<cr>]], { desc = "Swap treesitter nodes" })
    end
  },

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
      "rcarriga/nvim-notify",
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
      "nvim-telescope/telescope.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require "octo".setup {}
    end
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
