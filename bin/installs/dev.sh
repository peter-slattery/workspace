#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../utils/shell_rc.sh
source "$REPO_ROOT/bin/utils/shell_rc.sh"

install() {
  echo "Installing dev..."
  echo "  (shell function, no binary to install)"
}

configure() {
  local target="$REPO_ROOT/bin/dev.sh"
  write_rc_block "dev" "source \"$target\""
}

uninstall() {
  remove_rc_block "dev"
}

cmd="${1:-}"
case "$cmd" in
  install|configure|uninstall) "$cmd" ;;
  *) echo "Usage: $0 {install|configure|uninstall}" >&2; exit 2 ;;
esac
