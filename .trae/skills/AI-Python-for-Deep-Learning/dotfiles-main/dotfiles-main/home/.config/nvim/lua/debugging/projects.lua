-- DAP project-specific configurations
local utils = require("debugging.utils")
local M = {}

M.configs = {
  ["commercial-api"] = {
    type = "python",
    request = "attach",
    name = "Commercial API",
    connect = { host = "localhost", port = 5678 },
    pathMappings = {
      {
        localRoot = function()
          local current_dir = vim.fn.getcwd()
          if current_dir:find("commercial-api", 1, true) then
            return current_dir
          end
          return vim.fn.expand("~/Documents/Development/jv-dev-kit/services/commercial-api")
        end,
        remoteRoot = "/app",
      },
    },
    justMyCode = false,
  },

  ["platform-api"] = {
    type = "ruby",
    request = "attach",
    name = "Platform API Docker",
    connect = { host = "localhost", port = 38698 },
    localfsMap = "/home/app:/Users/nategreen/Documents/Development/jv-dev-kit/services/platform-api",
  },
}

-- State
M.initialized = false
M.last_loaded_dir = nil

function M.find_matching_config(directory)
  local directory_lower = directory:lower()
  for pattern, config in pairs(M.configs) do
    if directory_lower:find(pattern:lower(), 1, true) then
      return config, pattern
    end
  end
  return nil, nil
end

function M.load_project_config()
  local current_dir = vim.fn.getcwd()

  if M.initialized and M.last_loaded_dir == current_dir then
    return true
  end

  utils.log("Current directory: " .. current_dir, "info")

  local matched_config, matched_pattern = M.find_matching_config(current_dir)
  if matched_config then
    local project_type = matched_config.type
    require("dap").configurations[project_type] = { matched_config }
    utils.log("Loaded DAP config for: " .. matched_pattern, "success")
    M.initialized = true
    M.last_loaded_dir = current_dir
    return true
  end

  utils.log("No matching DAP config found for this directory", "warn")
  return false
end

return M
