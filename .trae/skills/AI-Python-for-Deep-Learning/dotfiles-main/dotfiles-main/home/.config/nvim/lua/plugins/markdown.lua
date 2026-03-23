return {
  "MeanderingProgrammer/render-markdown.nvim",
  ft = "markdown", -- Only load for markdown files
  dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-mini/mini.nvim" },
  ---@module 'render-markdown'
  ---@type render.md.UserConfig
  opts = {},
}
