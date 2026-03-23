return {
  "VonHeikemen/searchbox.nvim",
  dependencies = {
    "MunifTanjim/nui.nvim",
  },
  config = function()
    vim.keymap.set("n", "/", function()
      require("searchbox").match_all({
        clear_matches = false,
        show_matches = true,
      })
    end, {})
  end,
}
