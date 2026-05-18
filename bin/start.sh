#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=utils/shell_rc.sh
source "$SCRIPT_DIR/utils/shell_rc.sh"

write_rc_block "bin-path" "export PATH=\"$SCRIPT_DIR:\$PATH\""

# Install
for script in "$SCRIPT_DIR"/installs/*.sh; do
  [[ -f "$script" ]] || continue
  "$script" install
done

# Configure
for script in "$SCRIPT_DIR"/installs/*.sh; do
  [[ -f "$script" ]] || continue
  "$script" configure
done

for script in "$REPO_ROOT"/lib/*.sh; do
    [[ -f "$script" ]] || continue
    write_rc_block "$script" "source \"$script\""
done


