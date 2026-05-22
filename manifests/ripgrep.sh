# Manifest: ripgrep — fast recursive grep.
# Consumed by bin/installs/_manifest_runner.sh.
# Reference: https://github.com/BurntSushi/ripgrep
#
# Note: the binary on PATH is `rg`, not `ripgrep` — hence BIN=rg.

NAME=ripgrep
BIN=rg

APT=ripgrep
DNF=ripgrep
PACMAN=ripgrep
BREW=ripgrep
WINGET=BurntSushi.ripgrep.MSVC

# ripgrep has no auto-discovered config path; it reads only from
# $RIPGREP_CONFIG_PATH. Keep the path identical across OSes so the env var
# below works uniformly.
CONFIG_SRC=config/ripgrep/config
CONFIG_DST_LINUX="$HOME/.config/ripgrep/config"
CONFIG_DST_MACOS="$HOME/.config/ripgrep/config"
CONFIG_DST_WINDOWS="$HOME/.config/ripgrep/config"

RC_BLOCK_NAME=ripgrep
RC_BLOCK_CONTENT='export RIPGREP_CONFIG_PATH="{CONFIG_DST}"'
