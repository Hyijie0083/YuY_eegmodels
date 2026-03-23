return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    local ok_blame, git_blame = pcall(require, "gitblame")
    local ok_dap, dap_status = pcall(require, "debugging.status")

    local sections = {
      lualine_a = { "mode" },
      lualine_b = { "branch", "diagnostics" },
      lualine_c = {},
      lualine_x = { { "filename", path = 1 } },
      lualine_y = { "progress" },
      lualine_z = { "location" },
    }

    -- Add git blame if available
    if ok_blame then
      sections.lualine_c = {
        { git_blame.get_current_blame_text, cond = git_blame.is_blame_text_available },
      }
    end

    -- Add DAP status if available
    if ok_dap then
      table.insert(sections.lualine_x, 1, { dap_status.get_status })
    end

    return { sections = sections }
  end,
}
