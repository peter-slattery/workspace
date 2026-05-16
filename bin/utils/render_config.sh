#!/usr/bin/env bash

# Render a config file by selecting lines based on platform symbols.
#
# Usage:
#   render_config <src> <platform> [marker]
#     src       Path to source config file
#     platform  Platform symbol (case-insensitive; usually "$(detect_os)")
#     marker    Doubled comment marker for this file's syntax (default: "##")
#               Use "##" for #-comment files (tmux, sh, yaml, ini, gitconfig),
#               "----" for lua, '""' for vim, etc.
#
# Writes the rendered file to stdout.
#
# Directives must start at column 0, immediately after the marker:
#   <marker>if <EXPR>
#   <marker>elif <EXPR>
#   <marker>else
#   <marker>endif
#
# EXPR is one or more platform symbols joined with `||` (OR). Whitespace
# around `||` is optional. Examples:
#   ##if LINUX
#   ##if MACOS || WINDOWS
#
# Symbols are matched case-insensitively. Nested ifs are not supported.
# Non-directive lines starting with the marker pass through unchanged.

render_config() {
  local src="$1"
  local platform; platform="$(printf '%s' "$2" | tr '[:lower:]' '[:upper:]')"
  local marker="${3:-##}"

  local in_if=0 taken=0 emit=1 lineno=0
  local line

  while IFS= read -r line || [[ -n "$line" ]]; do
    lineno=$((lineno + 1))
    case "$line" in
      "${marker}if "*)
        if (( in_if )); then
          echo "render_config: $src:$lineno: nested ${marker}if not supported" >&2
          return 1
        fi
        in_if=1; taken=0
        if _render_eval_expr "${line#${marker}if }" "$platform"; then
          emit=1; taken=1
        else
          emit=0
        fi
        ;;
      "${marker}elif "*)
        if (( ! in_if )); then
          echo "render_config: $src:$lineno: ${marker}elif without ${marker}if" >&2
          return 1
        fi
        if (( taken )); then
          emit=0
        elif _render_eval_expr "${line#${marker}elif }" "$platform"; then
          emit=1; taken=1
        else
          emit=0
        fi
        ;;
      "${marker}else"|"${marker}else "*)
        if (( ! in_if )); then
          echo "render_config: $src:$lineno: ${marker}else without ${marker}if" >&2
          return 1
        fi
        if (( taken )); then emit=0; else emit=1; taken=1; fi
        ;;
      "${marker}endif"|"${marker}endif "*)
        if (( ! in_if )); then
          echo "render_config: $src:$lineno: ${marker}endif without ${marker}if" >&2
          return 1
        fi
        in_if=0; taken=0; emit=1
        ;;
      *)
        (( emit )) && printf '%s\n' "$line"
        ;;
    esac
  done < "$src"

  if (( in_if )); then
    echo "render_config: $src: unterminated ${marker}if" >&2
    return 1
  fi
}

_render_eval_expr() {
  local expr="$1" platform="$2"
  expr="${expr// /}"
  expr="$(printf '%s' "$expr" | tr '[:lower:]' '[:upper:]')"
  local part rest="$expr"
  while [[ -n "$rest" ]]; do
    if [[ "$rest" == *"||"* ]]; then
      part="${rest%%||*}"; rest="${rest#*||}"
    else
      part="$rest"; rest=""
    fi
    [[ "$part" == "$platform" ]] && return 0
  done
  return 1
}
