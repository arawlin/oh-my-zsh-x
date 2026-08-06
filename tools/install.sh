#!/bin/sh
#
# oh-my-zsh-x bootstrap installer
#
# Two ways to run:
#   1. From a local clone:
#        sh install.sh
#   2. From remote (one-liner, clones this repo automatically):
#        sh -c "$(curl -fsSL https://raw.githubusercontent.com/arawlin/oh-my-zsh-x/main/install.sh)"
#
# What it does:
#   1. Bootstrap: locate this repo (clone it first when run from remote).
#   2. Deploy the config layer: render templates/zshrc.zsh-template as
#      ~/.zshrc, point $ZSH_CUSTOM at this repo's custom/, create
#      ~/.zshrc_custom.
#   3. Install community plugins into $ZSH_CUSTOM/plugins via
#      tools/install-plugins.sh (idempotent clone/update).
#   4. Install the framework by delegating to the official Oh My Zsh
#      install script (--keep-zshrc so it never touches ~/.zshrc).
#
# Environment variables (all optional):
#   OMZ_X_DIR      - this repo's location (default: $HOME/.oh-my-zsh-x)
#   OMZ_X_REMOTE   - git URL used to clone this repo (default: GitHub URL)
#   ZSH            - Oh My Zsh install path (default: $HOME/.oh-my-zsh)
#   KEEP_ZSHRC     - 'yes' keeps an existing .zshrc (default: no)
#   OMZ_INSTALLER  - official installer (URL or local path; for testing)
#
# Options:
#   --skip-chsh    pass through: do not change the default shell
#   --unattended   pass through: non-interactive install
#   --keep-zshrc   keep an existing .zshrc (skip deploying the template)
#
set -e

# --- Defaults ----------------------------------------------------------------

USER=${USER:-$(id -u -n)}
HOME="${HOME:-$(getent passwd "$USER" 2>/dev/null | cut -d: -f6)}"
HOME="${HOME:-$(eval echo ~"$USER")}"

ZSH="${ZSH:-$HOME/.oh-my-zsh}"
KEEP_ZSHRC=${KEEP_ZSHRC:-no}

# This repo's location and remote (used by the bootstrap step).
OMZ_X_DIR="${OMZ_X_DIR:-$HOME/.oh-my-zsh-x}"
OMZ_X_REMOTE="${OMZ_X_REMOTE:-https://github.com/arawlin/oh-my-zsh-x.git}"

# Official installer; override with a local path for testing/offline installs.
OMZ_INSTALLER="${OMZ_INSTALLER:-https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh}"

# This script lives in tools/; the repo root is one level up.
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)

# --- Small helpers -----------------------------------------------------------

command_exists() {
  command -v "$@" >/dev/null 2>&1
}

# Print a path as "$HOME/..." when it lives under $HOME, else as-is.
# Keeps generated .zshrc portable across machines.
path_to_home() {
  case "$1" in
    "$HOME") printf '%s' '$HOME' ;;
    "$HOME"/*) printf '%s/%s' '$HOME' "${1#"$HOME"/}" ;;
    *) printf '%s' "$1" ;;
  esac
}

# Escape a string for safe use in a sed replacement.
sed_escape() {
  printf '%s' "$1" | sed 's/[&/\]/\\&/g'
}

# ANSI color support (no-op when stdout is not a tty).
if [ -t 1 ]; then
  setup_color() {
    FMT_RESET=$(printf '\033[0m')
    FMT_BOLD=$(printf '\033[1m')
    FMT_RED=$(printf '\033[31m')
    FMT_GREEN=$(printf '\033[32m')
    FMT_YELLOW=$(printf '\033[33m')
    FMT_BLUE=$(printf '\033[34m')
  }
else
  setup_color() {
    FMT_RESET=""; FMT_BOLD=""; FMT_RED=""; FMT_GREEN=""; FMT_YELLOW=""; FMT_BLUE=""
  }
fi

fmt_error() {
  printf '%sError: %s%s\n' "$FMT_RED" "$*" "$FMT_RESET" >&2
}

# --- Steps -------------------------------------------------------------------

bootstrap_repo() {
  # Running from a local clone when tools/../custom and the template exist.
  if [ -d "$SCRIPT_DIR/../custom" ] && [ -f "$SCRIPT_DIR/../templates/zshrc.zsh-template" ]; then
    REPO_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
    return
  fi

  # Otherwise (curl | sh) clone this repo first.
  if [ ! -d "$OMZ_X_DIR" ]; then
    printf '%sCloning oh-my-zsh-x...%s\n' "$FMT_BLUE" "$FMT_RESET"
    command_exists git || {
      echo "Error: git is required to bootstrap." >&2
      exit 1
    }
    git clone --quiet "$OMZ_X_REMOTE" "$OMZ_X_DIR" || {
      echo "Error: failed to clone $OMZ_X_REMOTE" >&2
      exit 1
    }
  fi
  REPO_DIR="$OMZ_X_DIR"
}

deploy_zshrc() {
  zdot="${ZDOTDIR:-$HOME}"
  # Ensure the target dotfiles dir exists (e.g. when ZDOTDIR is set).
  mkdir -p "$zdot"
  old_zshrc="$zdot/.zshrc.pre-oh-my-zsh"

  printf '%sLooking for an existing zsh config...%s\n' "$FMT_BLUE" "$FMT_RESET"

  if [ -f "$zdot/.zshrc" ] || [ -h "$zdot/.zshrc" ]; then
    if [ "$KEEP_ZSHRC" = yes ]; then
      printf '%sFound %s/.zshrc.%s %sKeeping...%s\n' \
        "$FMT_YELLOW" "$zdot" "$FMT_RESET" "$FMT_GREEN" "$FMT_RESET"
      return
    fi
    if [ -e "$old_zshrc" ]; then
      old_old_zshrc="${old_zshrc}-$(date +%Y-%m-%d_%H-%M-%S)"
      if [ -e "$old_old_zshrc" ]; then
        fmt_error "$old_old_zshrc exists. Can't back up ${old_zshrc}"
        fmt_error "re-run the installer again in a couple of seconds"
        exit 1
      fi
      mv "$old_zshrc" "$old_old_zshrc"
      printf '%sFound old .zshrc.pre-oh-my-zsh. %sBacking up to %s%s\n' \
        "$FMT_YELLOW" "$FMT_GREEN" "$old_old_zshrc" "$FMT_RESET"
    fi
    printf '%sBacking up to %s%s\n' "$FMT_GREEN" "$old_zshrc" "$FMT_RESET"
    mv "$zdot/.zshrc" "$old_zshrc"
  fi

  printf '%sUsing the oh-my-zsh-x template and adding it to %s/.zshrc.%s\n' \
    "$FMT_GREEN" "$zdot" "$FMT_RESET"

  # Rewrite paths as portable literals ($HOME/...) before writing.
  omz=$(path_to_home "$ZSH")
  omz_x_custom=$(path_to_home "$REPO_DIR/custom")

  sed "s|__OMZ_X_CUSTOM__|$(sed_escape "$omz_x_custom")|" \
    "$REPO_DIR/templates/zshrc.zsh-template" \
    | sed "s|^export ZSH=.*$|export ZSH=\"$(sed_escape "$omz")\"|" \
    > "$zdot/.zshrc-omztemp"
  mv -f "$zdot/.zshrc-omztemp" "$zdot/.zshrc"

  # Create the custom profile hook referenced by the template.
  touch "$zdot/.zshrc_custom"

  echo
}


# --- Entry point --------------------------------------------------------------

main() {
  # Options for the official installer (passed through).
  official_args=""
  while [ $# -gt 0 ]; do
    case $1 in
      --skip-chsh|--unattended) official_args="$official_args $1" ;;
      --keep-zshrc) KEEP_ZSHRC=yes ;;
      *) echo "Unknown option: $1"; exit 1 ;;
    esac
    shift
  done

  setup_color
  bootstrap_repo

  # Deploy the config layer BEFORE running the official installer:
  # the official script ends with `exec zsh -l`, which replaces this
  # process, so nothing after that call would run.
  deploy_zshrc

  # Install community plugins into $ZSH_CUSTOM/plugins (idempotent).
  if [ -f "$REPO_DIR/tools/install-plugins.sh" ]; then
    sh "$REPO_DIR/tools/install-plugins.sh"
  fi

  # Install the framework via the official script. --keep-zshrc makes
  # sure it never overwrites the .zshrc we just deployed.
  printf '%sInstalling Oh My Zsh (upstream)...%s\n' "$FMT_BLUE" "$FMT_RESET"
  export ZSH
  case "$OMZ_INSTALLER" in
    http://*|https://*)
      sh -c "$(curl -fsSL "$OMZ_INSTALLER")" "" $official_args --keep-zshrc ;;
    *)
      sh "$OMZ_INSTALLER" $official_args --keep-zshrc ;;
  esac
}

main "$@"
