-- DAP keybindings
local utils = require("debugging.utils")
local M = {}

function M.setup()
  local keybindings = {
    { "<Leader>da", function() vim.cmd("DapAttachDebugger") end, "debug: attach to debugger" },
    { "<Leader>dl", function() vim.cmd("DapListSessions") end, "debug: list sessions" },
    { "<Leader>dC", function() vim.cmd("DapCloseAllSessions") end, "debug: close all sessions" },
    { "<Leader>dR", function() vim.cmd("DapResetState") end, "debug: reset DAP state" },
    { "<Leader>dc", function() require("dap").continue() end, "debug: continue" },
    { "<Leader>ds", function() require("dap").step_over() end, "debug: step over" },
    { "<Leader>di", function() require("dap").step_into() end, "debug: step into" },
    { "<Leader>do", function() require("dap").step_out() end, "debug: step out" },
    { "<Leader>db", function() require("dap").toggle_breakpoint() end, "debug: toggle breakpoint" },
    { "<Leader>dx", function()
      require("dap").clear_breakpoints()
      utils.log("All breakpoints cleared", "info")
    end, "debug: clear all breakpoints" },
    { "<Leader>du", function() require("dapui").toggle() end, "debug: toggle ui" },
    { "<Leader>de", function() require("dap.ui.widgets").hover() end, "debug: evaluate expression" },
  }

  for _, binding in ipairs(keybindings) do
    vim.keymap.set("n", binding[1], binding[2], { desc = binding[3] })
  end
end

return M
