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

KEY_FILE="$HOME/.ssh/id_personal"
PUB_FILE="$KEY_FILE.pub"
SSH_CONFIG="$HOME/.ssh/config"
BEGIN_MARK="# BEGIN startup-ssh-personal"
END_MARK="# END startup-ssh-personal"

ensure_ssh_keygen() {
  if command -v ssh-keygen >/dev/null 2>&1; then
    return 0
  fi
  case "$OS" in
    linux)
      if   command -v apt-get >/dev/null 2>&1; then sudo apt-get update && sudo apt-get install -y openssh-client
      elif command -v dnf     >/dev/null 2>&1; then sudo dnf install -y openssh-clients
      elif command -v pacman  >/dev/null 2>&1; then sudo pacman -S --noconfirm openssh
      else echo "Need ssh-keygen but no supported package manager found." >&2; exit 1
      fi
      ;;
    macos)   echo "ssh-keygen missing on macOS (unexpected)." >&2; exit 1 ;;
    windows) echo "ssh-keygen not found; reinstall Git for Windows." >&2; exit 1 ;;
  esac
}

install() {
  echo "Setting up personal SSH key..."
  ensure_ssh_keygen
  if [[ -f "$KEY_FILE" ]]; then
    echo "  Already exists: $KEY_FILE"
    return 0
  fi
  mkdir -p -m 700 "$HOME/.ssh"
  ssh-keygen -q -t ed25519 -f "$KEY_FILE" -N "" -C "$(whoami)@$(hostname) personal"
  echo ""
  echo "================================================================"
  echo " NEXT STEP: Add this public key to your personal GitHub account"
  echo "   https://github.com/settings/ssh/new"
  echo ""
  cat "$PUB_FILE"
  echo ""
  echo " Then verify with: ssh -T git@github-personal"
  echo "================================================================"
}

configure() {
  mkdir -p -m 700 "$HOME/.ssh"
  if [[ ! -f "$SSH_CONFIG" ]]; then
    touch "$SSH_CONFIG"
    chmod 600 "$SSH_CONFIG"
  fi
  if grep -qF "$BEGIN_MARK" "$SSH_CONFIG"; then
    return 0
  fi
  local tmp; tmp="$(mktemp)"
  {
    echo "$BEGIN_MARK"
    echo "Host github-personal"
    echo "  HostName github.com"
    echo "  User git"
    echo "  IdentityFile ~/.ssh/id_personal"
    echo "  IdentitiesOnly yes"
    echo "$END_MARK"
    echo ""
    cat "$SSH_CONFIG"
  } > "$tmp"
  mv "$tmp" "$SSH_CONFIG"
  chmod 600 "$SSH_CONFIG"
  echo "Added github-personal block to $SSH_CONFIG"
}

uninstall() {
  if [[ -f "$SSH_CONFIG" ]] && grep -qF "$BEGIN_MARK" "$SSH_CONFIG"; then
    local tmp; tmp="$(mktemp)"
    awk -v b="$BEGIN_MARK" -v e="$END_MARK" '
      $0 == b { skip = 1; next }
      $0 == e { skip = 0; next }
      !skip   { print }
    ' "$SSH_CONFIG" > "$tmp"
    mv "$tmp" "$SSH_CONFIG"
    chmod 600 "$SSH_CONFIG"
    echo "Removed github-personal block from $SSH_CONFIG"
  fi
  rm -f "$KEY_FILE" "$PUB_FILE"
}

cmd="${1:-}"
case "$cmd" in
  install|configure|uninstall) "$cmd" ;;
  *) echo "Usage: $0 {install|configure|uninstall}" >&2; exit 2 ;;
esac
