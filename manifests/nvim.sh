# Manifest: neovim — modern vim-compatible editor.
# Consumed by bin/installs/_manifest_runner.sh.
# Reference: https://neovim.io
#
# The distro package name is `neovim`, but the binary on PATH (and the
# display name we use here) is `nvim`.

NAME=nvim
BIN=nvim

APT=neovim
DNF=neovim
PACMAN=neovim
BREW=neovim
WINGET=Neovim.Neovim

CONFIG_SRC=config/nvim/init.lua
CONFIG_DST_LINUX="${XDG_CONFIG_HOME:-$HOME/.config}/nvim/init.lua"
CONFIG_DST_MACOS="${XDG_CONFIG_HOME:-$HOME/.config}/nvim/init.lua"
CONFIG_DST_WINDOWS="${LOCALAPPDATA:-$HOME/AppData/Local}/nvim/init.lua"
