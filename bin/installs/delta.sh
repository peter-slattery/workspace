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
    *) echo "Unsupported arch for delta: $(uname -m)" >&2; exit 1 ;;
  esac

  local tmp; tmp="$(mktemp -d)"

  local version
  version="$(curl -fsSL https://api.github.com/repos/dandavison/delta/releases/latest \
    | sed -nE 's/.*"tag_name":[[:space:]]*"([^"]+)".*/\1/p' | head -1)"
  [[ -n "$version" ]] || { echo "Could not determine latest delta version" >&2; exit 1; }

  local stem="delta-${version}-${arch}"
  curl -fsSL -o "$tmp/delta.tar.gz" \
    "https://github.com/dandavison/delta/releases/download/${version}/${stem}.tar.gz"
  tar -xzf "$tmp/delta.tar.gz" -C "$tmp"
  sudo install -m 0755 "$tmp/${stem}/delta" /usr/local/bin/delta
  rm -rf "$tmp"
}

install() {
  echo "Installing delta..."
  if command -v delta >/dev/null 2>&1; then
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
      brew install git-delta
      ;;
    windows)
      if   command -v winget >/dev/null 2>&1; then
        winget install --id dandavison.delta -e --silent \
          --accept-package-agreements --accept-source-agreements
      elif command -v scoop >/dev/null 2>&1; then scoop install delta
      else echo "Need winget or scoop installed on Windows to install delta." >&2; exit 1
      fi
      ;;
  esac
}

# delta is wired in via config/git/config and config/lazygit/config.yml,
# which are written by their respective install scripts.
configure() {
  return 0
}

uninstall() {
  if ! command -v delta >/dev/null 2>&1; then
    return 0
  fi
  echo "Uninstalling delta..."
  case "$OS" in
    linux)
      sudo rm -f /usr/local/bin/delta
      ;;
    macos)
      brew uninstall git-delta
      ;;
    windows)
      if   command -v winget >/dev/null 2>&1; then
        winget uninstall --id dandavison.delta -e --silent
      elif command -v scoop >/dev/null 2>&1; then scoop uninstall delta
      fi
      ;;
  esac
}

cmd="${1:-}"
case "$cmd" in
  install|configure|uninstall) "$cmd" ;;
  *) echo "Usage: $0 {install|configure|uninstall}" >&2; exit 2 ;;
esac
