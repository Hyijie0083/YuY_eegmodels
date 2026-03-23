-- Mock implementation for testing Neovim plugins
local mock = {}

-- Initialize data structures
mock.print_messages = {}
mock.vim = {
  api = {
    nvim_create_user_command = function(name, fn, opts) end,
    nvim_create_autocmd = function(event, opts) end,
  },
  fn = {
    getcwd = function()
      return "/default/path"
    end,
    expand = function(path)
      return path
    end,
    filereadable = function(path)
      return 0
    end,
  },
  keymap = {
    set_calls = {},
    set = function(mode, lhs, rhs, opts)
      table.insert(mock.vim.keymap.set_calls, { mode = mode, lhs = lhs, rhs = rhs, opts = opts })
    end,
  },
  diagnostic = {
    severity = {
      ERROR = 1,
    },
  },
  cmd = function(cmd) end,
  list_extend = function(list, items)
    for _, item in ipairs(items) do
      table.insert(list, item)
    end
    return list
  end,
}

mock.dap = {
  configurations = {},
  continue = function() end,
  clear_breakpoints = function() end,
  toggle_breakpoint = function() end,
  step_over = function() end,
  step_into = function() end,
  step_out = function() end,
  ui = {
    widgets = {
      hover = function() end,
    },
  },
}

mock.dapui = {
  toggle = function() end,
}

-- Reset mock state
function mock.reset()
  mock.dap.configurations = {}
  mock.vim.keymap.set_calls = {}
  mock.print_messages = {}
  mock.null_ls_configs = {}
  mock.has_mypy_ini = false
end

-- Load a module with mocked environment
function mock.load_with_env(module_path, env)
  -- Save original globals
  local orig_vim = _G.vim
  local orig_require = _G.require
  local orig_print = _G.print

  -- Set test environment
  _G.vim = env.vim
  _G.require = env.require
  _G.print = function(msg)
    table.insert(mock.print_messages, tostring(msg))
  end

  -- Fix the module path - normalize path to handle both "lua." prefix and direct paths
  local actual_path = module_path
  if module_path:sub(1, 4) == "lua." then
    actual_path = module_path:sub(5)
  end

  -- Also handle paths without the lua prefix that need it
  if not package.loaded[actual_path] and package.loaded["lua." .. actual_path] then
    actual_path = "lua." .. actual_path
  end

  -- Load the module
  package.loaded[actual_path] = nil
  local status, module = pcall(require, actual_path)

  -- Restore globals
  _G.vim = orig_vim
  _G.require = orig_require
  _G.print = orig_print

  if not status then
    print("Error loading module: " .. module)
    return nil
  end

  return module
end

return mock
