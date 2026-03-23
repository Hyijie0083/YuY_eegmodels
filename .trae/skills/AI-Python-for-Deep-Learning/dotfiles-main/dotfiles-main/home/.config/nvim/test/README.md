# Neovim Configuration Testing

This directory contains tests for the Neovim configuration, focusing on more complex parts of the setup like DAP (Debug Adapter Protocol) configuration and LSP (Language Server Protocol) integration.

## Testing Philosophy

The tests in this directory are designed to:

1. Verify that complex configuration logic works as expected
2. Provide a safety net for refactoring
3. Document how the configuration is supposed to work

## Test Structure

- `runner.lua`: A lightweight test runner that doesn't rely on coroutines
- `helpers/mock.lua`: Mock implementation that avoids modifying global state
- `*_test.lua`: Test modules for different parts of the configuration
- `run.sh`: Shell script to run tests in headless Neovim

## Writing Tests

Tests are structured as Lua modules with the following format:

```lua
local mock = require("test.helpers.mock")
local M = {}

-- Optional module setup function
function M.setup()
  -- Setup code that runs once before all tests in this module
end

-- Optional module teardown function
function M.teardown()
  -- Cleanup code that runs once after all tests in this module
end

-- Optional setup for each test
function M.before_each()
  mock.reset()
  -- Additional setup before each test
end

-- Optional teardown for each test
function M.after_each()
  -- Cleanup after each test
end

-- Test cases
M.tests = {
  test_some_functionality = function()
    -- Test code here
    assert(true, "This should be true")
  end,
  
  test_another_thing = function()
    -- Another test
    assert(1 + 1 == 2, "Basic math should work")
  end
}

return M
```

## Mocking

The `mock` module provides a clean way to mock Neovim APIs without modifying global state:

```lua
local mock = require("test.helpers.mock")

-- Load a module with mocked environment
local my_module = mock.load_with_sandbox("my_module")

-- Reset mock state between tests
mock.reset()
```

## Running Tests

Run tests using Make from the Neovim config directory:

```bash
make test            # Run all tests in headless mode
make test-headless   # Same as above
make test-interactive # Run tests in interactive mode (useful for debugging)
```

Or using the shell script directly:

```bash
./test/run.sh
```

Or directly with Neovim:

```bash
nvim --headless --noplugin -u test/minimal_init.lua -c "luafile test/runner.lua"
```

## Test Coverage

Current test coverage includes:

- DAP Projects Configuration (`dap_projects.lua`)
- Python LSP Configuration (`plugins/python.lua`)

## Best Practices

1. Keep tests focused on specific functionality
2. Avoid testing Neovim internals - focus on your custom code
3. Use assertions to verify expected behavior
4. Mock external dependencies
5. Keep tests isolated from each other
6. Use descriptive test names

## Timeouts and Performance

The improved testing framework avoids using coroutines and busy-wait loops, which:

1. Prevents CPU hogging during test execution
2. Eliminates timeout issues in headless mode
3. Makes tests more reliable and consistent
4. Significantly improves test execution speed