-- DAP user commands
local utils = require("debugging.utils")
local M = {}

function M.setup()
  vim.api.nvim_create_user_command("DapAttachDebugger", function()
    local dap = require("dap")
    -- Clean up existing sessions
    for _, session in pairs(dap.sessions()) do
      session:close()
    end
    -- Small delay then continue
    vim.defer_fn(function()
      dap.continue()
      utils.log("Attached to debugger", "success")
    end, 100)
  end, { desc = "Attach to running debugger" })

  vim.api.nvim_create_user_command("DapClearBreakpoints", function()
    require("dap").clear_breakpoints()
    utils.log("All breakpoints cleared", "info")
  end, { desc = "Clear all breakpoints" })

  vim.api.nvim_create_user_command("DapListSessions", function()
    local dap = require("dap")
    local sessions = dap.sessions()
    if #sessions == 0 then
      utils.log("No active debug sessions", "info")
      return
    end
    local lines = { "Active debug sessions:" }
    for i, session in ipairs(sessions) do
      local config = session.config or {}
      local name = config.name or "Session " .. i
      local stype = config.type or "unknown"
      table.insert(lines, i .. ": " .. name .. " (" .. stype .. ")")
    end
    utils.log(table.concat(lines, "\n"), "info")
  end, { desc = "List all active debug sessions" })

  vim.api.nvim_create_user_command("DapCloseAllSessions", function()
    local ok, dap = pcall(require, "dap")
    if not ok then
      utils.log("DAP not available", "error")
      return
    end
    local sessions = dap.sessions()
    if #sessions == 0 then
      utils.log("No active debug sessions", "info")
      return
    end
    for _, session in pairs(sessions) do
      pcall(function() session:close() end)
    end
    vim.defer_fn(function()
      if #dap.sessions() > 0 then
        utils.log("Warning: Some sessions did not close cleanly", "warn")
      else
        utils.log("Closed all debug sessions", "success")
      end
    end, 200)
  end, { desc = "Close all active debug sessions" })

  vim.api.nvim_create_user_command("DapResetState", function()
    local ok, dap = pcall(require, "dap")
    if not ok then
      utils.log("DAP not available", "error")
      return
    end
    local sessions = dap.sessions()
    if #sessions > 0 then
      utils.log("Terminating " .. #sessions .. " active debug sessions", "warn")
      for _, session in pairs(sessions) do
        pcall(function() session:close() end)
      end
    end
    vim.defer_fn(function()
      if type(dap.reset) == "function" then
        dap.reset()
      end
      package.loaded["dap"] = nil
      require("dap")
      utils.log("DAP state has been completely reset", "success")
    end, 300)
  end, { desc = "Reset DAP state completely (emergency use)" })
end

return M
