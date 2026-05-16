# dev — per-project environment activation
#
# Projects can put a .dev/ directory at their root (gitignore it). Layout:
#
#   .dev/
#     env.sh            <- default: env vars (sourced with `set -a`, plain assignments auto-export)
#     enter.sh          <- default: arbitrary setup (sourced normally)
#     exit.sh           <- default: optional cleanup (sourced before env restoration)
#     <profile>/
#       env.sh          <- per-profile equivalents
#       enter.sh
#       exit.sh
#
# Commands:
#   dev enter            -> source .dev/env.sh + .dev/enter.sh
#   dev enter <profile>  -> source .dev/<profile>/env.sh + .dev/<profile>/enter.sh
#   dev exit             -> source .dev/[<profile>/]exit.sh, then restore env
#
# Walks up from $PWD to find .dev/. If `dev enter` runs while a project is
# already active, the current one is exited first (with an announcement).
#
# Env restoration is best-effort: any exported variable that env.sh/enter.sh
# created or changed is reverted on exit. Non-env side effects (started
# processes, opened editors, etc.) need an explicit exit.sh to undo.

_dev_find_root() {
  local dir="$PWD"
  while [[ -n "$dir" && "$dir" != "/" ]]; do
    if [[ -d "$dir/.dev" ]]; then
      printf '%s\n' "$dir/.dev"
      return 0
    fi
    dir="${dir%/*}"
  done
  [[ -d "/.dev" ]] && { printf '/.dev\n'; return 0; }
  return 1
}

_dev_label() {
  local root="$1" profile="$2"
  local project; project="$(basename "$(dirname "$root")")"
  if [[ -n "$profile" ]]; then
    printf '%s[%s]' "$project" "$profile"
  else
    printf '%s' "$project"
  fi
}

_dev_active_label() {
  [[ -z "${DEV_STATE_DIR:-}" || ! -f "$DEV_STATE_DIR/info" ]] && return 1
  local root profile
  root="$(awk -F= '$1=="root"{print $2}' "$DEV_STATE_DIR/info")"
  profile="$(awk -F= '$1=="profile"{print $2}' "$DEV_STATE_DIR/info")"
  _dev_label "$root" "$profile"
}

# args: before_snap, after_snap, output_restore_file
_dev_diff_env() {
  local before="$1" after="$2" out="$3"
  : > "$out"

  # Vars that exist (or differ) in after — set them back to their old value, or unset.
  local line name before_line old
  while IFS= read -r line; do
    name="${line%%=*}"
    [[ "$name" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || continue

    before_line=""
    while IFS= read -r bl; do
      if [[ "$bl" == "${name}="* ]]; then
        before_line="$bl"
        break
      fi
    done < "$before"

    if [[ -z "$before_line" ]]; then
      printf 'unset %s\n' "$name" >> "$out"
    elif [[ "$before_line" != "$line" ]]; then
      old="${before_line#*=}"
      printf 'export %s=%q\n' "$name" "$old" >> "$out"
    fi
  done < "$after"

  # Vars that were in before but vanished in after — re-export them.
  local in_after
  while IFS= read -r line; do
    name="${line%%=*}"
    [[ "$name" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || continue

    in_after=0
    while IFS= read -r al; do
      if [[ "$al" == "${name}="* ]]; then
        in_after=1
        break
      fi
    done < "$after"

    if (( in_after == 0 )); then
      old="${line#*=}"
      printf 'export %s=%q\n' "$name" "$old" >> "$out"
    fi
  done < "$before"
}

_dev_enter_impl() {
  local root="$1" profile="$2"
  local dir="$root"
  [[ -n "$profile" ]] && dir="$root/$profile"

  if [[ ! -d "$dir" ]]; then
    echo "dev: profile not found: $dir" >&2
    return 1
  fi

  local env_file="$dir/env.sh"
  local enter_file="$dir/enter.sh"

  local state_dir
  state_dir="$(mktemp -d "${TMPDIR:-/tmp}/dev-$$-XXXXXX")"
  {
    printf 'root=%s\n'    "$root"
    printf 'profile=%s\n' "$profile"
    printf 'dir=%s\n'     "$dir"
  } > "$state_dir/info"

  # Export DEV_STATE_DIR before snapshotting so it doesn't show up in the diff.
  export DEV_STATE_DIR="$state_dir"

  env > "$state_dir/env.before"

  if [[ -f "$env_file" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "$env_file"
    set +a
  fi
  if [[ -f "$enter_file" ]]; then
    # shellcheck disable=SC1090
    source "$enter_file"
  fi

  env > "$state_dir/env.after"
  _dev_diff_env "$state_dir/env.before" "$state_dir/env.after" "$state_dir/restore.sh"
  rm -f "$state_dir/env.before" "$state_dir/env.after"
}

_dev_exit_impl() {
  local state_dir="${DEV_STATE_DIR:-}"
  [[ -z "$state_dir" || ! -d "$state_dir" ]] && return 0

  local dir
  dir="$(awk -F= '$1=="dir"{print $2}' "$state_dir/info" 2>/dev/null)"

  if [[ -n "$dir" && -f "$dir/exit.sh" ]]; then
    # shellcheck disable=SC1090
    source "$dir/exit.sh"
  fi

  if [[ -f "$state_dir/restore.sh" ]]; then
    # shellcheck disable=SC1090
    source "$state_dir/restore.sh"
  fi

  rm -rf "$state_dir"
  unset DEV_STATE_DIR
}

dev() {
  local cmd="${1:-}"
  case "$cmd" in
    enter)
      local profile="${2:-}"
      local root
      if ! root="$(_dev_find_root)"; then
        echo "dev: no .dev/ directory found in $PWD or any parent" >&2
        return 1
      fi

      local next; next="$(_dev_label "$root" "$profile")"
      if [[ -n "${DEV_STATE_DIR:-}" ]]; then
        local prev; prev="$(_dev_active_label)"
        echo "Exiting $prev"
        _dev_exit_impl
      fi
      echo "Entering $next"
      _dev_enter_impl "$root" "$profile"
      ;;
    exit)
      if [[ -z "${DEV_STATE_DIR:-}" ]]; then
        echo "dev: not in a dev env" >&2
        return 1
      fi
      echo "Exiting $(_dev_active_label)"
      _dev_exit_impl
      ;;
    ""|-h|--help|help)
      echo "usage: dev {enter [profile]|exit}"
      [[ "$cmd" == "" ]] && return 2 || return 0
      ;;
    *)
      echo "dev: unknown command: $cmd" >&2
      echo "usage: dev {enter [profile]|exit}" >&2
      return 2
      ;;
  esac
}
