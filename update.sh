#!/bin/sh
#
# oh-my-zsh-x updater
#
# Updates both layers in the right order:
#   1. This repo (custom config)  - git pull
#   2. Oh My Zsh (framework)      - upstream upgrade script
#
# Usage:
#   sh update.sh
#
set -e

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ZSH="${ZSH:-$HOME/.oh-my-zsh}"

echo "==> Updating oh-my-zsh-x (custom config)..."
git -C "$SCRIPT_DIR" pull --ff-only

echo "==> Updating Oh My Zsh (framework)..."
if [ -f "$ZSH/tools/upgrade.sh" ]; then
  zsh "$ZSH/tools/upgrade.sh"
else
  echo "! Oh My Zsh not found at $ZSH, skipping framework update"
fi

echo "==> Done. Restart your shell (or run: source ~/.zshrc) to apply changes."
