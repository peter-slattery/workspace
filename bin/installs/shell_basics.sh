#!/usr/bin/env bash
set -euo pipefail

# Centralized shell-environment basics: editor pointers, pager flags,
# convenience aliases, and clears for distro-default aliases that would
# otherwise shadow scripts in bin/ (e.g. Ubuntu's `alias ll='ls -alF'`).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../utils/shell_rc.sh
source "$REPO_ROOT/bin/utils/shell_rc.sh"

install() {
  echo "Configuring shell basics..."
  echo "  (rc-block only, nothing to install)"
}

configure() {
  # Migration: an earlier split kept the unalias in its own block.
  remove_rc_block "alias-overrides" >/dev/null 2>&1 || true

  local block
  block="$(cat <<'EOF'
# Editor — used by git commit, crontab -e, etc.
export EDITOR=nvim
export VISUAL=nvim

# Let less render ANSI colors emitted by delta/bat/etc.
export LESS=-R

# Convenience aliases.
alias g=git

# Clear distro-default aliases that would shadow our bin/ scripts. Appended
# after distro defaults in the rc file, so this runs last and wins.
unalias ll 2>/dev/null || true
EOF
)"
  write_rc_block "shell-basics" "$block"
}

uninstall() {
  remove_rc_block "shell-basics"
}

cmd="${1:-}"
case "$cmd" in
  install|configure|uninstall) "$cmd" ;;
  *) echo "Usage: $0 {install|configure|uninstall}" >&2; exit 2 ;;
esac
