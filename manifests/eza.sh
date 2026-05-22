# Manifest: eza — a modern ls replacement with git/tree/icons support.
# Consumed by bin/installs/_manifest_runner.sh.
# Reference: https://github.com/eza-community/eza

NAME=eza
BIN=eza

# macOS
BREW=eza

# Windows
WINGET=eza-community.eza

# Linux — install from GitHub release (apt only has eza on Ubuntu 22.10+,
# and we want the same version across machines anyway).
GH_REPO=eza-community/eza
GH_ASSET='eza_{ARCH}.tar.gz'
GH_BIN_IN_ARCHIVE=eza
GH_ARCH_X86_64=x86_64-unknown-linux-gnu
GH_ARCH_AARCH64=aarch64-unknown-linux-gnu
