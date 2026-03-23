return {
  {
    "akinsho/bufferline.nvim",
    opts = {
      options = {
        diagnostics = "nvim_lsp",
        always_show_bufferline = true,
        -- separator_style = "slant",
        show_buffer_close_icons = true,
        show_close_icon = true,
        show_tab_indicators = true,
        show_duplicate_prefix = false,
        tab_size = 21,
        numbers = "ordinal",
        max_name_length = 30, -- Truncate long filenames
        name_formatter = function(buf) -- buf contains:
          return buf.name -- Show full path on hover
        end,
        height = 4,
        padding = 2,
        enforce_regular_tabs = true,
      },
    },
  },
}
