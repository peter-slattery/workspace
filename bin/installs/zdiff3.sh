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

# zdiff3 is git's "zealous diff3" merge conflict style, added in git 2.35.
# config/git/config sets merge.conflictstyle = zdiff3, so the system git must
# be 2.35+ for that setting to take effect.
MIN_MAJOR=2
MIN_MINOR=35

git_supports_zdiff3() {
  command -v git >/dev/null 2>&1 || return 1
  local v major minor
  v="$(git --version | awk '{print $3}')"
  major="${v%%.*}"
  minor="${v#*.}"; minor="${minor%%.*}"
  [[ "$major" -gt "$MIN_MAJOR" ]] && return 0
  [[ "$major" -eq "$MIN_MAJOR" && "$minor" -ge "$MIN_MINOR" ]]
}

install_linux() {
  if command -v apt-get >/dev/null 2>&1; then
    # Ubuntu 22.04 ships git 2.34; the git-core PPA tracks upstream stable.
    if ! command -v add-apt-repository >/dev/null 2>&1; then
      sudo apt-get update
      sudo apt-get install -y software-properties-common
    fi
    sudo add-apt-repository -y ppa:git-core/ppa
    sudo apt-get update
    sudo apt-get install -y git
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf upgrade -y git
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -Sy --noconfirm git
  else
    echo "No supported package manager (apt-get, dnf, pacman) found." >&2
    exit 1
  fi
}

install() {
  echo "Installing zdiff3 (git >= ${MIN_MAJOR}.${MIN_MINOR})..."
  if git_supports_zdiff3; then
    echo "  git $(git --version | awk '{print $3}') already supports zdiff3"
    return 0
  fi
  case "$OS" in
    linux)
      install_linux
      ;;
    macos)
      if ! command -v brew >/dev/null 2>&1; then
        echo "Homebrew not found. Install from https://brew.sh and re-run." >&2
        exit 1
      fi
      brew install git
      ;;
    windows)
      if   command -v winget >/dev/null 2>&1; then
        winget install --id Git.Git -e --silent \
          --accept-package-agreements --accept-source-agreements
      elif command -v scoop >/dev/null 2>&1; then scoop install git
      else echo "Need winget or scoop installed on Windows to upgrade git." >&2; exit 1
      fi
      ;;
  esac

  if ! git_supports_zdiff3; then
    echo "git is still < ${MIN_MAJOR}.${MIN_MINOR} after upgrade attempt: $(git --version)" >&2
    exit 1
  fi
}

# The zdiff3 conflict style is wired in via config/git/config, written by
# git.sh's configure step. Nothing to configure here.
configure() {
  return 0
}

# zdiff3 is a feature of git itself, not a separate package — removing it
# would mean downgrading git, which we don't want to do automatically.
uninstall() {
  return 0
}

cmd="${1:-}"
case "$cmd" in
  install|configure|uninstall) "$cmd" ;;
  *) echo "Usage: $0 {install|configure|uninstall}" >&2; exit 2 ;;
esac
