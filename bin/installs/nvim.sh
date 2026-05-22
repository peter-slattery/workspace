#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../bin/utils/detect_os.sh
source "$REPO_ROOT/bin/utils/detect_os.sh"

OS="$(detect_os)"
if [[ "$OS" == "unknown" ]]; then
  echo "Unsupported OS: $(uname -s)" >&2
  exit 1
fi

config_dst_dir() {
  case "$OS" in
    windows) echo "${LOCALAPPDATA:-$HOME/AppData/Local}/nvim" ;;
    *)       echo "${XDG_CONFIG_HOME:-$HOME/.config}/nvim" ;;
  esac
}

install() {
  echo "Installing neovim..."
  if command -v nvim >/dev/null 2>&1; then
    echo "  Already installed"
    return 0
  fi
  echo "Installing neovim..."
  case "$OS" in
    linux)
      if   command -v apt-get >/dev/null 2>&1; then sudo apt-get update && sudo apt-get install -y neovim
      elif command -v dnf     >/dev/null 2>&1; then sudo dnf install -y neovim
      elif command -v pacman  >/dev/null 2>&1; then sudo pacman -S --noconfirm neovim
      else echo "No supported package manager (apt-get, dnf, pacman) found." >&2; exit 1
      fi
      ;;
    macos)
      if ! command -v brew >/dev/null 2>&1; then
        echo "Homebrew not found. Install from https://brew.sh and re-run." >&2
        exit 1
      fi
      brew install neovim
      ;;
    windows)
      $SCRIPT_DIR/_windows_install.sh Neovim.Neovim
      ;;
  esac
}

configure() {
  local src="$REPO_ROOT/config/nvim/init.lua"
  local dst_dir; dst_dir="$(config_dst_dir)"
  local dst="$dst_dir/init.lua"

  mkdir -p "$dst_dir"
  if [[ -f "$dst" ]] && cmp -s "$src" "$dst"; then
    return 0
  fi
  cp "$src" "$dst"
  echo "Updated nvim config -> $dst"
}

uninstall() {
  local dst_dir; dst_dir="$(config_dst_dir)"
  rm -f "$dst_dir/init.lua"
  rmdir "$dst_dir" 2>/dev/null || true

  if ! command -v nvim >/dev/null 2>&1; then
    return 0
  fi
  echo "Uninstalling neovim..."
  case "$OS" in
    linux)
      if   command -v apt-get >/dev/null 2>&1; then sudo apt-get remove -y neovim
      elif command -v dnf     >/dev/null 2>&1; then sudo dnf remove -y neovim
      elif command -v pacman  >/dev/null 2>&1; then sudo pacman -R --noconfirm neovim
      fi
      ;;
    macos)
      brew uninstall neovim
      ;;
    windows)
      $SCRIPT_DIR/_windows_uninstall.sh Neovim.Neovim
      ;;
  esac
}

cmd="${1:-}"
case "$cmd" in
  install|configure|uninstall) "$cmd" ;;
  *) echo "Usage: $0 {install|configure|uninstall}" >&2; exit 2 ;;
esac
