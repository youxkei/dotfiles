local cmd = vim.cmd
local fn = vim.fn
local g = vim.g
local opt = vim.opt
local opt_global = vim.opt_global

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
opt.cinoptions = {"L0", "(2", "U1", "m1"}

opt_global.expandtab = true
opt_global.smarttab = true
opt_global.shiftwidth = 4
opt_global.tabstop = 4
opt_global.softtabstop = 4

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
opt.listchars = {tab = " ･", trail = "-", nbsp = "%"}

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
opt.timeout = false

g.mapleader = ","

cmd[[
  augroup youxkei
    autocmd!

    autocmd BufWritePost init.lua ++nested source <afile> | PackerCompile
    autocmd InsertLeave * call system('fcitx5-remote -c')

    autocmd FileType rescript,lua,nix,javascript,ocaml,text setlocal shiftwidth=2 tabstop=2 softtabstop=2
  augroup END
]]

function youxkei_toggleterm()
  local id = vim.t.youxkei_toggleterm_id

  if not vim.t.youxkei_toggleterm_id then
    id = youxkei_next_toggleterm_unique_id or 1
    youxkei_next_toggleterm_unique_id = id + 1

    vim.t.youxkei_toggleterm_id = id
  end

  require("toggleterm").toggle(id)
end

local packer_dir = fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"

if fn.empty(fn.glob(packer_dir)) > 0 then
  packer_bootstrap = fn.system({"git", "clone", "https://github.com/wbthomason/packer.nvim", packer_dir})
end

require("packer").startup{
  function(use)
    use("wbthomason/packer.nvim")

    use{"christianchiarulli/nvcode-color-schemes.vim", after = "indent-blankline.nvim", config = function()
      vim.cmd[[colorscheme nord]]
    end}

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
      keymap.nnoremap{"<c-j>", "<cmd>cnext<cr>", silent = true}
      keymap.nnoremap{"<c-k>", "<cmd>cabove<cr>", silent = true}

      keymap.tnoremap{"<c-v>", [[<c-\><c-n>pi]], silent = true}
    end}

    use{"thinca/vim-ambicmd", config = function()
      local keymap = require("astronauta.keymap")

      keymap.cnoremap{"<cr>", "ambicmd#expand('<cr>')", expr = true}
      keymap.cnoremap{"<space>", "ambicmd#expand('<space>')", expr = true}
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
          return fnamemodify(empty(cwd) ? getcwd() : cwd, ':t')
        endfunction
      ]]
    end}

    use{"previm/previm"}

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

    use{"rhysd/committia.vim"}

    use{"kana/vim-tabpagecd"}

    use{"w0rp/ale", config = function()
      vim.g.ale_lint_on_save = 1
      vim.g.ale_fix_on_save = 1
      vim.g.ale_lint_on_text_changed = 1

      vim.g.ale_fixers = {
        ["*"] = {"remove_trailing_lines", "trim_whitespace"},
      }
    end}

    use{"machakann/vim-swap", config = function()
      local keymap = require("astronauta.keymap")

      vim.g.swap_no_default_key_mappings = true

      keymap.nmap{"gs", "<plug>(swap-interactive)"}
      keymap.omap{"i,", "<plug>(swap-textobject-i)"}
      keymap.xmap{"i,", "<plug>(swap-textobject-i)"}
      keymap.omap{"a,", "<plug>(swap-textobject-a)"}
      keymap.xmap{"a,", "<plug>(swap-textobject-a)"}
    end}

    use{"lambdalisue/suda.vim"}

    use{"sgur/vim-editorconfig"}

    use{"prakashdanish/vim-githubinator"}

    use{"lambdalisue/vim-manpager", opt = true, cmd = "MANPAGER"}

    use{"haya14busa/vim-asterisk", config = function()
      local keymap = require("astronauta.keymap")

      keymap.map{"*", "<plug>(asterisk-z*)<cmd>lua require('hlslens').start()<cr>"}
      keymap.map{"#", "<plug>(asterisk-z#)<cmd>lua require('hlslens').start()<cr>"}
      keymap.map{"g*", "<plug>(asterisk-gz*)<cmd>lua require('hlslens').start()<cr>"}
      keymap.map{"g#", "<plug>(asterisk-gz#)<cmd>lua require('hlslens').start()<cr>"}
    end}

    use{"chaoren/vim-wordmotion", config = function()
      local keymap = require("astronauta.keymap")

      vim.g.wordmotion_spaces = "_-."
      vim.g.wordmotion_mappings = {
        W = "",
        B = "",
        E = "",
        GE = "",
        aW = "",
        iW = "",
      }

      keymap.nnoremap{"W", "w"}
      keymap.nnoremap{"B", "b"}
      keymap.nnoremap{"E", "e"}
      keymap.nnoremap{"gE", "ge"}
      keymap.onoremap{"W", "w"}
      keymap.xnoremap{"W", "w"}
      keymap.onoremap{"B", "b"}
      keymap.xnoremap{"B", "b"}
      keymap.onoremap{"E", "e"}
      keymap.xnoremap{"E", "e"}
      keymap.onoremap{"GE", "ge"}
      keymap.xnoremap{"GE", "ge"}
      keymap.xnoremap{"iW", "iw"}
      keymap.onoremap{"iW", "iw"}
      keymap.xnoremap{"aW", "aw"}
      keymap.onoremap{"aW", "aw"}
    end}

    use{"inkarkat/vim-mark", requires = "inkarkat/vim-ingo-library", config = function()
      local keymap = require("astronauta.keymap")

      vim.g.mw_no_mappings = 1
      vim.g.mwDefaultHighlightingPalette = 'maximum'

      keymap.nmap{"<leader>m", "<plug>MarkSet"}
      keymap.vmap{"<leader>m", "<plug>MarkSet"}
      keymap.nmap{"<leader>n", "<plug>MarkAllClear"}
    end}

    use{
      "nvim-treesitter/nvim-treesitter",
      run = ":TSUpdate",
      requires = {
        "p00f/nvim-ts-rainbow",
      },
      config = function()
        require("nvim-treesitter.configs").setup{
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
          }
        }

        vim.cmd[[autocmd youxkei FileType sh,dockerfile,go,html,javascript,json,lua,nix,rust,toml,typescriptreact,typescript,yaml setlocal foldmethod=expr foldexpr=nvim_treesitter#foldexpr()]]
      end,
    }

    use{"romgrk/nvim-treesitter-context", config = function()
      require("treesitter-context.config").setup{
        enable = true,
      }
    end}

    use{
      "neovim/nvim-lspconfig",
      requires = {
        "hrsh7th/cmp-nvim-lsp",
        "amiralies/vim-rescript",
      },
      config = function()
        local keymap = require("astronauta.keymap")
        local lspconfig = require("lspconfig")

        local capabilities = vim.lsp.protocol.make_client_capabilities()
        capabilities = require("cmp_nvim_lsp").update_capabilities(capabilities)

        lspconfig.gopls.setup{
          capabilities = capabilities,
        }

        lspconfig.rescriptls.setup{
          capabilities = capabilities,
          cmd = {"node", vim.fn.stdpath("data") .. "/site/pack/packer/start/vim-rescript/server/out/server.js", "--stdio"}
        }

        lspconfig.tsserver.setup{
          capabilities = capabilities,
        }

        lspconfig.sumneko_lua.setup{
          capabilities = capabilities,
          cmd = {"lua-language-server"},
        }

        require("lspconfig").ocamllsp.setup{
          capabilities = capabilities,
        }

        keymap.nnoremap{"<leader>ln", "<cmd>lua vim.lsp.buf.rename()<cr>", silent = true}
        keymap.nnoremap{"<leader>ld", "<cmd>lua vim.lsp.buf.definition()<cr>", silent = true}

        vim.cmd[[autocmd youxkei BufWritePre *.go,*.res,*.js,*.lua,*.ml lua vim.lsp.buf.formatting_sync(nil, 1000)]]
      end,
    }

    use{
      "nvim-telescope/telescope.nvim",
      requires = {
        "nvim-lua/popup.nvim",
        "nvim-lua/plenary.nvim",
        "nvim-telescope/telescope-project.nvim",
      },
      config = function()
        local telescope = require("telescope")

        telescope.load_extension("project")

        telescope.setup{}

        local keymap = require("astronauta.keymap")
        local builtin = require("telescope.builtin")
        local project = function()
          telescope.extensions.project.project{
            attach_mappings = function(prompt_bufnr)
              require("telescope.actions").select_default:replace(function()
                require("telescope._extensions.project.actions").change_working_directory(prompt_bufnr)
              end)

              return true
            end
          }
        end

        keymap.nnoremap{"<leader>tf", builtin.find_files}
        keymap.nnoremap{"<leader>tg", builtin.live_grep}
        keymap.nnoremap{"<leader>tb", builtin.buffers}
        keymap.nnoremap{"<leader>tp", project}
        keymap.nnoremap{"<leader>lr", builtin.lsp_references}
        keymap.nnoremap{"<leader>li", builtin.lsp_implementations}
        keymap.nnoremap{"<leader>ls", builtin.lsp_document_symbols}
        keymap.nnoremap{"<leader>le", builtin.lsp_workspace_diagnostics}
      end
    }

    use{"phaazon/hop.nvim", config = function()
      local keymap = require("astronauta.keymap")
      local hop = require("hop")

      hop.setup{
        keys = "etonaspgyfcrlkmxbjwqvuhid",
        jump_on_sole_occurrence = false,
      }

      keymap.nnoremap{"s", hop.hint_char1}
    end}

    use{"lewis6991/gitsigns.nvim", requires = "nvim-lua/plenary.nvim", config = function()
      require("gitsigns").setup()
    end}

    use{'kevinhwang91/nvim-hlslens', config = function()
      local keymap = require("astronauta.keymap")

      require("hlslens").setup({
        calm_down = true,
      })

      keymap.noremap{"n", "<cmd>execute('normal! ' . v:count1 . 'n')<cr><cmd>lua require('hlslens').start()<cr>", silent = true}
      keymap.noremap{"N", "<cmd>execute('normal! ' . v:count1 . 'N')<cr><cmd>lua require('hlslens').start()<cr>", silent = true}
      keymap.noremap{"*", "*<cmd>lua require('hlslens').start()<cr>"}
      keymap.noremap{"#", "#<cmd>lua require('hlslens').start()<cr>"}
      keymap.noremap{"g*", "g*<cmd>lua require('hlslens').start()<cr>"}
      keymap.noremap{"g#", "g#<cmd>lua require('hlslens').start()<cr>"}
    end}

    use{"lukas-reineke/indent-blankline.nvim", config = function()
      require("indent_blankline").setup{
        char = "│",
        char_highlight_list = {"Indent1", "Indent2", "Indent3", "Indent4", "Indent5"},
        buftype_exclude = {"terminal"}
      }

      vim.cmd[[
        function! BlanklineHighlights() abort
          highlight Indent1 guifg=#BF616A guibg=none gui=nocombine
          highlight Indent2 guifg=#D08770 guibg=none gui=nocombine
          highlight Indent3 guifg=#EBCB8B guibg=none gui=nocombine
          highlight Indent4 guifg=#A3BE8C guibg=none gui=nocombine
          highlight Indent5 guifg=#B48EAD guibg=none gui=nocombine
          highlight IndentBlanklineSpaceChar guifg=white guibg=none gui=nocombine
          highlight IndentBlanklineSpaceCharBlankline guifg=white guibg=none gui=nocombine
        endfunction

        autocmd youxkei ColorScheme * call BlanklineHighlights()
      ]]
    end}

    use{"akinsho/nvim-toggleterm.lua", config = function()
      local keymap = require("astronauta.keymap")

      require("toggleterm").setup{
        open_mapping = "<c-t>",
        direction = "float",
      }

      keymap.nnoremap{"<c-t>", youxkei_toggleterm, silent = true}
    end}

    use{"karb94/neoscroll.nvim", config = function()
      require("neoscroll").setup({
        mappings = {"<C-u>", "<C-d>"},
      })
    end}

    use{"github/copilot.vim"}

    use{"VonHeikemen/fine-cmdline.nvim", disable = true, requires = "MunifTanjim/nui.nvim", config = function() -- disabled because it doesn't work with cmp-cmdline
      local keymap = require("astronauta.keymap")

      keymap.nnoremap{":", require("fine-cmdline").open}
    end}

    use{
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
        cmp.setup{
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
    end}

    use{"amiralies/vim-rescript"}

    use{"sgur/vim-textobj-parameter", requires = "kana/vim-textobj-user"}

    use{"kana/vim-textobj-entire", requires = "kana/vim-textobj-user"}

    use{"kana/vim-operator-replace", requires = "kana/vim-operator-user", config = function()
      local keymap = require("astronauta.keymap")

      keymap.map{"_", "<plug>(operator-replace)"}
    end}

    use{"haya14busa/vim-operator-flashy", config = function()
      local keymap = require("astronauta.keymap")

      keymap.map{"y", "<plug>(operator-flashy)"}
      keymap.nmap{"Y", "<plug>(operator-flashy)$"}
    end}

    use{"machakann/vim-sandwich", config = function()
      local keymap = require("astronauta.keymap")

      vim.g.sandwich_no_default_key_mappings = true
      vim.g.operator_sandwich_no_default_key_mappings = true
      vim.g["sandwich#recipes"] = vim.g["sandwich#default_recipes"]

      keymap.nmap{"<Leader>sd", "<plug>(operator-sandwich-delete)<plug>(operator-sandwich-release-count)<plug>(textobj-sandwich-query-a)"}
      keymap.nmap{"<Leader>sr", "<plug>(operator-sandwich-replace)<plug>(operator-sandwich-release-count)<plug>(textobj-sandwich-query-a)"}
      keymap.nmap{"<Leader>sdb", "<plug>(operator-sandwich-delete)<plug>(operator-sandwich-release-count)<plug>(textobj-sandwich-auto-a)"}
      keymap.nmap{"<Leader>srb", "<plug>(operator-sandwich-replace)<plug>(operator-sandwich-release-count)<plug>(textobj-sandwich-auto-a)"}
      keymap.nmap{"<Leader>sa", "<plug>(operator-sandwich-add)"}
      keymap.xmap{"<Leader>sa", "<plug>(operator-sandwich-add)"}
      keymap.omap{"<Leader>sa", "<plug>(operator-sandwich-g@)"}
      keymap.xmap{"<Leader>sd", "<plug>(operator-sandwich-delete)"}
      keymap.xmap{"<Leader>sr", "<plug>(operator-sandwich-replace)"}
    end}

    use{"b3nj5m1n/kommentary", config = function()
      local keymap = require("astronauta.keymap")

      vim.g.kommentary_create_default_mappings = false

      keymap.nmap{"<leader>cic", "<plug>kommentary_line_increase"}
      keymap.nmap{"<leader>ci", "<plug>kommentary_motion_increase"}
      keymap.xmap{"<leader>ci", "<plug>kommentary_visual_increase"}
      keymap.nmap{"<leader>cdc", "<plug>kommentary_line_decrease"}
      keymap.nmap{"<leader>cd", "<plug>kommentary_motion_decrease"}
      keymap.xmap{"<leader>cd", "<plug>kommentary_visual_decrease"}
    end}

    if packer_bootstrap then
      require('packer').sync()
    end
  end
}
