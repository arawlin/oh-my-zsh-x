#!/bin/sh
#
# oh-my-zsh-x plugin manager
#
# Installs (clones or updates) third-party plugins into $ZSH_CUSTOM/plugins
# so Oh My Zsh picks them up by name from the plugins=() list in the .zshrc
# template.
#
# Idempotent and safe to re-run: clones a plugin when its directory is
# missing, fast-forward pulls it when it already exists. A failing plugin is
# reported but never aborts the run.
#
# The plugin directories are local machine state and are gitignored
# (custom/plugins/), so they never enter this repo and `git pull` on this
# repo can never conflict with them. Each plugin keeps its own upstream
# remote and is updated independently.
#
# Usage:
#   sh tools/install-plugins.sh
#
# Environment:
#   ZSH_CUSTOM   - Oh My Zsh custom dir (default: this repo's custom/)
#   SKIP_PLUGINS - 'yes' skips all plugin work (default: no)
#
set -e

# This script lives in tools/; the repo root is one level up.
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
REPO_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)

CUSTOM_DIR="${ZSH_CUSTOM:-$REPO_DIR/custom}"
PLUGINS_DIR="$CUSTOM_DIR/plugins"

# Plugin specs, one "<dir-name> <git-url>" per line.
# Add new community plugins here; they are auto-cloned on install.
PLUGIN_SPECS="
zsh-autosuggestions https://github.com/zsh-users/zsh-autosuggestions.git
zsh-completions https://github.com/zsh-users/zsh-completions.git
zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting.git
"

command_exists() {
  command -v "$@" >/dev/null 2>&1
}

# ANSI color support (no-op when stdout is not a tty).
if [ -t 1 ]; then
  FMT_RESET=$(printf '\033[0m')
  FMT_BOLD=$(printf '\033[1m')
  FMT_RED=$(printf '\033[31m')
  FMT_GREEN=$(printf '\033[32m')
  FMT_YELLOW=$(printf '\033[33m')
  FMT_BLUE=$(printf '\033[34m')
else
  FMT_RESET=""; FMT_BOLD=""; FMT_RED=""; FMT_GREEN=""; FMT_YELLOW=""; FMT_BLUE=""
fi

# Clone a plugin if missing, otherwise fast-forward update it.
sync_plugin() {
  name="$1"
  url="$2"
  target="$PLUGINS_DIR/$name"

  if [ -d "$target/.git" ]; then
    printf '  %s updating %s...%s\n' "$FMT_BLUE" "$name" "$FMT_RESET"
    if ! git -C "$target" pull --ff-only --quiet; then
      printf '  %s! could not update %s (local changes?), skipping%s\n' \
        "$FMT_YELLOW" "$name" "$FMT_RESET"
    fi
  else
    printf '  %s installing %s...%s\n' "$FMT_GREEN" "$name" "$FMT_RESET"
    git clone --quiet "$url" "$target" || {
      printf '  %s! failed to clone %s, skipping%s\n' "$FMT_YELLOW" "$name" "$FMT_RESET"
    }
  fi
}

main() {
  if [ "$SKIP_PLUGINS" = yes ]; then
    echo "! Plugin management skipped (SKIP_PLUGINS=yes)"
    return
  fi

  command_exists git || {
    echo "Error: git is required to install plugins." >&2
    exit 1
  }

  mkdir -p "$PLUGINS_DIR"
  printf '%sSyncing custom plugins into %s...%s\n' "$FMT_BLUE" "$PLUGINS_DIR" "$FMT_RESET"
  printf '%s' "$PLUGIN_SPECS" | while IFS=' ' read -r name url; do
    [ -z "$name" ] && continue
    sync_plugin "$name" "$url"
  done
}

main "$@"
