# Manifest: bat — cat clone with syntax highlighting + git integration.
# Consumed by bin/installs/_manifest_runner.sh.
# Reference: https://github.com/sharkdp/bat

NAME=bat
BIN=bat

BREW=bat
WINGET=sharkdp.bat

GH_REPO=sharkdp/bat
GH_ASSET='bat-v{VERSION}-{ARCH}.tar.gz'
GH_BIN_IN_ARCHIVE='bat-v{VERSION}-{ARCH}/bat'
GH_ARCH_X86_64=x86_64-unknown-linux-gnu
GH_ARCH_AARCH64=aarch64-unknown-linux-gnu
