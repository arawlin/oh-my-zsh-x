#!/bin/sh
#
# oh-my-zsh-x upgrade script
#
# Updates both layers:
#   1. Config layer (this repo)     - git pull
#   2. Framework layer (Oh My Zsh)  - official tools/upgrade.sh
#
# Usage:
#   sh upgrade.sh
#
set -e

# This script lives in tools/; the repo root is one level up.
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
REPO_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
ZSH="${ZSH:-$HOME/.oh-my-zsh}"

echo "==> Updating config layer (oh-my-zsh-x)..."
if ! git -C "$REPO_DIR" pull --ff-only; then
  echo "! Config update skipped (no remote yet, or local changes conflict)."
fi

echo "==> Updating custom plugins..."
if [ -f "$REPO_DIR/tools/install-plugins.sh" ]; then
  sh "$REPO_DIR/tools/install-plugins.sh"
else
  echo "! tools/install-plugins.sh not found, skipping"
fi

echo "==> Updating framework layer (Oh My Zsh)..."
if [ -f "$ZSH/tools/upgrade.sh" ]; then
  zsh "$ZSH/tools/upgrade.sh"
else
  echo "! Oh My Zsh not found at $ZSH, skipping framework update"
fi

echo "==> Done. Restart your shell (or run: source ~/.zshrc) to apply changes."
