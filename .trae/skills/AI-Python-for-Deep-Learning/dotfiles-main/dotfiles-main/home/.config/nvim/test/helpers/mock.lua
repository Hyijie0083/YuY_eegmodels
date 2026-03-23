-- Improved mock implementation for testing Neovim plugins
-- Avoids modifying global state
local M = {}

-- Track all created mocks for global reset
M._created_mocks = {}
M.print_messages = {}

-- Spy functionality to track function calls
function M.create_spy(func)
  local spy = {
    calls = {},
    call_count = 0,
    original_func = func or function() end
  }
  
  local spy_fn = function(...)
    local args = {...}
    spy.call_count = spy.call_count + 1
    table.insert(spy.calls, args)
    return spy.original_func(...)
  end
  
  -- Methods for verifying calls
  spy.was_called = function()
    return spy.call_count > 0
  end
  
  spy.was_called_with = function(...)
    local expected_args = {...}
    for _, call_args in ipairs(spy.calls) do
      local match = true
      for i, arg in ipairs(expected_args) do
        if call_args[i] ~= arg then
          match = false
          break
        end
      end
      if match then return true end
    end
    return false
  end
  
  spy.was_called_times = function(n)
    return spy.call_count == n
  end
  
  spy.reset = function()
    spy.calls = {}
    spy.call_count = 0
  end
  
  table.insert(M._created_mocks, spy)
  return spy_fn, spy
end

-- Create base mock environment
function M.create_env()
  -- Create a sandbox environment that doesn't affect global state
  local env = {}
  
  -- Initialize mocked Neovim API
  env.vim = {
    api = {
      nvim_create_user_command = function(name, fn, opts) end,
      nvim_create_autocmd = function(event, opts) end,
      nvim_get_current_buf = function() return 1 end,
      nvim_buf_get_lines = function(bufnr, start_line, end_line, strict_indexing) 
        return {} 
      end,
      nvim_buf_set_lines = function(bufnr, start_line, end_line, strict_indexing, lines) end,
      nvim_buf_set_text = function(bufnr, row, col, end_row, end_col, lines) end,
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
      glob = function(pattern, nosuf, list, alllinks)
        return {}
      end,
      globpath = function(path, pattern, nosuf, list, alllinks)
        return list and {} or ""
      end,
      finddir = function(name, path, count)
        return ""
      end,
      stdpath = function(what)
        if what == "config" then
          return "/Users/nategreen/.config/nvim"
        end
        return "/default/" .. what
      end,
    },
    keymap = {
      set_calls = {},
      set = function(mode, lhs, rhs, opts)
        table.insert(env.vim.keymap.set_calls, { mode = mode, lhs = lhs, rhs = rhs, opts = opts })
      end,
    },
    diagnostic = {
      severity = {
        ERROR = 1,
        WARN = 2,
        INFO = 3,
        HINT = 4,
      },
    },
    cmd = function(cmd) end,
    list_extend = function(list, items)
      for _, item in ipairs(items) do
        table.insert(list, item)
      end
      return list
    end,
    notify = function(msg, level, opts)
      table.insert(M.print_messages, {
        message = msg,
        level = level,
        opts = opts
      })
    end,
    log = {
      levels = {
        DEBUG = 0,
        INFO = 1,
        WARN = 2,
        ERROR = 3
      }
    },
    loop = {
      sleep = vim.loop.sleep -- Use real sleep function
    }
  }
  
  -- Add spy functionality to commonly used functions
  for name, fn in pairs(env.vim.api) do
    local spy_fn, spy_obj = M.create_spy(fn)
    env.vim.api[name] = spy_fn
    env.vim.api[name .. "_spy"] = spy_obj
  end
  
  for name, fn in pairs(env.vim.fn) do
    if type(fn) == "function" then
      local spy_fn, spy_obj = M.create_spy(fn)
      env.vim.fn[name] = spy_fn
      env.vim.fn[name .. "_spy"] = spy_obj
    end
  end
  
  -- Mock for dap (Debug Adapter Protocol)
  env.dap = {
    configurations = {},
    adapters = {},
    session = nil,
    sessions = function() return {} end,
    reset = function() end,
    continue = function() end,
    clear_breakpoints = function() end,
    toggle_breakpoint = function() end,
    step_over = function() end,
    step_into = function() end,
    step_out = function() end,
    listeners = {
      after = {
        event_initialized = {},
        event_terminated = {},
        disconnect = {}
      }
    },
    ui = {
      widgets = {
        hover = function() end,
      },
    },
  }
  
  -- Add spy functionality to dap functions
  for name, fn in pairs(env.dap) do
    if type(fn) == "function" then
      local spy_fn, spy_obj = M.create_spy(fn)
      env.dap[name] = spy_fn
      env.dap[name .. "_spy"] = spy_obj
    end
  end
  
  -- Mock for dapui
  env.dapui = {
    toggle = function() end,
    open = function() end,
    close = function() end,
  }
  
  -- Add spy functionality to dapui functions
  for name, fn in pairs(env.dapui) do
    local spy_fn, spy_obj = M.create_spy(fn)
    env.dapui[name] = spy_fn
    env.dapui[name .. "_spy"] = spy_obj
  end
  
  -- Mock for null-ls/none-ls
  env.null_ls = {
    builtins = {
      diagnostics = {
        mypy = {
          with = function(config)
            M.null_ls_configs = M.null_ls_configs or {}
            table.insert(M.null_ls_configs, {
              name = "mypy",
              config = config,
            })
            return "mypy_source"
          end,
        },
        ruff = {
          with = function(config)
            M.null_ls_configs = M.null_ls_configs or {}
            table.insert(M.null_ls_configs, {
              name = "ruff",
              config = config,
            })
            return "ruff_source"
          end,
        },
      },
      formatting = {
        black = {
          with = function(config)
            M.null_ls_configs = M.null_ls_configs or {}
            table.insert(M.null_ls_configs, {
              name = "black",
              config = config,
            })
            return "black_source"
          end,
        },
      },
    },
    register = function() end,
  }
  
  -- Mock print function 
  env.print = function(msg)
    print("[TEST] " .. tostring(msg)) -- Show in Neovim output but mark as test output
    table.insert(M.print_messages, tostring(msg))
  end
  
  -- Custom require function that intercepts specific modules
  env.require = function(module)
    if module == "dap" then
      return env.dap
    elseif module == "dapui" then
      return env.dapui
    elseif module == "null-ls" or module == "none-ls" then
      return env.null_ls
    else
      -- Pass through to real require for non-mocked modules
      return require(module)
    end
  end
  
  return env
end

-- Reset all mock state
function M.reset()
  M.print_messages = {}
  M.null_ls_configs = {}
  M.has_mypy_ini = false
  
  -- Reset all spy objects
  for _, spy in ipairs(M._created_mocks) do
    spy.reset()
  end
end

-- Load a module with mocked environment WITHOUT modifying global state
function M.load_with_sandbox(module_path)
  -- Create clean environment
  local env = M.create_env()
  
  -- Mark this as a test environment
  env._TEST_ENV = true
  
  -- Normalize the module path
  local actual_path = module_path
  if module_path:sub(1, 4) == "lua." then
    actual_path = module_path:sub(5)
  end
  
  -- First try to load the module source code
  local module_source = package.searchpath(actual_path, package.path)
  if not module_source then
    module_source = package.searchpath("lua." .. actual_path, package.path)
    if module_source then
      actual_path = "lua." .. actual_path
    else
      print("❌ Could not find module: " .. module_path)
      return nil
    end
  end
  
  -- Load the file content
  local f, err = loadfile(module_source)
  if not f then
    print("❌ Error loading module source: " .. tostring(err))
    return nil
  end
  
  -- Create a sandboxed environment with both our mocks and minimal _G access
  local sandbox = setmetatable({}, {
    __index = function(t, k)
      -- Allow test environment flag
      if k == "_TEST_ENV" then
        return true
      end
      
      -- First check if our mock environment has the key
      if env[k] ~= nil then
        return env[k]
      end
      -- Otherwise allow limited access to safe globals
      local safe_globals = {
        "string", "table", "math", "tonumber", "tostring", 
        "ipairs", "pairs", "select", "type", "next", "error",
        "pcall", "xpcall", "setmetatable", "getmetatable", "assert"
      }
      for _, global in ipairs(safe_globals) do
        if k == global then
          return _G[k]
        end
      end
      -- Provide minimal _G reference for compatibility
      if k == "_G" then
        return t
      end
      return nil
    end
  })
  
  -- Set the environment of the loaded function to our sandbox
  local status, result
  if setfenv then -- Lua 5.1
    status, result = pcall(setfenv(f, sandbox))
  else -- Lua 5.2+
    -- Define module upvalues manually
    local loader = function(...)
      local _ENV = sandbox
      return f(...)
    end
    status, result = pcall(loader)
  end
  
  if not status then
    print("❌ Error executing module: " .. tostring(result))
    return nil
  end
  
  return result
end

return M