#!/usr/bin/env bash
set -euo pipefail

TARGET=$1

WINGET_FLAGS=(
  -e
  --silent
  --accept-package-agreements
  --accept-source-agreements
)

if winget list --id "$TARGET" -e >/dev/null 2>&1; then
  echo "Upgrading $TARGET..."
  winget upgrade --id "$TARGET" "${WINGET_FLAGS[@]}" || {
    code=$?

    # winget frequently returns 43 for:
    # - no upgrade available
    # - already current
    # - benign installer conditions
    if [[ $code -eq 43 ]]; then
      echo "$TARGET already current"
      exit 0
    fi

    exit "$code"
  }
else
  echo "Installing $TARGET..."
  winget install --id "$TARGET" "${WINGET_FLAGS[@]}"
fi
