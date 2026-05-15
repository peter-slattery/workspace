#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../utils/detect_os.sh
source "$REPO_ROOT/bin/utils/detect_os.sh"

OS="$(detect_os)"
if [[ "$OS" == "unknown" ]]; then
  echo "Unsupported OS: $(uname -s)" >&2
  exit 1
fi

# ripgrep has no auto-discovered config path; it reads only from
# $RIPGREP_CONFIG_PATH. Use a uniform path on all OSes so the env var
# can be set to the same value everywhere.
config_dst() {
  echo "$HOME/.config/ripgrep/config"
}

install() {
  echo "Installing ripgrep..."
  if command -v rg >/dev/null 2>&1; then
    echo "  Already installed"
    return 0
  fi
  case "$OS" in
    linux)
      if   command -v apt-get >/dev/null 2>&1; then sudo apt-get update && sudo apt-get install -y ripgrep
      elif command -v dnf     >/dev/null 2>&1; then sudo dnf install -y ripgrep
      elif command -v pacman  >/dev/null 2>&1; then sudo pacman -S --noconfirm ripgrep
      else echo "No supported package manager (apt-get, dnf, pacman) found." >&2; exit 1
      fi
      ;;
    macos)
      if ! command -v brew >/dev/null 2>&1; then
        echo "Homebrew not found. Install from https://brew.sh and re-run." >&2
        exit 1
      fi
      brew install ripgrep
      ;;
    windows)
      if   command -v winget >/dev/null 2>&1; then
        winget install --id BurntSushi.ripgrep.MSVC -e --silent \
          --accept-package-agreements --accept-source-agreements
      elif command -v scoop >/dev/null 2>&1; then scoop install ripgrep
      else echo "Need winget or scoop installed on Windows to install ripgrep." >&2; exit 1
      fi
      ;;
  esac
}

configure() {
  local src="$REPO_ROOT/config/ripgrep/config"
  local dst; dst="$(config_dst)"

  mkdir -p "$(dirname "$dst")"
  if [[ -f "$dst" ]] && cmp -s "$src" "$dst"; then
    return 0
  fi
  cp "$src" "$dst"
  echo "Updated ripgrep config -> $dst"
  echo "  (set RIPGREP_CONFIG_PATH=$dst in your shell to activate)"
}

uninstall() {
  local dst; dst="$(config_dst)"
  rm -f "$dst"
  rmdir "$(dirname "$dst")" 2>/dev/null || true

  if ! command -v rg >/dev/null 2>&1; then
    return 0
  fi
  echo "Uninstalling ripgrep..."
  case "$OS" in
    linux)
      if   command -v apt-get >/dev/null 2>&1; then sudo apt-get remove -y ripgrep
      elif command -v dnf     >/dev/null 2>&1; then sudo dnf remove -y ripgrep
      elif command -v pacman  >/dev/null 2>&1; then sudo pacman -R --noconfirm ripgrep
      fi
      ;;
    macos)
      brew uninstall ripgrep
      ;;
    windows)
      if   command -v winget >/dev/null 2>&1; then
        winget uninstall --id BurntSushi.ripgrep.MSVC -e --silent
      elif command -v scoop >/dev/null 2>&1; then scoop uninstall ripgrep
      fi
      ;;
  esac
}

cmd="${1:-}"
case "$cmd" in
  install|configure|uninstall) "$cmd" ;;
  *) echo "Usage: $0 {install|configure|uninstall}" >&2; exit 2 ;;
esac
