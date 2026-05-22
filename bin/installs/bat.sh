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

install_linux_from_github() {
  local arch
  case "$(uname -m)" in
    x86_64)        arch=x86_64-unknown-linux-gnu  ;;
    aarch64|arm64) arch=aarch64-unknown-linux-gnu ;;
    *) echo "Unsupported arch for bat: $(uname -m)" >&2; exit 1 ;;
  esac

  local tmp; tmp="$(mktemp -d)"

  local version
  version="$(curl -fsSL https://api.github.com/repos/sharkdp/bat/releases/latest \
    | sed -nE 's/.*"tag_name":[[:space:]]*"v([^"]+)".*/\1/p' | head -1)"
  [[ -n "$version" ]] || { echo "Could not determine latest bat version" >&2; exit 1; }

  local stem="bat-v${version}-${arch}"
  curl -fsSL -o "$tmp/bat.tar.gz" \
    "https://github.com/sharkdp/bat/releases/download/v${version}/${stem}.tar.gz"
  tar -xzf "$tmp/bat.tar.gz" -C "$tmp"
  sudo install -m 0755 "$tmp/${stem}/bat" /usr/local/bin/bat
  rm -rf "$tmp"
}

install() {
  echo "Installing bat..."
  if command -v bat >/dev/null 2>&1; then
    echo "  Already installed"
    return 0
  fi
  case "$OS" in
    linux)
      install_linux_from_github
      ;;
    macos)
      if ! command -v brew >/dev/null 2>&1; then
        echo "Homebrew not found. Install from https://brew.sh and re-run." >&2
        exit 1
      fi
      brew install bat
      ;;
    windows)
      $SCRIPT_DIR/_windows_install.sh sharkdp.bat
      ;;
  esac
}

configure() {
  return 0
}

uninstall() {
  if ! command -v bat >/dev/null 2>&1; then
    return 0
  fi
  echo "Uninstalling bat..."
  case "$OS" in
    linux)
      sudo rm -f /usr/local/bin/bat
      ;;
    macos)
      brew uninstall bat
      ;;
    windows)
      $SCRIPT_DIR/_windows_uninstall.sh sharkdp.bat
      ;;
  esac
}

cmd="${1:-}"
case "$cmd" in
  install|configure|uninstall) "$cmd" ;;
  *) echo "Usage: $0 {install|configure|uninstall}" >&2; exit 2 ;;
esac
