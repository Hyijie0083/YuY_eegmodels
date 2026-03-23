# Makefile for Neovim configuration tests

# Variables
NVIM_CONFIG := $(HOME)/.config/nvim
TEST_DIR := $(NVIM_CONFIG)/test
NVIM_BIN := nvim

.PHONY: test test-headless test-interactive lint help

# Default target
.DEFAULT_GOAL := help

# Help command
help:
	@echo "Neovim Config Test Commands:"
	@echo "  make test             Run all tests in headless mode"
	@echo "  make test-headless    Run all tests in headless mode"
	@echo "  make test-interactive Run tests in interactive mode"
	@echo "  make lint             Run linting/formatting on Lua files"

# Run all tests in headless mode
test: test-headless

# Run all tests in headless mode
test-headless:
	@echo "Running tests in headless mode..."
	@cd $(NVIM_CONFIG) && $(TEST_DIR)/run.sh

# Run tests in interactive mode (useful for debugging)
test-interactive:
	@echo "Running tests in interactive mode..."
	@cd $(NVIM_CONFIG) && NVIM_TEST_MODE=1 $(NVIM_BIN) -u $(TEST_DIR)/minimal_init.lua \
		-c "luafile $(TEST_DIR)/runner.lua"

# Lint Lua files using stylua if available
lint:
	@echo "Linting Lua files..."
	@if command -v stylua > /dev/null; then \
		stylua $(NVIM_CONFIG)/lua/ $(NVIM_CONFIG)/test/ --check; \
	else \
		echo "stylua not found, skipping lint"; \
	fi