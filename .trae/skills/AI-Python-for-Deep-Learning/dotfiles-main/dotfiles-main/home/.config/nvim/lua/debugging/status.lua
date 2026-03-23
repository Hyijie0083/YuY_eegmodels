-- DAP statusline integration
local M = {}

function M.get_status()
  local ok, dap = pcall(require, "dap")
  if not ok then
    return ""
  end
  local sessions = dap.sessions()
  if #sessions > 0 then
    return "🐞 " .. #sessions
  end
  return ""
end

return M
