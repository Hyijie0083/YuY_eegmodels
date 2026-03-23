-- Test runner for Neovim plugins
local test_results = {}

-- Safely require a module
local function safe_require(module_name)
  -- Get absolute path to nvim config directory
  local nvim_dir = "/Users/nategreen/.config/nvim/"

  -- Setup package path to include all necessary directories
  package.path = nvim_dir .. "lua/?.lua;" .. nvim_dir .. "lua/?/init.lua;" .. nvim_dir .. "test/?.lua;" .. package.path

  print("Searching for module: " .. module_name)

  local status, module = pcall(require, module_name)
  if not status then
    print("❌ Failed to load module: " .. module_name)
    print("Error: " .. module)
    return nil
  end
  return module
end

-- Run test with timeout protection
local function run_test_with_timeout(test_module, test_name)
  if not test_module then
    test_results[test_name] = false
    return false
  end

  -- Set a timeout to prevent hanging
  local success, result = pcall(function()
    -- Create a coroutine for the test
    local co = coroutine.create(function()
      return test_module.run()
    end)

    local timeout_seconds = 30
    local start_time = os.time()

    -- Resume the coroutine until it's done or times out
    while coroutine.status(co) ~= "dead" do
      local resume_success, resume_result = coroutine.resume(co)

      if not resume_success then
        print("Error in test execution: " .. tostring(resume_result))
        return false
      end

      if os.time() - start_time > timeout_seconds then
        print("⚠️ Tests timed out after " .. timeout_seconds .. " seconds")
        return false
      end

      -- Small delay to prevent CPU hogging while yielding control to the event loop
      vim.loop.sleep(10)  -- Sleep for 10ms, non-blocking
    end

    -- If the coroutine is already dead, we don't need to resume it again
    if coroutine.status(co) == "dead" then
      -- The last resume inside the loop already got the result
      return true
    else
      -- Get the final result from the coroutine
      local success, final_result = coroutine.resume(co)
      return success and final_result
    end
  end)

  if success then
    test_results[test_name] = result
  else
    print("❌ Test execution failed: " .. tostring(result))
    test_results[test_name] = false
  end

  return test_results[test_name]
end

-- Run DAP Projects tests
local dap_projects_test = safe_require("test.dap_projects_test")
run_test_with_timeout(dap_projects_test, "dap_projects")

-- Run Python LSP tests
local python_lsp_test = safe_require("test.python_lsp_test")
run_test_with_timeout(python_lsp_test, "python_lsp")

-- Print overall results
local all_passed = true
for module, passed in pairs(test_results) do
  if not passed then
    all_passed = false
    break
  end
end

if all_passed then
  print("\n✅ All tests passed!")
else
  print("\n❌ Some tests failed!")
end

-- Always exit explicitly
if all_passed then
  os.exit(0) -- Success exit code
else
  os.exit(1) -- Error exit code
end
