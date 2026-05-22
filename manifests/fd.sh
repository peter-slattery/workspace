# Manifest: fd — fast, user-friendly alternative to find.
# Consumed by bin/installs/_manifest_runner.sh.
# Reference: https://github.com/sharkdp/fd

NAME=fd
BIN=fd

BREW=fd
WINGET=sharkdp.fd

GH_REPO=sharkdp/fd
GH_ASSET='fd-v{VERSION}-{ARCH}.tar.gz'
GH_BIN_IN_ARCHIVE='fd-v{VERSION}-{ARCH}/fd'
GH_ARCH_X86_64=x86_64-unknown-linux-gnu
GH_ARCH_AARCH64=aarch64-unknown-linux-gnu
