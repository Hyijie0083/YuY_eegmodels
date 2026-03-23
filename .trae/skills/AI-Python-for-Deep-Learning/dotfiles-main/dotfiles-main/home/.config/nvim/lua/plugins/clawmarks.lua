return {
  "mrilikecoding/clawmarks.nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim",
    "nvim-lua/plenary.nvim",
  },
  config = function()
    require("clawmarks").setup()
    require("telescope").load_extension("clawmarks")
  end,
  keys = {
    { "<leader>ct", "<cmd>Telescope clawmarks threads<cr>", desc = "Clawmarks threads" },
    { "<leader>cm", "<cmd>Telescope clawmarks marks<cr>", desc = "Clawmarks marks" },
    { "<leader>cg", "<cmd>Telescope clawmarks tags<cr>", desc = "Clawmarks tags" },
  },
}
