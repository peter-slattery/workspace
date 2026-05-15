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

config_dst_dir() {
  case "$OS" in
    linux)   echo "${XDG_CONFIG_HOME:-$HOME/.config}/lazygit" ;;
    macos)   echo "$HOME/Library/Application Support/lazygit" ;;
    windows) echo "${APPDATA:-$HOME/AppData/Roaming}/lazygit" ;;
  esac
}

install_linux_from_github() {
  local arch
  case "$(uname -m)" in
    x86_64)        arch=x86_64 ;;
    aarch64|arm64) arch=arm64  ;;
    *) echo "Unsupported arch for lazygit: $(uname -m)" >&2; exit 1 ;;
  esac

  local tmp; tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT

  local version
  version="$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest \
    | sed -nE 's/.*"tag_name":[[:space:]]*"v([^"]+)".*/\1/p' | head -1)"
  if [[ -z "$version" ]]; then
    echo "Could not determine latest lazygit version" >&2
    exit 1
  fi

  curl -fsSL -o "$tmp/lazygit.tar.gz" \
    "https://github.com/jesseduffield/lazygit/releases/download/v${version}/lazygit_${version}_Linux_${arch}.tar.gz"
  tar -xzf "$tmp/lazygit.tar.gz" -C "$tmp" lazygit
  sudo install -m 0755 "$tmp/lazygit" /usr/local/bin/lazygit
}

install() {
  echo "Installing lazygit..."
  if command -v lazygit >/dev/null 2>&1; then
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
      brew install lazygit
      ;;
    windows)
      if   command -v winget >/dev/null 2>&1; then
        winget install --id JesseDuffield.lazygit -e --silent \
          --accept-package-agreements --accept-source-agreements
      elif command -v scoop >/dev/null 2>&1; then scoop install lazygit
      else echo "Need winget or scoop installed on Windows to install lazygit." >&2; exit 1
      fi
      ;;
  esac
}

configure() {
  local src="$REPO_ROOT/config/lazygit/config.yml"
  local dst_dir; dst_dir="$(config_dst_dir)"
  local dst="$dst_dir/config.yml"

  mkdir -p "$dst_dir"
  if [[ -f "$dst" ]] && cmp -s "$src" "$dst"; then
    return 0
  fi
  cp "$src" "$dst"
  echo "Updated lazygit config -> $dst"
}

uninstall() {
  local dst_dir; dst_dir="$(config_dst_dir)"
  rm -f "$dst_dir/config.yml"
  rmdir "$dst_dir" 2>/dev/null || true

  if ! command -v lazygit >/dev/null 2>&1; then
    return 0
  fi
  echo "Uninstalling lazygit..."
  case "$OS" in
    linux)
      sudo rm -f /usr/local/bin/lazygit
      ;;
    macos)
      brew uninstall lazygit
      ;;
    windows)
      if   command -v winget >/dev/null 2>&1; then
        winget uninstall --id JesseDuffield.lazygit -e --silent
      elif command -v scoop >/dev/null 2>&1; then scoop uninstall lazygit
      fi
      ;;
  esac
}

cmd="${1:-}"
case "$cmd" in
  install|configure|uninstall) "$cmd" ;;
  *) echo "Usage: $0 {install|configure|uninstall}" >&2; exit 2 ;;
esac
