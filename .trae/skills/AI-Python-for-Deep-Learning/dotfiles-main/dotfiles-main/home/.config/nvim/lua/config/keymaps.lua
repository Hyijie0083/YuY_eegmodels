-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Define keymaps in a structured way for consistency
local keymaps = {
  -- Buffer navigation
  {
    mode = "n",
    lhs = "<leader><Tab>",
    rhs = ":BufferLineCycleNext<CR>",
    opts = { silent = true, desc = "next buffer" },
  },
  {
    mode = "n",
    lhs = "<leader><S-Tab>",
    rhs = ":BufferLineCyclePrev<CR>",
    opts = { silent = true, desc = "previous buffer" },
  },

  -- LSP diagnostics
  {
    mode = "n",
    lhs = "<Tab>",
    rhs = vim.diagnostic.open_float,
    opts = { desc = "show diagnostic in floating window" },
  },
  { mode = "n", lhs = "K", rhs = vim.lsp.buf.hover, opts = { desc = "show hover documentation" } },
}

-- Buffer number quick access
for i = 1, 9 do
  table.insert(keymaps, {
    mode = "n",
    lhs = "<leader>" .. i,
    rhs = ":BufferLineGoToBuffer " .. i .. "<CR>",
    opts = { silent = true, desc = "go to buffer " .. i },
  })
end

-- Register all keybindings
for _, binding in ipairs(keymaps) do
  vim.keymap.set(binding.mode, binding.lhs, binding.rhs, binding.opts)
end
