#!/bin/bash
#
# Fresh machine setup script
# Clone this repo and run: ./install.sh
#

set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

echo "=== Dotfiles Installation ==="
echo "Dotfiles directory: $DOTFILES_DIR"
echo ""

# Check for Homebrew
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add brew to path for this session
    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
fi

# Install stow if needed
if ! command -v stow &> /dev/null; then
    echo "Installing stow..."
    brew install stow
fi

# Files/directories that will be symlinked
ITEMS=(
    ".bash_profile"
    ".bashrc"
    ".claude/CLAUDE.md"
    ".claude/.mcp.json"
    ".claude/settings.json"
    ".vibe/AGENTS.md"
    ".vibe/skills"
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

# Backup existing files
echo ""
echo "Step 1: Backing up existing files..."
needs_backup=false
for item in "${ITEMS[@]}"; do
    if [ -e "$HOME/$item" ] || [ -L "$HOME/$item" ]; then
        needs_backup=true
        break
    fi
done

if [ "$needs_backup" = true ]; then
    mkdir -p "$BACKUP_DIR"
    for item in "${ITEMS[@]}"; do
        if [ -e "$HOME/$item" ] || [ -L "$HOME/$item" ]; then
            echo "  Backing up: $item"
            mv "$HOME/$item" "$BACKUP_DIR/" 2>/dev/null || true
        fi
    done
    echo "  Backed up to: $BACKUP_DIR"
else
    echo "  No existing files to backup"
fi

# Pre-create directories that must not be "folded" by stow
# (stow would otherwise replace the dir with a single symlink)
mkdir -p "$HOME/.claude"
mkdir -p "$HOME/.vibe"

# Create symlinks
echo ""
echo "Step 2: Creating symlinks with stow..."
cd "$DOTFILES_DIR"
stow -v -t "$HOME" home

# Install Brewfile packages (optional)
echo ""
if [ -f "$DOTFILES_DIR/Brewfile" ]; then
    read -p "Install Brewfile packages? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Installing packages from Brewfile..."
        brew bundle --file="$DOTFILES_DIR/Brewfile"
    fi
fi

echo ""
echo "=== Installation complete! ==="
echo ""
echo "Workflow:"
echo "  1. Edit files directly (they're symlinks)"
echo "     vim ~/.config/nvim/init.lua"
echo ""
echo "  2. Commit changes"
echo "     cd $DOTFILES_DIR && git add -A && git commit -m 'update'"
echo ""
echo "  3. On other machines: git pull"
echo ""
echo "Note: To install tmux plugins, open tmux and press prefix + I"
