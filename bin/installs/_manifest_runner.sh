#!/usr/bin/env bash
set -euo pipefail

# Generic install/configure/uninstall driver for declarative manifests.
#
# Each manifest is a bash file in $REPO_ROOT/manifests/ that sets a fixed
# set of variables (see manifests/eza.sh for an example). The runner sources
# the manifest, then performs the requested action using the values set.
#
# Per-tool install scripts in bin/installs/*.sh still take priority — use a
# manifest when the install is a straight package-manager-or-GitHub-release
# fetch, and reach for a bespoke script when you need anything weirder
# (config file rendering, rc-block writes, version-aware logic, etc.).
#
# Usage: _manifest_runner.sh <manifest> {install|configure|uninstall}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../utils/detect_os.sh
source "$REPO_ROOT/bin/utils/detect_os.sh"

OS="$(detect_os)"
if [[ "$OS" == "unknown" ]]; then
  echo "Unsupported OS: $(uname -s)" >&2
  exit 1
fi

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <manifest> {install|configure|uninstall}" >&2
  exit 2
fi
MANIFEST="$1"
CMD="$2"
[[ -f "$MANIFEST" ]] || { echo "manifest not found: $MANIFEST" >&2; exit 1; }

# Pre-declare every key the manifest may set. Anything left blank after
# sourcing the manifest is treated as "not configured for this platform".
NAME=""              # required; display name for messages
BIN=""               # binary on PATH (defaults to $NAME)

APT=""               # Linux: apt-get package id
DNF=""               # Linux: dnf package id
PACMAN=""            # Linux: pacman package id

BREW=""              # macOS: brew formula

WINGET=""            # Windows: winget --id

GH_REPO=""           # Linux fallback: GitHub owner/repo
GH_ASSET=""          # Release asset filename; supports {ARCH}, {VERSION}
GH_BIN_IN_ARCHIVE="" # Path to binary inside the archive; supports the same placeholders
GH_ARCH_X86_64=""    # Substituted for {ARCH} when uname -m is x86_64
GH_ARCH_AARCH64=""   # Substituted for {ARCH} when uname -m is aarch64/arm64

# shellcheck disable=SC1090
source "$MANIFEST"

: "${BIN:=$NAME}"
[[ -n "$NAME" ]] || { echo "$MANIFEST: NAME is required" >&2; exit 1; }

# ----------------------------------------------------------------------------
# Helpers
# ----------------------------------------------------------------------------

_gh_latest_version() {
  curl -fsSL "https://api.github.com/repos/$GH_REPO/releases/latest" \
    | sed -nE 's/.*"tag_name":[[:space:]]*"v?([^"]+)".*/\1/p' \
    | head -1
}

_gh_arch_for_host() {
  case "$(uname -m)" in
    x86_64)        printf '%s' "$GH_ARCH_X86_64"  ;;
    aarch64|arm64) printf '%s' "$GH_ARCH_AARCH64" ;;
    *)             return 1                       ;;
  esac
}

_subst() {
  local s="$1"
  s="${s//\{ARCH\}/${ARCH:-}}"
  s="${s//\{VERSION\}/${VERSION:-}}"
  printf '%s' "$s"
}

install_linux_from_github() {
  local ARCH VERSION
  ARCH="$(_gh_arch_for_host)" || { echo "Unsupported arch for $NAME: $(uname -m)" >&2; exit 1; }
  [[ -n "$ARCH" ]] || { echo "$NAME: no GH_ARCH_* entry for $(uname -m)" >&2; exit 1; }
  VERSION="$(_gh_latest_version)"
  [[ -n "$VERSION" ]] || { echo "Could not determine latest $NAME version" >&2; exit 1; }

  local asset; asset="$(_subst "$GH_ASSET")"
  local inner; inner="$(_subst "$GH_BIN_IN_ARCHIVE")"

  local tmp; tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/pkg.tar.gz" \
    "https://github.com/$GH_REPO/releases/download/v${VERSION}/${asset}"
  tar -xzf "$tmp/pkg.tar.gz" -C "$tmp"
  sudo install -m 0755 "$tmp/$inner" "/usr/local/bin/$BIN"
  rm -rf "$tmp"
}

# ----------------------------------------------------------------------------
# Commands
# ----------------------------------------------------------------------------

install() {
  echo "Installing $NAME..."
  if command -v "$BIN" >/dev/null 2>&1; then
    echo "  Already installed"
    return 0
  fi
  case "$OS" in
    linux)
      if [[ -n "$GH_REPO" ]]; then
        install_linux_from_github
      elif [[ -n "$APT" ]] && command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update && sudo apt-get install -y "$APT"
      elif [[ -n "$DNF" ]] && command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y "$DNF"
      elif [[ -n "$PACMAN" ]] && command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --noconfirm "$PACMAN"
      else
        echo "$NAME: no install method configured for Linux" >&2
        exit 1
      fi
      ;;
    macos)
      [[ -n "$BREW" ]] || { echo "$NAME: no BREW set in manifest" >&2; exit 1; }
      if ! command -v brew >/dev/null 2>&1; then
        echo "Homebrew not found. Install from https://brew.sh and re-run." >&2
        exit 1
      fi
      brew install "$BREW"
      ;;
    windows)
      [[ -n "$WINGET" ]] || { echo "$NAME: no WINGET set in manifest" >&2; exit 1; }
      "$SCRIPT_DIR/_windows_install.sh" "$WINGET"
      ;;
  esac
}

# Manifests can't currently express config-file copies or rc-block writes —
# if you need those, drop a bespoke installs/<name>.sh alongside the manifest.
configure() {
  return 0
}

uninstall() {
  if ! command -v "$BIN" >/dev/null 2>&1; then
    return 0
  fi
  echo "Uninstalling $NAME..."
  case "$OS" in
    linux)
      if [[ -n "$GH_REPO" ]]; then
        sudo rm -f "/usr/local/bin/$BIN"
      elif [[ -n "$APT" ]] && command -v apt-get >/dev/null 2>&1; then
        sudo apt-get remove -y "$APT"
      elif [[ -n "$DNF" ]] && command -v dnf >/dev/null 2>&1; then
        sudo dnf remove -y "$DNF"
      elif [[ -n "$PACMAN" ]] && command -v pacman >/dev/null 2>&1; then
        sudo pacman -R --noconfirm "$PACMAN"
      fi
      ;;
    macos)
      [[ -n "$BREW" ]] && brew uninstall "$BREW"
      ;;
    windows)
      [[ -n "$WINGET" ]] && "$SCRIPT_DIR/_windows_uninstall.sh" "$WINGET"
      ;;
  esac
}

case "$CMD" in
  install|configure|uninstall) "$CMD" ;;
  *) echo "Usage: $0 <manifest> {install|configure|uninstall}" >&2; exit 2 ;;
esac
