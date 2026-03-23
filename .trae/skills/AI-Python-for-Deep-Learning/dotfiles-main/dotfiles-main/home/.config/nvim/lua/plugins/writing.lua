return {
  {
    "folke/zen-mode.nvim",
    dependencies = {
      "folke/twilight.nvim",
    },
    config = function()
      -- Zen-mode setup
      require("zen-mode").setup({
        window = {
          backdrop = 0.95,
          width = 80,
          height = 1,
          options = {
            signcolumn = "no",
            number = false,
            relativenumber = false,
            cursorline = false,
            cursorcolumn = false,
            foldcolumn = "0",
            list = false,
            wrap = true,
            linebreak = true,
          },
        },
        plugins = {
          options = {
            enabled = true,
            ruler = false,
            showcmd = false,
          },
          twilight = { enabled = true },
          gitsigns = { enabled = false },
        },
      })

      -- Set textwidth when entering zen mode
      vim.api.nvim_create_autocmd("User", {
        pattern = "ZenMode",
        callback = function()
          if require("zen-mode.view").is_open() then
            vim.opt_local.textwidth = 80
          end
        end,
      })

      vim.keymap.set("n", "<leader>z", "<cmd>ZenMode<cr>", { desc = "Toggle Zen Mode" })
    end,
  },
}
