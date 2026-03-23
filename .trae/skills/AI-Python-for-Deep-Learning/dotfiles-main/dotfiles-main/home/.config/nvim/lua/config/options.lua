-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Disable relative line numbers
vim.opt.relativenumber = false

-- Keep absolute line numbers enabled, if desired
vim.opt.number = true

vim.opt.showtabline = 1

-- mouse behavior
vim.o.mousemoveevent = true

-- Auto-reload files when changed externally
vim.o.autoread = true
