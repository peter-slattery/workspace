#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=utils/shell_rc.sh
source "$SCRIPT_DIR/utils/shell_rc.sh"

write_rc_block "bin-path" "export PATH=\"$SCRIPT_DIR:\$PATH\""

# Install
echo "======= BEGINNING INSTALLATION ======="
for script in "$SCRIPT_DIR"/installs/[!_]*.sh; do
  [[ -f "$script" ]] || continue
  echo "== $script =="
  "$script" install
  echo "Complete $?"
done

# Configure
echo "======= BEGINNING CONFIGURATION ======="
for script in "$SCRIPT_DIR"/installs/[!_]*.sh; do
  [[ -f "$script" ]] || continue
  echo "== $script =="
  "$script" configure
done

echo "======= UPDATING .BASHRC ======="

write_rc_block "prompt line" $'export PS1=\'\\[\\e[34m\\]\\u@\\h\\[\\e[0m\\]:\\[\\e[32m\\]\\w\\[\\e[0m\\]\n→  \''

for script in "$REPO_ROOT"/lib/[!_]*.sh; do
    [[ -f "$script" ]] || continue
    echo "== $script =="
    write_rc_block "$script" "source \"$script\""
done


