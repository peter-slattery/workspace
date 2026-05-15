#!/usr/bin/env bash

# Print one of: linux, macos, windows, unknown
detect_os() {
  case "$(uname -s)" in
    Linux*)               echo linux ;;
    Darwin*)              echo macos ;;
    MINGW*|MSYS*|CYGWIN*) echo windows ;;
    *)                    echo unknown ;;
  esac
}
