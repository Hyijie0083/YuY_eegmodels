#!/bin/bash
# Simple test runner for Neovim configuration

# Get the directory of this script
SCRIPT_DIR=$(dirname "$(realpath "$0")")
NVIM_DIR=$(dirname "$SCRIPT_DIR")

# Echo with color
function echo_color() {
  local color=$1
  local message=$2
  case $color in
    "red") echo -e "\033[0;31m$message\033[0m" ;;
    "green") echo -e "\033[0;32m$message\033[0m" ;;
    "yellow") echo -e "\033[0;33m$message\033[0m" ;;
    "blue") echo -e "\033[0;34m$message\033[0m" ;;
    *) echo "$message" ;;
  esac
}

# Create minimal init file
cat > "$SCRIPT_DIR/minimal_init.lua" << EOF
-- Minimal init for testing
vim.cmd('set rtp+=' .. vim.fn.getcwd())
-- Add test directory to package.path
package.path = "$SCRIPT_DIR/?.lua;" .. 
               "$SCRIPT_DIR/?/init.lua;" .. 
               "$SCRIPT_DIR/helpers/?.lua;" ..
               package.path
vim.cmd('set noswapfile')
vim.cmd('set nobackup')
vim.cmd('set nowritebackup')
-- Set a generous timeout for CI environments
vim.o.timeout = true
vim.o.timeoutlen = 5000
EOF

# Header
echo_color "blue" "==============================================="
echo_color "blue" "   Running tests with simplified framework"
echo_color "blue" "==============================================="
echo ""

# Run with simplified runner
echo_color "blue" "Running tests with simplified runner..."
nvim --headless --noplugin -u "$SCRIPT_DIR/minimal_init.lua" \
  -c "luafile $SCRIPT_DIR/runner.lua" \
  2>&1

# Get exit code
EXIT_CODE=$?

# Exit with the same code
if [ $EXIT_CODE -eq 0 ]; then
  echo ""
  echo_color "green" "All tests passed! 🎉"
else
  echo ""
  echo_color "red" "Some tests failed!"
fi

exit $EXIT_CODE