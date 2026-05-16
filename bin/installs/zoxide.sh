#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../utils/detect_os.sh
source "$REPO_ROOT/bin/utils/detect_os.sh"
# shellcheck source=../utils/shell_rc.sh
source "$REPO_ROOT/bin/utils/shell_rc.sh"

OS="$(detect_os)"
if [[ "$OS" == "unknown" ]]; then
  echo "Unsupported OS: $(uname -s)" >&2
  exit 1
fi

install() {
  echo "Installing zoxide..."
  if command -v zoxide >/dev/null 2>&1; then
    echo "  Already installed"
    return 0
  fi
  case "$OS" in
    linux)
      if   command -v apt-get >/dev/null 2>&1; then sudo apt-get update && sudo apt-get install -y zoxide
      elif command -v dnf     >/dev/null 2>&1; then sudo dnf install -y zoxide
      elif command -v pacman  >/dev/null 2>&1; then sudo pacman -S --noconfirm zoxide
      else echo "No supported package manager (apt-get, dnf, pacman) found." >&2; exit 1
      fi
      ;;
    macos)
      if ! command -v brew >/dev/null 2>&1; then
        echo "Homebrew not found. Install from https://brew.sh and re-run." >&2
        exit 1
      fi
      brew install zoxide
      ;;
    windows)
      if   command -v winget >/dev/null 2>&1; then
        winget install --id ajeetdsouza.zoxide -e --silent \
          --accept-package-agreements --accept-source-agreements
      elif command -v scoop >/dev/null 2>&1; then scoop install zoxide
      else echo "Need winget or scoop installed on Windows to install zoxide." >&2; exit 1
      fi
      ;;
  esac
}

configure() {
  local sh; sh="$(rc_shell_name)"
  local block
  block="$(cat <<EOF
if command -v zoxide >/dev/null 2>&1; then
  eval "\$(zoxide init ${sh})"
fi
EOF
)"
  write_rc_block "zoxide" "$block"
}

uninstall() {
  remove_rc_block "zoxide"
  if ! command -v zoxide >/dev/null 2>&1; then
    return 0
  fi
  echo "Uninstalling zoxide..."
  case "$OS" in
    linux)
      if   command -v apt-get >/dev/null 2>&1; then sudo apt-get remove -y zoxide
      elif command -v dnf     >/dev/null 2>&1; then sudo dnf remove -y zoxide
      elif command -v pacman  >/dev/null 2>&1; then sudo pacman -R --noconfirm zoxide
      fi
      ;;
    macos)
      brew uninstall zoxide
      ;;
    windows)
      if   command -v winget >/dev/null 2>&1; then
        winget uninstall --id ajeetdsouza.zoxide -e --silent
      elif command -v scoop >/dev/null 2>&1; then scoop uninstall zoxide
      fi
      ;;
  esac
}

cmd="${1:-}"
case "$cmd" in
  install|configure|uninstall) "$cmd" ;;
  *) echo "Usage: $0 {install|configure|uninstall}" >&2; exit 2 ;;
esac
