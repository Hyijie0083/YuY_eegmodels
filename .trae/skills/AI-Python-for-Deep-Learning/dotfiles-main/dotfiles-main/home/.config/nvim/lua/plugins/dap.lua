-- DAP plugin configuration
return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
    },
    config = function()
      local dap = require("dap")
      local paths = require("debugging.paths")

      -- Ruby DAP adapter configuration
      dap.adapters.ruby = {
        type = "server",
        host = "127.0.0.1",
        port = 38698,
        executable = {
          command = "bundle",
          args = { "exec", "rdbg", "-n", "--open", "--port", "38698" },
        },
        options = {
          source_filetype = "ruby",
          initialize_timeout_sec = 20,
        },
      }

      dap.configurations.ruby = {
        {
          type = "ruby",
          request = "attach",
          name = "Debug Ruby (Default)",
          port = 38698,
          localfs = true,
        },
      }

      -- Log Ruby path
      local ruby_path = paths.find_ruby_path()
      vim.notify("DAP Ruby using: " .. ruby_path, vim.log.levels.INFO)
    end,
  },
}
