#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# The `ignore` file lives at git's XDG default ($XDG_CONFIG_HOME/git/ignore),
# which git reads automatically when core.excludesFile is unset.
#
# The `config` file is wired in differently: we append an [include] block to
# ~/.gitconfig pointing at the repo copy. Git reads ~/.gitconfig *after*
# $XDG_CONFIG_HOME/git/config, so dropping the repo config at the XDG path
# would let any conflicting key in ~/.gitconfig silently win. The include
# directive is inlined at its location, so anchoring it at the end of
# ~/.gitconfig guarantees the repo's settings take precedence while leaving
# the user's existing identity/safe.directory/etc. entries alone.
config_dir() {
  echo "${XDG_CONFIG_HOME:-$HOME/.config}/git"
}

GITCONFIG="$HOME/.gitconfig"
BLOCK_BEGIN="# BEGIN startup-workspace-include"
BLOCK_END="# END startup-workspace-include"

install() {
  echo "Configuring git..."
  if ! command -v git >/dev/null 2>&1; then
    echo "  git not found on PATH. Install it before re-running." >&2
    exit 1
  fi
  echo "  git already present (no install step)"
}

_extract_block() {
  awk -v b="$BLOCK_BEGIN" -v e="$BLOCK_END" '
    $0 == b { inb = 1; next }
    $0 == e { inb = 0; next }
    inb     { print }
  ' "$1"
}

_strip_block() {
  local tmp; tmp="$(mktemp)"
  awk -v b="$BLOCK_BEGIN" -v e="$BLOCK_END" '
    $0 == b { skip = 1; next }
    $0 == e { skip = 0; next }
    !skip   { print }
  ' "$1" > "$tmp"
  mv "$tmp" "$1"
}

configure() {
  local dir; dir="$(config_dir)"
  mkdir -p "$dir"

  local src_ignore="$REPO_ROOT/config/git/ignore"
  local dst_ignore="$dir/ignore"
  if [[ ! -f "$dst_ignore" ]] || ! cmp -s "$src_ignore" "$dst_ignore"; then
    cp "$src_ignore" "$dst_ignore"
    echo "Updated git ignore -> $dst_ignore"
  fi

  # Clean up the stale config copy from the previous XDG-based approach.
  if [[ -f "$dir/config" ]]; then
    rm -f "$dir/config"
    echo "Removed stale $dir/config (now sourced via include in $GITCONFIG)"
  fi

  local src_config="$REPO_ROOT/config/git/config"
  local content
  content="$(printf '[include]\n\tpath = %s' "$src_config")"

  touch "$GITCONFIG"
  if grep -qF "$BLOCK_BEGIN" "$GITCONFIG"; then
    local existing; existing="$(_extract_block "$GITCONFIG")"
    if [[ "$existing" == "$content" ]]; then
      return 0
    fi
    _strip_block "$GITCONFIG"
  fi
  {
    echo ""
    echo "$BLOCK_BEGIN"
    echo "$content"
    echo "$BLOCK_END"
  } >> "$GITCONFIG"
  echo "Updated workspace include in $GITCONFIG"
}

uninstall() {
  local dir; dir="$(config_dir)"
  rm -f "$dir/ignore" "$dir/config"
  rmdir "$dir" 2>/dev/null || true

  if [[ -f "$GITCONFIG" ]] && grep -qF "$BLOCK_BEGIN" "$GITCONFIG"; then
    _strip_block "$GITCONFIG"
    echo "Removed workspace include from $GITCONFIG"
  fi
}

cmd="${1:-}"
case "$cmd" in
  install|configure|uninstall) "$cmd" ;;
  *) echo "Usage: $0 {install|configure|uninstall}" >&2; exit 2 ;;
esac
