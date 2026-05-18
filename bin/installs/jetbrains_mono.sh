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

FONT_NAME="JetBrainsMono Nerd Font"

is_installed() {
  case "$OS" in
    linux|macos)
      # Don't use `grep -q`: it short-circuits and SIGPIPEs fc-list, which
      # then makes the pipeline non-zero under `set -o pipefail`.
      command -v fc-list >/dev/null 2>&1 && fc-list | grep -iF "$FONT_NAME" >/dev/null
      ;;
    windows)
      # No good portable check; rely on the install path's idempotency.
      return 1
      ;;
  esac
}

install_linux_from_github() {
  local tmp; tmp="$(mktemp -d)"

  local version
  version="$(curl -fsSL https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest \
    | sed -nE 's/.*"tag_name":[[:space:]]*"([^"]+)".*/\1/p' | head -1)"
  [[ -n "$version" ]] || { echo "Could not determine latest nerd-fonts version" >&2; rm -rf "$tmp"; exit 1; }

  curl -fsSL -o "$tmp/JetBrainsMono.zip" \
    "https://github.com/ryanoasis/nerd-fonts/releases/download/${version}/JetBrainsMono.zip"

  local dst="$HOME/.local/share/fonts/JetBrainsMonoNerdFont"
  mkdir -p "$dst"
  unzip -q -o "$tmp/JetBrainsMono.zip" -d "$dst"
  rm -rf "$tmp"
  # ~/.local/share/fonts is on fontconfig's default search path, so a plain
  # `fc-cache -f` picks it up without needing to register the directory.
  fc-cache -f >/dev/null
}

install() {
  echo "Installing $FONT_NAME..."
  if is_installed; then
    echo "  Already installed"
    return 0
  fi
  case "$OS" in
    linux)
      if ! command -v unzip >/dev/null 2>&1; then
        if   command -v apt-get >/dev/null 2>&1; then sudo apt-get update && sudo apt-get install -y unzip
        elif command -v dnf     >/dev/null 2>&1; then sudo dnf install -y unzip
        elif command -v pacman  >/dev/null 2>&1; then sudo pacman -S --noconfirm unzip
        else echo "Need unzip to install fonts." >&2; exit 1
        fi
      fi
      install_linux_from_github
      ;;
    macos)
      if ! command -v brew >/dev/null 2>&1; then
        echo "Homebrew not found. Install from https://brew.sh and re-run." >&2
        exit 1
      fi
      brew install --cask font-jetbrains-mono-nerd-font
      ;;
    windows)
      if command -v scoop >/dev/null 2>&1; then
        scoop bucket add nerd-fonts || true
        scoop install nerd-fonts/JetBrainsMono-NF
      else
        echo "Install scoop and re-run, or download JetBrainsMono.zip from" >&2
        echo "https://github.com/ryanoasis/nerd-fonts/releases/latest manually." >&2
        exit 1
      fi
      ;;
  esac

  if ! is_installed; then
    echo "Font install completed but '$FONT_NAME' not visible to fontconfig yet." >&2
    [[ "$OS" == "linux" ]] && echo "Try opening a new terminal or running: fc-cache -fv" >&2
  fi
}

# Font selection lives in the terminal emulator's own config, which this repo
# does not manage. Lazygit already declares nerdFontsVersion: 3, so its
# glyphs light up automatically once the font is the active terminal font.
configure() {
  return 0
}

uninstall() {
  if ! is_installed; then
    return 0
  fi
  echo "Uninstalling $FONT_NAME..."
  case "$OS" in
    linux)
      rm -rf "$HOME/.local/share/fonts/JetBrainsMonoNerdFont"
      fc-cache -f >/dev/null
      ;;
    macos)
      brew uninstall --cask font-jetbrains-mono-nerd-font
      ;;
    windows)
      if command -v scoop >/dev/null 2>&1; then
        scoop uninstall nerd-fonts/JetBrainsMono-NF
      fi
      ;;
  esac
}

cmd="${1:-}"
case "$cmd" in
  install|configure|uninstall) "$cmd" ;;
  *) echo "Usage: $0 {install|configure|uninstall}" >&2; exit 2 ;;
esac
