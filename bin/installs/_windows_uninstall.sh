#!/usr/bin/env bash

TARGET=$1
if winget list --id $TARGET -e >/dev/null 2>&1; then
    echo "uninstalling..."
  winget uninstall --id $TARGET -e --silent \
    --accept-source-agreements || true
fi
