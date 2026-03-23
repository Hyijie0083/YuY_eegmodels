return {
  {
    "RRethy/base16-nvim",
    config = function()
      vim.cmd("colorscheme base16-ocean")
    end,
  },
  -- Enable live preview when browsing colorschemes
  {
    "nvim-telescope/telescope.nvim",
    opts = {
      pickers = {
        colorscheme = {
          enable_preview = true,
        },
      },
    },
  },
  -- Colorful window separation
  {
    "nvim-zh/colorful-winsep.nvim",
    config = true,
    event = { "WinLeave" },
  },
}
