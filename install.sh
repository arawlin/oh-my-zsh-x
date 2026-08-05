#!/bin/sh
#
# oh-my-zsh-x installer
#
# Installs Oh My Zsh (upstream) and deploys this repo's customization:
#   - custom/ directory (themes, plugins) as $ZSH_CUSTOM
#   - zshrc.zsh-template as ~/.zshrc
#   - creates ~/.zshrc_custom (custom profile hook)
#   - optionally switches the default shell to zsh
#
# Run from the repo root (or anywhere):
#   sh install.sh
#
# Environment variables (all optional):
#   ZSH       - Oh My Zsh install path          (default: $HOME/.oh-my-zsh)
#   REPO      - GitHub repo to clone from       (default: ohmyzsh/ohmyzsh)
#   REMOTE    - full git remote URL             (default: https://github.com/${REPO}.git)
#   BRANCH    - branch to check out             (default: master)
#   CHSH      - 'no' skips changing the shell   (default: yes)
#   RUNZSH    - 'no' skips running zsh after    (default: yes)
#   KEEP_ZSHRC - 'yes' keeps an existing .zshrc (default: no)
#
# Options:
#   --skip-chsh   same as CHSH=no
#   --unattended  sets CHSH=no, RUNZSH=no, KEEP_ZSHRC=yes
#   --keep-zshrc  same as KEEP_ZSHRC=yes
#
# Examples:
#   sh install.sh                                  # interactive install
#   sh install.sh --unattended                     # non-interactive install
#   ZSH=/tmp/omztest/oh-my-zsh sh install.sh       # install to a custom path
#
set -e

# --- Locate this repo -------------------------------------------------------

# Resolve the directory of this script (repo root), following symlinks.
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ZSH_CUSTOM_DIR="$SCRIPT_DIR/custom"

# --- Defaults ----------------------------------------------------------------

USER=${USER:-$(id -u -n)}
HOME="${HOME:-$(getent passwd "$USER" 2>/dev/null | cut -d: -f6)}"
HOME="${HOME:-$(eval echo ~"$USER")}"

ZSH="${ZSH:-$HOME/.oh-my-zsh}"
REPO=${REPO:-ohmyzsh/ohmyzsh}
REMOTE=${REMOTE:-https://github.com/${REPO}.git}
BRANCH=${BRANCH:-master}

CHSH=${CHSH:-yes}
RUNZSH=${RUNZSH:-yes}
KEEP_ZSHRC=${KEEP_ZSHRC:-no}

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

setup_ohmyzsh() {
  # Prevent the cloned repo from having insecure permissions, which
  # otherwise breaks compinit ("command not found: compdef").
  umask g-w,o-w

  printf '%sCloning Oh My Zsh...%s\n' "$FMT_BLUE" "$FMT_RESET"

  command_exists git || {
    fmt_error "git is not installed"
    exit 1
  }

  # Manual shallow clone; also works with git < 1.7.2.
  git init --quiet "$ZSH" && cd "$ZSH" \
  && git config core.eol lf \
  && git config core.autocrlf false \
  && git config fsck.zeroPaddedFilemode ignore \
  && git config fetch.fsck.zeroPaddedFilemode ignore \
  && git config receive.fsck.zeroPaddedFilemode ignore \
  && git config oh-my-zsh.remote origin \
  && git config oh-my-zsh.branch "$BRANCH" \
  && git remote add origin "$REMOTE" \
  && git fetch --depth=1 origin \
  && git checkout -b "$BRANCH" "origin/$BRANCH" || {
    [ ! -d "$ZSH" ] || {
      cd -
      rm -rf "$ZSH" 2>/dev/null
    }
    fmt_error "git clone of oh-my-zsh repo failed"
    exit 1
  }
  cd -
  echo
}

setup_zshrc() {
  # Keep the most recent old .zshrc at .zshrc.pre-oh-my-zsh so uninstall.sh
  # can restore it; older backups get a datestamp suffix.
  # Note: plain variables (no `local`) to stay POSIX-sh compatible.
  zdot="${ZDOTDIR:-$HOME}"
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
  omz_x_custom=$(path_to_home "$ZSH_CUSTOM_DIR")

  sed "s|__OMZ_X_CUSTOM__|$(sed_escape "$omz_x_custom")|" \
    "$SCRIPT_DIR/zshrc.zsh-template" \
    | sed "s|^export ZSH=.*$|export ZSH=\"$(sed_escape "$omz")\"|" \
    > "$zdot/.zshrc-omztemp"
  mv -f "$zdot/.zshrc-omztemp" "$zdot/.zshrc"

  # Create the custom profile hook referenced by the template.
  touch "$zdot/.zshrc_custom"

  echo
}

setup_shell() {
  # Skip if disabled, stdin is closed, or the shell is already zsh.
  if [ "$CHSH" = no ]; then
    return
  fi
  if [ "$(basename -- "$SHELL")" = "zsh" ]; then
    return
  fi
  if ! command_exists chsh; then
    printf 'I cannot change your shell automatically (no chsh).\n'
    printf '%sPlease manually change your default shell to zsh%s\n' "$FMT_BLUE" "$FMT_RESET"
    return
  fi

  printf '%sTime to change your default shell to zsh:%s\n' "$FMT_BLUE" "$FMT_RESET"
  printf 'Do you want to change your default shell to zsh? [Y/n] '
  read -r opt
  case $opt in
    [Yy]*|"") ;;
    [Nn]*) echo "Shell change skipped."; return ;;
    *) echo "Invalid choice. Shell change skipped."; return ;;
  esac

  # Find a zsh binary that is registered in /etc/shells.
  shells_file=""
  if [ -f /etc/shells ]; then
    shells_file=/etc/shells
  elif [ -f /usr/share/defaults/etc/shells ]; then
    shells_file=/usr/share/defaults/etc/shells
  else
    fmt_error "could not find /etc/shells. Change your default shell manually."
    return
  fi
  zsh_bin=""
  if ! zsh_bin=$(command -v zsh) || ! grep -qx "$zsh_bin" "$shells_file"; then
    if ! zsh_bin=$(grep '^/.*/zsh$' "$shells_file" | tail -n 1) || [ ! -f "$zsh_bin" ]; then
      fmt_error "no zsh binary found or not present in '$shells_file'"
      fmt_error "change your default shell manually."
      return
    fi
  fi

  # Back up the current shell so uninstall.sh can restore it.
  if [ -n "$SHELL" ]; then
    echo "$SHELL" > "${ZDOTDIR:-$HOME}/.shell.pre-oh-my-zsh"
  else
    grep "^$USER:" /etc/passwd | awk -F: '{print $7}' > "${ZDOTDIR:-$HOME}/.shell.pre-oh-my-zsh"
  fi

  echo "Changing your shell to $zsh_bin..."
  if chsh -s "$zsh_bin" "$USER"; then
    export SHELL="$zsh_bin"
    printf '%sShell successfully changed to '%s'.%s\n' "$FMT_GREEN" "$zsh_bin" "$FMT_RESET"
  else
    fmt_error "chsh command unsuccessful. Change your default shell manually."
  fi
  echo
}

print_success() {
  printf '%s%s%s\n' "$FMT_GREEN" "oh-my-zsh-x is now installed!" "$FMT_RESET"
  printf '\n'
  printf '  - Oh My Zsh (framework):  %s\n' "$ZSH"
  printf '  - Custom config (repo):    %s\n' "$SCRIPT_DIR"
  printf '  - Custom directory:        %s\n' "$ZSH_CUSTOM_DIR"
  printf '  - Zsh config:              %s/.zshrc\n' "${ZDOTDIR:-$HOME}"
  printf '\n'
  printf 'Edit %s/custom and %s to tune your setup.\n' "$SCRIPT_DIR" "$SCRIPT_DIR/zshrc.zsh-template"
  printf 'Follow us on X: https://x.com/ohmyzsh\n'
}

# --- Entry point --------------------------------------------------------------

main() {
  # Run unattended when stdin is not a tty (e.g. curl | sh).
  if [ ! -t 0 ]; then
    RUNZSH=no
    CHSH=no
  fi

  # Parse arguments.
  while [ $# -gt 0 ]; do
    case $1 in
      --unattended) RUNZSH=no; CHSH=no; KEEP_ZSHRC=yes ;;
      --skip-chsh) CHSH=no ;;
      --keep-zshrc) KEEP_ZSHRC=yes ;;
      *) echo "Unknown option: $1"; exit 1 ;;
    esac
    shift
  done

  setup_color

  command_exists zsh || {
    printf '%sZsh is not installed.%s Please install zsh first.\n' "$FMT_YELLOW" "$FMT_RESET"
    exit 1
  }

  if [ -d "$ZSH" ]; then
    printf '%sThe $ZSH folder already exists (%s).%s\n' "$FMT_YELLOW" "$ZSH" "$FMT_RESET"
    echo "You'll need to remove it if you want to reinstall, e.g.:"
    echo "  rm -rf $ZSH"
    exit 1
  fi

  setup_ohmyzsh
  setup_zshrc
  setup_shell

  print_success

  if [ "$RUNZSH" = no ]; then
    printf '%sRun zsh to try it out.%s\n' "$FMT_YELLOW" "$FMT_RESET"
    exit
  fi

  exec zsh -l
}

main "$@"
