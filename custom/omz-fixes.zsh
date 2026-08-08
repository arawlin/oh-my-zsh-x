# Fix: remove the global alias P defined by the common-aliases plugin.
#
# common-aliases defines P='2>&1| pygmentize -l pytb' (meant to highlight python
# tracebacks when used like: python script.py P). It collides with oh-my-zsh's
# omz_urlencode() (lib/functions.zsh), which uses a bare 'P' as a zparseopts
# option. zsh expands aliases inside function bodies at DEFINITION time, so
# `source ~/.zshrc` re-defines omz_urlencode while P exists and bakes
# `pygmentize` into the function, causing "command not found" errors on every
# prompt render (omz_termsupport_cwd calls omz_urlencode).
#
# This file is sourced by oh-my-zsh.sh AFTER all plugins (it loads
# $ZSH_CUSTOM/*.zsh last), so the unalias below always runs after common-aliases
# and guarantees P is gone before the next re-source — which is exactly what
# prevents omz_urlencode from being re-baked.
#
# The quotes are mandatory: `unalias P` would expand P itself (global aliases
# expand in argument position), and `unalias -g` is invalid in zsh.
#
# If you actually use the P alias, install pygments and remove this line.
unalias 'P' 2>/dev/null
