#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=utils/shell_rc.sh
source "$SCRIPT_DIR/utils/shell_rc.sh"

write_rc_block "bin-path" "export PATH=\"$SCRIPT_DIR:\$PATH\""

RUNNER="$SCRIPT_DIR/installs/_manifest_runner.sh"

# Install
echo "======= BEGINNING INSTALLATION ======="
for script in "$SCRIPT_DIR"/installs/[!_]*.sh; do
  [[ -f "$script" ]] || continue
  echo "== $script =="
  "$script" install
  echo "Complete $?"
done
for manifest in "$REPO_ROOT"/manifests/[!_]*.sh; do
  [[ -f "$manifest" ]] || continue
  echo "== $manifest =="
  "$RUNNER" "$manifest" install
  echo "Complete $?"
done

# Configure
echo "======= BEGINNING CONFIGURATION ======="
for script in "$SCRIPT_DIR"/installs/[!_]*.sh; do
  [[ -f "$script" ]] || continue
  echo "== $script =="
  "$script" configure
done
for manifest in "$REPO_ROOT"/manifests/[!_]*.sh; do
  [[ -f "$manifest" ]] || continue
  echo "== $manifest =="
  "$RUNNER" "$manifest" configure
done

echo "======= UPDATING .BASHRC ======="

# Stale block from the pre-lib/ layout, when bin/dev.sh was sourced via a
# bespoke "dev" rc-block. lib/dev.sh is now picked up by the loop below.
remove_rc_block "dev" >/dev/null 2>&1 || true

if [[ "$(rc_shell_name)" == "zsh" ]]; then
  write_rc_block "prompt line" $'export PROMPT=\'%F{blue}%n@%m%f:%F{green}%~%f\n→  \''
else
  write_rc_block "prompt line" $'export PS1=\'\\[\\e[34m\\]\\u@\\h\\[\\e[0m\\]:\\[\\e[32m\\]\\w\\[\\e[0m\\]\n→  \''
fi

for script in "$REPO_ROOT"/lib/[!_]*.sh; do
    [[ -f "$script" ]] || continue
    echo "== $script =="
    write_rc_block "$script" "source \"$script\""
done


