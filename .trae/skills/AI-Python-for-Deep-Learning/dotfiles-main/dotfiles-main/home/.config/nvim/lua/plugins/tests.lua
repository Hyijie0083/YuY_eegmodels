-- Neotest configuration for Python
return {
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "antoinemadec/fixcursorhold.nvim",
    "nvim-treesitter/nvim-treesitter",
    "nvim-neotest/nvim-nio",
    "mfussenegger/nvim-dap",
    "rcarriga/nvim-dap-ui",
    "nvim-neotest/neotest-python",
    "mfussenegger/nvim-dap-python",
  },
  config = function()
    local neotest = require("neotest")
    local paths = require("debugging.paths")

    -- Get Python path using shared utility
    local python_path = paths.find_python_path()
    vim.notify("DAP using Python: " .. python_path, vim.log.levels.INFO)

    -- Setup Python DAP
    local status, err = pcall(function()
      require("dap-python").setup(python_path)
    end)
    if not status then
      vim.notify("Error setting up Python DAP: " .. tostring(err), vim.log.levels.ERROR)
    end

    -- Python test config
    local python_config = {
      args = { "--verbose", "-vv" },
      env = { pytest_addopts = "--sugar-no-header" },
      runner = "pytest",
      root_patterns = { "pyproject.toml", "setup.cfg", "setup.py", "pytest.ini" },
      dap = { justmycode = false },
    }

    -- Neotest setup
    neotest.setup({
      adapters = {
        require("neotest-python")({
          args = python_config.args,
          env = python_config.env,
          runner = python_config.runner,
          python = python_path,
          root_patterns = python_config.root_patterns,
          dap = python_config.dap,
        }),
      },
      icons = {
        passed = "●",
        failed = "●",
        running = "◍",
        skipped = "○",
      },
      highlights = {
        passed = "NeotestPassed",
        failed = "NeotestFailed",
        running = "NeotestRunning",
        skipped = "NeotestSkipped",
      },
      output = { open_on_run = false },
    })

    -- Highlight groups
    vim.cmd([[
      highlight NeotestPassed ctermfg=green guifg=#00ff00
      highlight NeotestFailed ctermfg=red guifg=#ff0000
      highlight NeotestRunning ctermfg=yellow guifg=#ffff00
      highlight NeotestSkipped ctermfg=gray guifg=#808080
    ]])

    -- Test keymaps
    vim.keymap.set("n", "<leader>tt", function() neotest.run.run() end, { desc = "run nearest test" })
    vim.keymap.set("n", "<leader>tf", function() neotest.run.run(vim.fn.expand("%")) end, { desc = "run test file" })
    vim.keymap.set("n", "<leader>ts", function() neotest.summary.toggle() end, { desc = "toggle test summary" })
    vim.keymap.set("n", "<leader>to", function() neotest.output.open() end, { desc = "show test output" })
    vim.keymap.set("n", "<leader>tp", function() neotest.output_panel.toggle() end, { desc = "toggle test output panel" })
    vim.keymap.set("n", "<leader>tF", function()
      neotest.run.run(vim.fn.getcwd())
      neotest.output_panel.toggle()
    end, { desc = "run all tests in project" })
    vim.keymap.set("n", "<leader>td", function() neotest.run.run({ strategy = "dap" }) end, { desc = "debug nearest test" })
  end,
}
