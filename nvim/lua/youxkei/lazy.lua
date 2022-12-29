local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--single-branch",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
end
vim.opt.runtimepath:prepend(lazypath)

vim.api.nvim_create_autocmd("User", {
  pattern = "LazySync",
  callback = function()
    local lazy = require("lazy")
    lazy.load({ plugins = lazy.plugins() })
  end,
})

require("lazy").setup("youxkei.plugins", {
  defaults = {
    lazy = false,
  },
  checker = {
    enabled = true,
  },
  rtp = {
      reset = true,
      disabled_plugins = {
        "gzip",
        "matchit",
        "matchparen",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
})
