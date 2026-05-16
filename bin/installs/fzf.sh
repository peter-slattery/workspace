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

# Newer than apt's 0.29 on Ubuntu — we need 0.48+ for `fzf --bash` / `--zsh`.
install_linux_from_github() {
  local arch
  case "$(uname -m)" in
    x86_64)        arch=amd64 ;;
    aarch64|arm64) arch=arm64 ;;
    *) echo "Unsupported arch for fzf: $(uname -m)" >&2; exit 1 ;;
  esac

  local tmp; tmp="$(mktemp -d)"

  local version
  version="$(curl -fsSL https://api.github.com/repos/junegunn/fzf/releases/latest \
    | sed -nE 's/.*"tag_name":[[:space:]]*"v([^"]+)".*/\1/p' | head -1)"
  [[ -n "$version" ]] || { echo "Could not determine latest fzf version" >&2; exit 1; }

  curl -fsSL -o "$tmp/fzf.tar.gz" \
    "https://github.com/junegunn/fzf/releases/download/v${version}/fzf-${version}-linux_${arch}.tar.gz"
  tar -xzf "$tmp/fzf.tar.gz" -C "$tmp"
  sudo install -m 0755 "$tmp/fzf" /usr/local/bin/fzf
  rm -rf "$tmp"
}

# Whether the resolved fzf supports shell-init integration (0.48+).
fzf_supports_shell_init() {
  local sh; sh="$(rc_shell_name)"
  command -v fzf >/dev/null 2>&1 && fzf --"$sh" >/dev/null 2>&1
}

install() {
  echo "Installing fzf..."
  if fzf_supports_shell_init; then
    echo "  Already installed (with --$(rc_shell_name) support)"
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
      brew install fzf
      ;;
    windows)
      if   command -v winget >/dev/null 2>&1; then
        winget install --id junegunn.fzf -e --silent \
          --accept-package-agreements --accept-source-agreements
      elif command -v scoop >/dev/null 2>&1; then scoop install fzf
      else echo "Need winget or scoop installed on Windows to install fzf." >&2; exit 1
      fi
      ;;
  esac
}

configure() {
  local sh; sh="$(rc_shell_name)"
  local block
  block="$(cat <<EOF
if command -v fzf >/dev/null 2>&1 && fzf --${sh} >/dev/null 2>&1; then
  eval "\$(fzf --${sh})"
  if command -v fd >/dev/null 2>&1; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="\$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
  fi
  if command -v bat >/dev/null 2>&1; then
    export FZF_CTRL_T_OPTS="--preview 'bat --color=always --line-range :200 {}' --preview-window=right:60%"
  fi
fi
EOF
)"
  write_rc_block "fzf" "$block"
}

uninstall() {
  remove_rc_block "fzf"
  if ! command -v fzf >/dev/null 2>&1; then
    return 0
  fi
  echo "Uninstalling fzf..."
  case "$OS" in
    linux)
      sudo rm -f /usr/local/bin/fzf
      ;;
    macos)
      brew uninstall fzf
      ;;
    windows)
      if   command -v winget >/dev/null 2>&1; then
        winget uninstall --id junegunn.fzf -e --silent
      elif command -v scoop >/dev/null 2>&1; then scoop uninstall fzf
      fi
      ;;
  esac
}

cmd="${1:-}"
case "$cmd" in
  install|configure|uninstall) "$cmd" ;;
  *) echo "Usage: $0 {install|configure|uninstall}" >&2; exit 2 ;;
esac
