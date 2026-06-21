local function force_redraw_floating_terminal(win)
  if not win or not vim.api.nvim_win_is_valid(win) then return end
  local cfg = vim.api.nvim_win_get_config(win)
  if cfg.relative == "" then return end
  local buf = vim.api.nvim_win_get_buf(win)
  if vim.bo[buf].buftype ~= "terminal" then return end
  local orig = cfg.width
  cfg.width = orig - 1
  vim.api.nvim_win_set_config(win, cfg)
  vim.defer_fn(function()
    if vim.api.nvim_win_is_valid(win) then
      cfg.width = orig
      vim.api.nvim_win_set_config(win, cfg)
    end
  end, 50)
end

-- gtd /do works inside a per-task worktree (~/repo/gtd/.claude/worktrees/do-<slug>/) and
-- puts clones + scratch under that worktree's todo/<slug>/ (main repo in repo/, reference
-- clones in ref/, both gitignored). nvim enters a worktree via ,dt (cd + possession session);
-- the current task is identified by cwd, so ,df/,dF/,dg/,dG search the cwd's worktree with
-- ignored files included (.git excluded; ,df/,dg also exclude ref/).
local function gtd_wt_root()
  return vim.fn.expand("~/repo/gtd/.claude/worktrees")
end

-- slug -> the task work dir inside the worktree
-- (.claude/worktrees/do-<slug>/todo/<slug>/, or the worktree root if absent).
local function gtd_wt_task_dir(root, slug)
  local wt = root .. "/do-" .. slug
  local td = wt .. "/todo/" .. slug
  if vim.fn.isdirectory(td) == 1 then return td end
  return wt
end

-- The current task's work dir, derived from cwd: if we're inside a do-<slug> worktree,
-- return its todo/<slug>/ (or the worktree root). Otherwise nil.
local function gtd_cwd_task_dir()
  local root = gtd_wt_root()
  local slug = vim.fn.getcwd():match("^" .. vim.pesc(root) .. "/do%-([^/]+)")
  if not slug then return nil end
  return gtd_wt_task_dir(root, slug)
end

-- ,df/,dF/,dg/,dG: search the current task (resolved from cwd). kind = "files" | "grep".
-- with_ref=false → main repo + notes (exclude ref/); true → everything (main + ref + notes).
local function gtd_search(kind, with_ref)
  local dir = gtd_cwd_task_dir()
  if not dir then
    return vim.notify("not in a gtd /do worktree — ,dt first", vim.log.levels.WARN)
  end
  require("snacks").picker[kind] {
    cwd = dir,
    hidden = true,
    ignored = true,
    exclude = with_ref and { ".git" } or { ".git", "ref" },
  }
end

-- Parse ~/repo/gtd/list.md and return an array of {title, slug} (higher = higher priority).
local function gtd_list_tasks()
  local f = io.open(vim.fn.expand("~/repo/gtd/list.md"), "r")
  if not f then return {} end
  local tasks = {}
  for line in f:lines() do
    local title, slug = line:match("^%-%s*%[(.-)%]%(todo/(.-)/task%.md%)")
    if title and slug then
      tasks[#tasks + 1] = { title = title, slug = slug }
    end
  end
  f:close()
  return tasks
end

-- Create the do-<slug> worktree from HEAD if it doesn't exist. Returns (path, created) on
-- success, (nil, nil, err) on failure. /do reuses this worktree by path, /done merges and cleans it up.
local function gtd_ensure_worktree(slug)
  local gtd = vim.fn.expand("~/repo/gtd")
  local wt = gtd .. "/.claude/worktrees/do-" .. slug
  if vim.fn.isdirectory(wt) == 1 then return wt, false end
  -- Check out the branch if it already exists, otherwise create it fresh from HEAD.
  vim.fn.system({ "git", "-C", gtd, "rev-parse", "--verify", "--quiet", "refs/heads/do-" .. slug })
  local cmd = { "git", "-C", gtd, "worktree", "add", wt }
  if vim.v.shell_error == 0 then
    cmd[#cmd + 1] = "do-" .. slug
  else
    vim.list_extend(cmd, { "-b", "do-" .. slug, "HEAD" })
  end
  local out = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then return nil, nil, out end
  return wt, true
end

-- True if any real, named file buffer is open (not a terminal / scratch). Used to decide
-- whether saving the outgoing possession session is worthwhile: the before_save hook strips
-- terminal buffers, so saving a terminal-only view (e.g. just the Claude terminal) would
-- overwrite that session with an empty one.
local function gtd_has_file_buffer()
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.fn.buflisted(b) == 1 and vim.bo[b].buftype == "" and vim.api.nvim_buf_get_name(b) ~= "" then
      return true
    end
  end
  return false
end

-- ,dt: pick a gtd task from list.md (priority order), create its do-<slug> worktree if
-- missing, then cd into the worktree root and switch the possession session to it. The task
-- is identified by cwd afterward, so a Claude launched here runs inside the worktree.
local function gtd_enter_task()
  local tasks = gtd_list_tasks()
  if #tasks == 0 then
    return vim.notify("no gtd tasks in list.md", vim.log.levels.WARN)
  end
  vim.ui.select(tasks, {
    prompt = "gtd task: ",
    format_item = function(t) return t.title end,
  }, function(choice)
    if not choice then return end
    local wt, created, err = gtd_ensure_worktree(choice.slug)
    if not wt then
      return vim.notify("gtd: failed to create worktree → " .. tostring(err), vim.log.levels.ERROR)
    end
    -- Switch the possession session to the worktree without clobbering the one we leave.
    -- Order matters: save the outgoing session (only if it has real files — see below), then
    -- PossessionClose (clears "current" with no autosave and no cd), and only THEN cd in. If
    -- we cd'd while the outgoing session was still "current", a later autosave (or load's
    -- on_load autosave) would write the worktree's buffers/cwd into that session.
    if gtd_has_file_buffer() then -- skip when only a terminal is open, else we'd save an empty session over it
      pcall(function() vim.cmd("silent! PossessionSaveCwd!") end)
    end
    pcall(function() vim.cmd("silent! PossessionClose") end)
    vim.cmd("cd " .. vim.fn.fnameescape(wt)) -- global cd into the worktree root (no session is current now)
    local paths = require("possession.paths")
    if paths.session(paths.cwd_session_name()):exists() then
      pcall(function() vim.cmd("silent! PossessionLoadCwd") end) -- existing worktree session → load it (current = this worktree)
    else
      -- Fresh worktree: PossessionClose above is a no-op when nothing was "current" (e.g. only a
      -- terminal was open), so the previous task's buffers can linger and no session gets created.
      -- Force a clean slate, then create + activate this worktree's session so it shows up in
      -- possession and future autosaves target it (not the previous task).
      pcall(function() require("possession.utils").delete_all_buffers(true) end)
      pcall(function() vim.cmd("silent! PossessionSaveCwd!") end)
    end
    vim.notify((created and "gtd: created + entered → " or "gtd: entered → ") .. choice.title)
  end)
end

-- Called by /done (via $NVIM RPC) right after it removes a do-<slug> worktree. If this nvim
-- was inside that worktree, return to the main gtd checkout + its session; then drop the
-- worktree's now-dangling cwd-session so autosave can't resurrect it.
function _G.GtdDoneCleanup(slug)
  local wt = gtd_wt_root() .. "/do-" .. slug
  local wt_name = vim.fn.fnamemodify(wt, ":~") -- == paths.cwd_session_name() when cwd == wt
  local paths = require("possession.paths")
  local function drop()
    if paths.session(wt_name):exists() then
      require("possession.session").delete(wt_name, { no_confirm = true })
    end
  end
  if vim.fn.getcwd():sub(1, #wt) == wt then
    -- Leave the (now-removed) worktree session first so cd'ing out can't autosave it back,
    -- then return to the main checkout and load its session.
    pcall(function() vim.cmd("silent! PossessionClose") end)
    vim.cmd("cd " .. vim.fn.fnameescape(vim.fn.expand("~/repo/gtd")))
    if paths.session(paths.cwd_session_name()):exists() then
      pcall(function() vim.cmd("silent! PossessionLoadCwd") end) -- back to main's session (closes /done terminal)
    end
    vim.schedule(drop) -- delete the worktree's dangling cwd-session file
  else
    drop()
  end
end

local host_ok, host = pcall(require, "youxkei.plugins.spec_host")
if not host_ok then host = {} end

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
    "shaunsingh/nord.nvim",
    config = function()
      vim.cmd.colorscheme("nord")

      local c = require("nord.named_colors")
      vim.api.nvim_set_hl(0, "Indent1", { fg = c.red })
      vim.api.nvim_set_hl(0, "Indent2", { fg = c.orange })
      vim.api.nvim_set_hl(0, "Indent3", { fg = c.yellow })
      vim.api.nvim_set_hl(0, "Indent4", { fg = c.green })
      vim.api.nvim_set_hl(0, "Indent5", { fg = c.purple })
      vim.api.nvim_set_hl(0, "IndentBlanklineSpaceChar", { fg = c.gray })
      vim.api.nvim_set_hl(0, "IndentBlanklineSpaceCharBlankline", { fg = c.gray })
      vim.api.nvim_set_hl(0, "SnacksPickerMatch", { fg = c.glacier, bold = true })
      vim.api.nvim_set_hl(0, "SnacksPickerDir", { fg = c.light_gray_bright })
      vim.api.nvim_set_hl(0, "SnacksPickerCursorLine", { bg = c.dark_gray })
      vim.api.nvim_set_hl(0, "SnacksPickerListCursorLine", { bg = c.dark_gray })
      vim.api.nvim_set_hl(0, "Comment", { fg = c.light_gray_bright, italic = false })
    end,
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
            buildFlags = host.gopls_build_flags,
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
            notifications = {
              confirm = function(picker, item)
                picker:close()
                if not item or not item.item then
                  return
                end

                local id = item.item.id
                vim.schedule(function()
                  snacks.notifier.show_history {
                    filter = function(notif)
                      return notif.id == id
                    end,
                  }
                end)
              end,
            },
          },
        },
        explorer = {},
        notifier = {},
        bigfile = {
          size = 5 * 1024 * 1024,
          setup = function(ctx)
            if vim.fn.exists(":NoMatchParen") ~= 0 then
              vim.cmd("NoMatchParen")
            end
            Snacks.util.wo(0, { foldmethod = "manual", statuscolumn = "", conceallevel = 0 })
            vim.b.completion = false
            vim.bo[ctx.buf].syntax = ""
          end,
        },
      }
    end,
    keys = {
      { "<leader>tf", function() require("snacks").picker.files { hidden = true } end, desc = "Select from files" },
      { "<leader>tF", function() require("snacks").picker.files { hidden = true, ignored = true } end, desc = "Select from all files" },
      { "<leader>tg", function() require("snacks").picker.grep { hidden = true } end, desc = "Grep from files" },
      { "<leader>tG", function() require("snacks").picker.grep { hidden = true, ignored = true } end, desc = "Grep from all files" },
      { "<leader>df", function() gtd_search("files", false) end, desc = "Find in current gtd task: main repo + notes (no ref)" },
      { "<leader>dF", function() gtd_search("files", true) end, desc = "Find in current gtd task: everything (main + ref + notes)" },
      { "<leader>dg", function() gtd_search("grep", false) end, desc = "Grep in current gtd task: main repo + notes (no ref)" },
      { "<leader>dG", function() gtd_search("grep", true) end, desc = "Grep in current gtd task: everything (main + ref + notes)" },
      { "<leader>dt", function() gtd_enter_task() end, desc = "Enter a gtd task: create worktree if needed + cd + session" },
      { "<leader>tb", function() require("snacks").picker.buffers() end, desc = "Select from buffers" },
      { "<leader>tr", function() require("snacks").picker.resume() end, desc = "Select from previous selections" },
      { "<leader>lr", function() require("snacks").picker.lsp_references() end, desc = "Select from references" },
      { "<leader>li", function() require("snacks").picker.lsp_implementations() end, desc = "Select from implementations" },
      { "<leader>ls", function() require("snacks").picker.lsp_symbols() end, desc = "Select from symbols in buffer" },
      { "<leader>lS", function() require("snacks").picker.lsp_workspace_symbols() end, desc = "Select from symbols in project" },
      { "<leader>le", function() require("snacks").picker.diagnostics() end, desc = "Select from diagnostics" },
      { "<leader>ld", function() require("snacks").picker.lsp_definitions() end, desc = "Select from definitions" },
      { "<leader>te", function() require("snacks").picker.explorer() end, desc = "Select with file browser" },
      { "<leader>tk", function() require("snacks").picker.keymaps() end, desc = "Select from keymaps" },
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
          delete_buffers = true,
        },
        hooks = {
          before_save = function(name)
            vim.cmd("%argd")
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
              if vim.bo[buf].buftype == "terminal" or vim.fn.buflisted(buf) == 0 then
                vim.api.nvim_buf_delete(buf, { force = true })
              end
            end
            return {}
          end,
          -- after_load = function(name, user_data)
          --   vim.cmd.luafile(vim.fn.stdpath("config") .. "/lua/youxkei/init.lua")
          -- end,
        },
      }
    end,
    keys = {
      { "<leader>ts", "<cmd>PossessionPick<cr>", desc = "Select from sessions" },
      { "<leader>r", "<cmd>silent! PossessionSaveCwd!<cr><cmd>silent! restart PossessionLoadCwd<cr>", desc = "Save, restart and restore cwd session" },
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
            force_redraw_floating_terminal(vim.api.nvim_get_current_win())
          end)
        end,
        mode = "t",
        ft = "toggleterm",
        desc = "Open Claude in toggleterm",
      },
      {
        "<c-g>",
        function()
          require("toggleterm").toggle()
          vim.cmd.Codex()
          vim.schedule(function()
            vim.cmd.startinsert()
            force_redraw_floating_terminal(vim.api.nvim_get_current_win())
          end)
        end,
        mode = "t",
        ft = "toggleterm",
        desc = "Open Codex in toggleterm",
      },
    },
  },

  { "f-person/git-blame.nvim" },

  {
    "folke/trouble.nvim",
    enabled = false,
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
    keys = {
      { "<leader>gp", "<cmd>Gitsigns preview_hunk_inline<cr>", desc = "Preview hunk" },
      { "<leader>ga", "<cmd>Gitsigns stage_hunk<cr>", desc = "Stage hunk" },
      { "<leader>gr", "<cmd>Gitsigns reset_hunk<cr>", desc = "Reset hunk" },
      { "<leader>gn", "<cmd>Gitsigns next_hunk<cr>", desc = "Next hunk" },
    },
    config = function()
      require("gitsigns").setup {}
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
      {
        "<c-l>",
        function()
          vim.cmd.ClaudeCodeSend()
          vim.schedule(function()
            force_redraw_floating_terminal(vim.api.nvim_get_current_win())
          end)
        end,
        mode = "v",
        desc = "Send to Claude",
      },

      {
        "<c-l>",
        function()
          vim.cmd.ClaudeCodeFocus()
          vim.schedule(function()
            force_redraw_floating_terminal(vim.api.nvim_get_current_win())
          end)
        end,
        desc = "Toggle Claude",
        mode = "n",
      },
    },
    config = function()
      require("claudecode").setup {
        terminal = {
          snacks_win_opts = {
            position = "float",
            width = 0.95,
            height = 0.95,
            keys = {
              {
                "<c-l>",
                function(self)
                  self:hide()
                end,
                mode = "t",
                desc = "Hide",
              },
              {
                "<c-t>",
                function(self)
                  self:hide()
                  require("toggleterm").toggle()
                end,
                mode = "t",
                desc = "Toggle toggleterm in Claude",
              },
              {
                "<c-g>",
                function(self)
                  self:hide()
                  vim.cmd.Codex()
                end,
                mode = "t",
                desc = "Open Codex",
              },
            },
          },
        },
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
    "youxkei/codex.nvim",
    version = "fix/find-available-port-listen-check",
    dependencies = {
      "folke/snacks.nvim",
    },
    keys = {
      {
        "<c-g>",
        function()
          vim.cmd.CodexSend()
          vim.schedule(function()
            force_redraw_floating_terminal(vim.api.nvim_get_current_win())
          end)
        end,
        mode = "v",
        desc = "Send to Codex",
      },

      {
        "<c-g>",
        function()
          vim.cmd.CodexFocus()
          vim.schedule(function()
            force_redraw_floating_terminal(vim.api.nvim_get_current_win())
          end)
        end,
        desc = "Toggle Codex",
        mode = "n",
      },
    },
    config = function()
      require("codex").setup {
        terminal_cmd = "codex --yolo",
        track_selection = true,
        keymaps = {
          enabled = false,
        },
        terminal = {
          snacks_win_opts = {
            position = "float",
            width = 0.95,
            height = 0.95,
            keys = {
              {
                "<c-g>",
                function(self)
                  self:hide()
                end,
                mode = "t",
                desc = "Hide",
              },
              {
                "<c-t>",
                function(self)
                  self:hide()
                  require("toggleterm").toggle()
                end,
                mode = "t",
                desc = "Toggle toggleterm in Codex",
              },
              {
                "<c-l>",
                function(self)
                  self:hide()
                  vim.cmd.ClaudeCode()
                end,
                mode = "t",
                desc = "Open Claude",
              },
            },
          },
        },
      }

      local augroup = vim.api.nvim_create_augroup("youxkei.codex", { clear = true })
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

  { "sevenc-nanashi/neov-ime.nvim" },

  {
    "Julian/lean.nvim",
    config = function()
      require("lean").setup {
        mappings = false
      }
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
