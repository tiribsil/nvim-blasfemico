#!/bin/sh

set -e

GITHUB_USER="tiribsil"
REPO_NAME="nvim-blasfemico"

NVIM_CONFIG_DIR="$HOME/.config/nvim"
REPO_URL="https://github.com/$GITHUB_USER/$REPO_NAME.git"

if ! command -v git >/dev/null 2>&1; then
        echo "Error: git is not installed. Please install git and run this script again."
            exit 1
fi
if ! command -v nvim >/dev/null 2>&1; then
        echo "Warning: nvim is not installed. The config will be cloned, but you must install Neovim to use it."
fi

if [ -d "$NVIM_CONFIG_DIR" ]; then
        echo "Found existing Neovim configuration. Backing it up to $NVIM_CONFIG_DIR.bak..."
            mv "$NVIM_CONFIG_DIR" "$NVIM_CONFIG_DIR.bak"
fi

echo "Cloning your configuration from $REPO_URL..."
git clone "$REPO_URL" "$NVIM_CONFIG_DIR"

echo ""
echo "Installation complete!"
echo "The first time you run 'nvim', plugins will be installed automatically."
