#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../utils/detect_os.sh
source "$REPO_ROOT/bin/utils/detect_os.sh"
# shellcheck source=../utils/render_config.sh
source "$REPO_ROOT/bin/utils/render_config.sh"

OS="$(detect_os)"
if [[ "$OS" == "unknown" ]]; then
  echo "Unsupported OS: $(uname -s)" >&2
  exit 1
fi

install() {
  echo "Installing tmux..."
  if [[ "$OS" == "windows" ]]; then
    echo "  tmux is not supported natively on Windows; skipping."
    return 0
  fi
  if command -v tmux >/dev/null 2>&1; then
    echo "  Already installed"
    return 0
  fi
  case "$OS" in
    linux)
      if   command -v apt-get >/dev/null 2>&1; then sudo apt-get update && sudo apt-get install -y tmux
      elif command -v dnf     >/dev/null 2>&1; then sudo dnf install -y tmux
      elif command -v pacman  >/dev/null 2>&1; then sudo pacman -S --noconfirm tmux
      else echo "No supported package manager (apt-get, dnf, pacman) found." >&2; exit 1
      fi
      ;;
    macos)
      if ! command -v brew >/dev/null 2>&1; then
        echo "Homebrew not found. Install from https://brew.sh and re-run." >&2
        exit 1
      fi
      brew install tmux
      ;;
  esac
}

configure() {
  if [[ "$OS" == "windows" ]]; then return 0; fi
  local src="$REPO_ROOT/config/tmux/config.conf"
  local dst="$HOME/.tmux.conf"
  local tmp; tmp="$(mktemp)"

  if ! render_config "$src" "$OS" > "$tmp"; then
    rm -f "$tmp"
    exit 1
  fi

  if [[ -f "$dst" ]] && cmp -s "$tmp" "$dst"; then
    rm -f "$tmp"
    return 0
  fi
  mv "$tmp" "$dst"
  echo "Updated tmux config -> $dst"
}

uninstall() {
  if [[ "$OS" == "windows" ]]; then return 0; fi
  rm -f "$HOME/.tmux.conf"
  if ! command -v tmux >/dev/null 2>&1; then
    return 0
  fi
  echo "Uninstalling tmux..."
  case "$OS" in
    linux)
      if   command -v apt-get >/dev/null 2>&1; then sudo apt-get remove -y tmux
      elif command -v dnf     >/dev/null 2>&1; then sudo dnf remove -y tmux
      elif command -v pacman  >/dev/null 2>&1; then sudo pacman -R --noconfirm tmux
      fi
      ;;
    macos)
      brew uninstall tmux
      ;;
  esac
}

cmd="${1:-}"
case "$cmd" in
  install|configure|uninstall) "$cmd" ;;
  *) echo "Usage: $0 {install|configure|uninstall}" >&2; exit 2 ;;
esac
