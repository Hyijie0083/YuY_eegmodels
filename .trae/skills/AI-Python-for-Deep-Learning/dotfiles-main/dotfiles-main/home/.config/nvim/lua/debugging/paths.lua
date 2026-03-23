-- DAP path detection for Python and Ruby
local M = {}

-- Find Python executable path
function M.find_python_path()
  -- Method 1: Try pyenv which python
  local pyenv_path = vim.fn.trim(vim.fn.system("pyenv which python 2>/dev/null"))
  if pyenv_path ~= "" and vim.fn.executable(pyenv_path) == 1 then
    return pyenv_path
  end

  -- Method 2: Try direct path to current pyenv Python
  local pyenv_root = os.getenv("PYENV_ROOT") or vim.fn.expand("~/.pyenv")
  local version_path = pyenv_root .. "/version"
  if vim.fn.filereadable(version_path) == 1 then
    local current_version = vim.fn.trim(vim.fn.readfile(version_path)[1])
    local direct_path = pyenv_root .. "/versions/" .. current_version .. "/bin/python"
    if vim.fn.executable(direct_path) == 1 then
      return direct_path
    end
  end

  -- Method 3: Try system Python3
  local sys_path = vim.fn.exepath("python3")
  if sys_path ~= "" then
    return sys_path
  end

  -- Method 4: Try system Python
  sys_path = vim.fn.exepath("python")
  if sys_path ~= "" then
    return sys_path
  end

  -- Fallback
  return "/usr/bin/python3"
end

-- Find Ruby executable path
function M.find_ruby_path()
  -- Check RVM first
  local handle = io.popen("rvm current 2>/dev/null")
  if handle then
    local result = handle:read("*a"):gsub("%s+$", "")
    handle:close()
    if result ~= "" then
      local rvm_ruby = os.getenv("HOME") .. "/.rvm/rubies/" .. result .. "/bin/ruby"
      if vim.fn.filereadable(rvm_ruby) == 1 then
        return rvm_ruby
      end
    end
  end

  -- Check RBENV
  local rbenv_root = os.getenv("RBENV_ROOT") or (os.getenv("HOME") .. "/.rbenv")
  if vim.fn.isdirectory(rbenv_root) == 1 then
    local version_path = rbenv_root .. "/version"
    if vim.fn.filereadable(version_path) == 1 then
      local version_file = io.open(version_path, "r")
      if version_file then
        local ruby_version = version_file:read("*line"):gsub("%s+$", "")
        version_file:close()
        local ruby_path = rbenv_root .. "/versions/" .. ruby_version .. "/bin/ruby"
        if vim.fn.filereadable(ruby_path) == 1 then
          return ruby_path
        end
      end
    end
  end

  -- Fall back to system ruby
  return vim.fn.exepath("ruby")
end

return M
