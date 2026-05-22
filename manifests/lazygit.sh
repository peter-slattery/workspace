# Manifest: lazygit — terminal UI for git.
# Consumed by bin/installs/_manifest_runner.sh.
# Reference: https://github.com/jesseduffield/lazygit

NAME=lazygit
BIN=lazygit

BREW=lazygit
WINGET=JesseDuffield.lazygit

# Ubuntu apt's lazygit is too old; always pull from GitHub on Linux.
GH_REPO=jesseduffield/lazygit
GH_ASSET='lazygit_{VERSION}_Linux_{ARCH}.tar.gz'
GH_BIN_IN_ARCHIVE=lazygit
GH_ARCH_X86_64=x86_64
GH_ARCH_AARCH64=arm64

CONFIG_SRC=config/lazygit/config.yml
CONFIG_DST_LINUX="${XDG_CONFIG_HOME:-$HOME/.config}/lazygit/config.yml"
CONFIG_DST_MACOS="$HOME/Library/Application Support/lazygit/config.yml"
CONFIG_DST_WINDOWS="${APPDATA:-$HOME/AppData/Roaming}/lazygit/config.yml"
