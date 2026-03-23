-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- statusline
vim.g.gitblame_display_virtual_text = 0 -- Disable virtual text

-- Debug configurations are loaded lazily
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  callback = function()
    require("debugging").init()
  end,
})
