#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Git's XDG default — picked up automatically on macOS, Linux, and Windows
# without needing to set core.excludesfile. Read in addition to ~/.gitconfig,
# so user-specific settings there are preserved.
config_dir() {
  echo "${XDG_CONFIG_HOME:-$HOME/.config}/git"
}

install() {
  echo "Configuring git..."
  if ! command -v git >/dev/null 2>&1; then
    echo "  git not found on PATH. Install it before re-running." >&2
    exit 1
  fi
  echo "  git already present (no install step)"
}

configure() {
  local dir; dir="$(config_dir)"
  mkdir -p "$dir"

  for name in ignore config; do
    local src="$REPO_ROOT/config/git/$name"
    local dst="$dir/$name"
    if [[ ! -f "$dst" ]] || ! cmp -s "$src" "$dst"; then
      cp "$src" "$dst"
      echo "Updated git $name -> $dst"
    fi
  done
}

uninstall() {
  local dir; dir="$(config_dir)"
  rm -f "$dir/ignore" "$dir/config"
  rmdir "$dir" 2>/dev/null || true
}

cmd="${1:-}"
case "$cmd" in
  install|configure|uninstall) "$cmd" ;;
  *) echo "Usage: $0 {install|configure|uninstall}" >&2; exit 2 ;;
esac
