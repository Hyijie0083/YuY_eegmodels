-- DAP module entry point
local M = {}

-- Re-export submodules
M.utils = require("debugging.utils")
M.paths = require("debugging.paths")
M.commands = require("debugging.commands")
M.keymaps = require("debugging.keymaps")
M.projects = require("debugging.projects")
M.ui = require("debugging.ui")
M.status = require("debugging.status")

-- Convenience exports
M.find_python_path = M.paths.find_python_path
M.find_ruby_path = M.paths.find_ruby_path
M.get_status = M.status.get_status
M.log = M.utils.log

-- Initialize all DAP components
function M.init()
  require("dap").set_log_level("TRACE")
  M.commands.setup()
  M.keymaps.setup()
  M.ui.setup()
  M.projects.load_project_config()
  M.log("Debug module initialized", "success")
end

return M
