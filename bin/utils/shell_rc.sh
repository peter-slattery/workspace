#!/usr/bin/env bash

# Idempotently manage marker-delimited blocks in ~/.bashrc.
#
# Each block is bracketed by:
#   # BEGIN startup-<name>
#   ...
#   # END startup-<name>
#
# write_bashrc_block <name> <content>   — replace existing block (or append if absent)
# remove_bashrc_block <name>            — strip the block out
#
# A block is rewritten only when its content actually changes, so re-running
# is silent.

RC_FILE="$HOME/.bashrc"

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

write_bashrc_block() {
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

remove_bashrc_block() {
  local name="$1"
  local begin="# BEGIN startup-${name}"
  local end="# END startup-${name}"
  [[ -f "$RC_FILE" ]] || return 0
  grep -qF "$begin" "$RC_FILE" || return 0
  _rc_strip_block "$begin" "$end" "$RC_FILE"
  echo "Removed ${name} block from $RC_FILE"
}
