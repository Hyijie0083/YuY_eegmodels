return {
  "neovim/nvim-lspconfig",
  opts = function(_, opts)
    -- Extend the existing opts
    opts.diagnostics = {
      virtual_text = false,
      underline = true,
      update_in_insert = false,
      severity_sort = true,
      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = "✘",
          [vim.diagnostic.severity.WARN] = "▲",
          [vim.diagnostic.severity.INFO] = "ℹ",
          [vim.diagnostic.severity.HINT] = "⚑",
        },
      },
    }

    return opts
  end,
}
