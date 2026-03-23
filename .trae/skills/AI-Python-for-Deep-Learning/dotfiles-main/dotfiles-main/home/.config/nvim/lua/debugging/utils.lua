-- DAP utilities: logging and safe operations
local M = {}

function M.safe_call(fn, ...)
  local status, result = pcall(fn, ...)
  return status and result or nil
end

function M.safe_trim(str)
  if not str then
    return ""
  end
  return vim.fn.trim(str)
end

function M.log(message, level)
  level = level or "info"
  local levels = {
    info = vim.log.levels.INFO,
    warn = vim.log.levels.WARN,
    error = vim.log.levels.ERROR,
    success = vim.log.levels.INFO,
  }
  vim.notify(message, levels[level] or vim.log.levels.INFO, { title = "DAP" })
end

return M
