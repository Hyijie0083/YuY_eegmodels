return {
  "mason-org/mason.nvim",
  opts = function(_, opts)
    opts.ensure_installed = opts.ensure_installed or {}
    vim.list_extend(opts.ensure_installed, {
      -- Python
      "debugpy",
      "mypy",
      "black",
      "ruff",
    })
    return opts
  end,
}
