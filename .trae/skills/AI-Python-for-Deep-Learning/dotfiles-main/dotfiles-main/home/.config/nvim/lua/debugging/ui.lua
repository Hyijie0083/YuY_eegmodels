-- DAP UI configuration
local M = {}

function M.setup()
  local dap = require("dap")
  local dapui = require("dapui")

  -- DAP UI layout
  dapui.setup({
    layouts = {
      {
        elements = {
          { id = "scopes", size = 0.25 },
          { id = "breakpoints", size = 0.25 },
          { id = "stacks", size = 0.25 },
          { id = "watches", size = 0.25 },
        },
        size = 40,
        position = "left",
      },
      {
        elements = {
          { id = "repl", size = 0.5 },
          { id = "console", size = 0.5 },
        },
        size = 10,
        position = "bottom",
      },
    },
  })

  -- Breakpoint styling
  vim.api.nvim_set_hl(0, "DapBreakpoint", { fg = "#e51a4c" })
  vim.fn.sign_define("DapBreakpoint", {
    text = "◉",
    texthl = "DapBreakpoint",
    linehl = "",
    numhl = "",
  })
  vim.api.nvim_set_hl(0, "DapBreakpointCondition", { fg = "#f5c747" })
  vim.fn.sign_define("DapBreakpointCondition", {
    text = "◈",
    texthl = "DapBreakpointCondition",
    linehl = "",
    numhl = "",
  })

  -- Window reuse logic for debugging
  dap.listeners.after.event_stopped["reuse_windows"] = function(_, body)
    local filename = body.frame and body.frame.source and body.frame.source.path
    if filename then
      local current_win = vim.api.nvim_get_current_win()
      local available_wins = {}
      for _, win in pairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        local buf_name = vim.api.nvim_buf_get_name(buf)
        if
          not buf_name:match("_test%.py$")
          and not buf_name:match("test_.*%.py$")
          and not buf_name:match("_spec%.rb$")
          and not buf_name:match("_test%.rb$")
        then
          table.insert(available_wins, win)
        end
      end
      if #available_wins > 0 then
        vim.api.nvim_set_current_win(available_wins[1])
        vim.cmd("edit " .. filename)
        vim.api.nvim_set_current_win(current_win)
      end
    end
  end
end

return M
