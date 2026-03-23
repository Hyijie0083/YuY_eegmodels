#!/bin/bash
#
# Migration script: chezmoi -> stow
# Run this once on each machine to switch from chezmoi to stow-based dotfiles
#

set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

echo "=== Migrating from chezmoi to stow ==="
echo "Dotfiles directory: $DOTFILES_DIR"
echo "Backup directory: $BACKUP_DIR"
echo ""

# Check for stow
if ! command -v stow &> /dev/null; then
    echo "Error: stow is not installed."
    echo "Install with: brew install stow"
    exit 1
fi

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Files/directories that will be symlinked
ITEMS=(
    ".bash_profile"
    ".bashrc"
    ".config"
    ".gitconfig"
    ".gitignore_global"
    ".tmux"
    ".tmux.conf"
    ".zprofile"
    ".zsh"
    ".zshenv"
    ".zshrc"
)

echo "Step 1: Backing up existing files..."
for item in "${ITEMS[@]}"; do
    if [ -e "$HOME/$item" ] || [ -L "$HOME/$item" ]; then
        echo "  Backing up: $item"
        mv "$HOME/$item" "$BACKUP_DIR/" 2>/dev/null || true
    fi
done

echo ""
echo "Step 2: Creating symlinks with stow..."
cd "$DOTFILES_DIR"
stow -v -t "$HOME" home

echo ""
echo "Step 3: Cleaning up chezmoi (optional)..."
if command -v chezmoi &> /dev/null; then
    read -p "Uninstall chezmoi? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        brew uninstall chezmoi 2>/dev/null || echo "chezmoi not installed via brew"
        rm -rf "$HOME/.local/share/chezmoi" 2>/dev/null || true
        rm -rf "$HOME/.config/chezmoi" 2>/dev/null || true
        echo "chezmoi removed"
    fi
fi

echo ""
echo "=== Migration complete! ==="
echo ""
echo "Your old files are backed up at: $BACKUP_DIR"
echo ""
echo "New workflow:"
echo "  1. Edit files directly (they're symlinks now)"
echo "     vim ~/.config/nvim/init.lua"
echo ""
echo "  2. Commit changes from dotfiles repo"
echo "     cd $DOTFILES_DIR && git add -A && git commit -m 'update'"
echo ""
echo "  3. On other machines: git pull (symlinks update automatically)"
echo ""
echo "To undo this migration, run:"
echo "  rm -rf ~/.*  # careful!"
echo "  mv $BACKUP_DIR/* ~/"
