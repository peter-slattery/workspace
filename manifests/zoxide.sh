# Manifest: zoxide — smarter `cd` that ranks visited directories.
# Consumed by bin/installs/_manifest_runner.sh.
# Reference: https://github.com/ajeetdsouza/zoxide

NAME=zoxide
BIN=zoxide

APT=zoxide
DNF=zoxide
PACMAN=zoxide
BREW=zoxide
WINGET=ajeetdsouza.zoxide

RC_BLOCK_NAME=zoxide
RC_BLOCK_CONTENT=$(cat <<'EOF'
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init {SHELL})"
fi
EOF
)
