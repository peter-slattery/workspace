#!/usr/bin/env bash

# Idempotently manage marker-delimited blocks in the user's shell rc file.
#
# Targets ~/.zshrc on macOS (default shell since Catalina), ~/.bashrc
# elsewhere (Linux, git-bash on Windows). Each block is bracketed by:
#   # BEGIN startup-<name>
#   ...
#   # END startup-<name>
#
# write_rc_block  <name> <content>   — replace existing block (or append if absent)
# remove_rc_block <name>             — strip the block out
# rc_shell_name                      — echo "zsh" or "bash"; use to pick the
#                                      right shell-init flavor (e.g. `fzf --$(rc_shell_name)`)
#
# A block is rewritten only when its content actually changes, so re-running
# is silent.

# shellcheck source=detect_os.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/detect_os.sh"

case "$(detect_os)" in
  macos) RC_FILE="$HOME/.zshrc"  ;;
  *)     RC_FILE="$HOME/.bashrc" ;;
esac

rc_shell_name() {
  case "$(detect_os)" in
    macos) echo zsh  ;;
    *)     echo bash ;;
  esac
}

_rc_extract_block() {
  local begin="$1" end="$2" file="$3"
  awk -v b="$begin" -v e="$end" '
    $0 == b { in_block = 1; next }
    $0 == e { in_block = 0; next }
    in_block { print }
  ' "$file"
}

_rc_strip_block() {
  local begin="$1" end="$2" file="$3"
  local tmp; tmp="$(mktemp)"
  awk -v b="$begin" -v e="$end" '
    $0 == b { skip = 1; next }
    $0 == e { skip = 0; next }
    !skip   { print }
  ' "$file" > "$tmp"
  mv "$tmp" "$file"
}

write_rc_block() {
  local name="$1" content="$2"
  local begin="# BEGIN startup-${name}"
  local end="# END startup-${name}"

  touch "$RC_FILE"

  if grep -qF "$begin" "$RC_FILE"; then
    local existing
    existing="$(_rc_extract_block "$begin" "$end" "$RC_FILE")"
    if [[ "$existing" == "$content" ]]; then
      return 0
    fi
    _rc_strip_block "$begin" "$end" "$RC_FILE"
  fi

  {
    echo ""
    echo "$begin"
    echo "$content"
    echo "$end"
  } >> "$RC_FILE"
  echo "Updated ${name} block in $RC_FILE (re-source or open a new shell)"
}

remove_rc_block() {
  local name="$1"
  local begin="# BEGIN startup-${name}"
  local end="# END startup-${name}"
  [[ -f "$RC_FILE" ]] || return 0
  grep -qF "$begin" "$RC_FILE" || return 0
  _rc_strip_block "$begin" "$end" "$RC_FILE"
  echo "Removed ${name} block from $RC_FILE"
}
