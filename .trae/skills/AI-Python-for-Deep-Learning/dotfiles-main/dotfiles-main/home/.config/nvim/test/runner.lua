-- Simple, non-coroutine test runner for Neovim plugin tests
local M = {}

-- Track test results
M.results = {
  passed = {},
  failed = {},
  skipped = {}
}

-- Setup package path to include all necessary directories
local nvim_dir = vim.fn.stdpath("config") .. "/"
package.path = nvim_dir .. "lua/?.lua;" .. 
               nvim_dir .. "lua/?/init.lua;" .. 
               nvim_dir .. "test/?.lua;" .. 
               nvim_dir .. "test/helpers/?.lua;" ..
               package.path

-- Safely require a module
function M.safe_require(module_name)
  print("Loading module: " .. module_name)
  local status, module = pcall(require, module_name)
  if not status then
    print("❌ Failed to load module: " .. module_name)
    print("Error: " .. module)
    return nil
  end
  return module
end

-- Run a single test module
function M.run_module(module_name)
  print("\n==== Running test module: " .. module_name .. " ====")
  
  local module = M.safe_require(module_name)
  if not module then
    table.insert(M.results.failed, module_name .. " (failed to load)")
    return false
  end
  
  -- No tests defined
  if not module.tests then
    print("⚠️ No tests found in module: " .. module_name)
    table.insert(M.results.skipped, module_name)
    return true
  end
  
  local module_success = true
  local module_tests_run = 0
  local module_tests_passed = 0
  
  -- Run module setup if available
  if type(module.setup) == "function" then
    print("Running module setup...")
    local setup_success, setup_err = pcall(module.setup)
    if not setup_success then
      print("❌ Module setup failed: " .. tostring(setup_err))
      table.insert(M.results.failed, module_name .. ".setup")
      return false
    end
  end
  
  -- Run each test in the module
  for test_name, test_fn in pairs(module.tests) do
    module_tests_run = module_tests_run + 1
    local test_full_name = module_name .. "." .. test_name
    print("Running test: " .. test_name)
    
    -- Run before_each if available
    if type(module.before_each) == "function" then
      pcall(module.before_each)
    end
    
    -- Run the actual test
    local test_start = os.time()
    local success, err = pcall(test_fn)
    local duration = os.time() - test_start
    
    -- Run after_each if available
    if type(module.after_each) == "function" then
      pcall(module.after_each)
    end
    
    -- Track results
    if success then
      print(string.format("✅ %s (%.2fs)", test_name, duration))
      table.insert(M.results.passed, test_full_name)
      module_tests_passed = module_tests_passed + 1
    else
      print(string.format("❌ %s: %s (%.2fs)", test_name, tostring(err), duration))
      table.insert(M.results.failed, test_full_name)
      module_success = false
    end
    
    -- Ensure proper cleanup between tests by yielding to event loop
    vim.loop.sleep(1)
  end
  
  -- Run module teardown if available
  if type(module.teardown) == "function" then
    print("Running module teardown...")
    pcall(module.teardown)
  end
  
  -- Print module summary
  print(string.format("\nModule results: %d/%d tests passed", 
    module_tests_passed, module_tests_run))
  
  return module_success
end

-- Run all specified test modules
function M.run_all(modules)
  local start_time = os.time()
  local all_passed = true
  
  -- Default test modules if none specified
  modules = modules or {
    "test.simple_test",
    "test.dap_projects_test",
    "test.python_lsp_test"
  }
  
  print("Running " .. #modules .. " test modules...")
  
  for _, module_name in ipairs(modules) do
    local module_success = M.run_module(module_name)
    all_passed = all_passed and module_success
  end
  
  -- Print summary
  local total_duration = os.time() - start_time
  print("\n==== Test Summary ====")
  print(string.format("Duration: %.2f seconds", total_duration))
  print("Passed: " .. #M.results.passed)
  print("Failed: " .. #M.results.failed)
  print("Skipped: " .. #M.results.skipped)
  
  if #M.results.failed > 0 then
    print("\nFailed tests:")
    for _, test_name in ipairs(M.results.failed) do
      print("  - " .. test_name)
    end
  end
  
  if all_passed then
    print("\n✅ All tests passed!")
    return true
  else
    print("\n❌ Some tests failed!")
    return false
  end
end

-- Run the tests directly
local success = M.run_all()

-- Exit with appropriate code
if success then
  vim.cmd("q!")  -- Exit with success (0)
else
  vim.cmd("cq!") -- Exit with error (>0)
end

return M