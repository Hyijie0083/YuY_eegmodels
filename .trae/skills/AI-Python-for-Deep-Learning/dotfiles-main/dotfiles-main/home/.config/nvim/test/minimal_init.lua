-- Minimal init for testing
vim.cmd('set rtp+=' .. vim.fn.getcwd())
-- Add test directory to package.path
package.path = "/Users/nategreen/.config/nvim/test/?.lua;" .. 
               "/Users/nategreen/.config/nvim/test/?/init.lua;" .. 
               "/Users/nategreen/.config/nvim/test/helpers/?.lua;" ..
               package.path
vim.cmd('set noswapfile')
vim.cmd('set nobackup')
vim.cmd('set nowritebackup')
-- Set a generous timeout for CI environments
vim.o.timeout = true
vim.o.timeoutlen = 5000
