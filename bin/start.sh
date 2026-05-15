#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

