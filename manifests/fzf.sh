# Manifest: fzf — general-purpose fuzzy finder.
# Consumed by bin/installs/_manifest_runner.sh.
# Reference: https://github.com/junegunn/fzf

NAME=fzf
BIN=fzf

BREW=fzf
WINGET=junegunn.fzf

# Don't trust apt's fzf — Ubuntu 22.04 ships 0.29 but we need 0.48+ for the
# `fzf --bash` / `--zsh` shell-init flag the rc-block below depends on. So no
# APT/DNF/PACMAN entries: always pull from GitHub on Linux.
GH_REPO=junegunn/fzf
GH_ASSET='fzf-{VERSION}-linux_{ARCH}.tar.gz'
GH_BIN_IN_ARCHIVE=fzf
GH_ARCH_X86_64=amd64
GH_ARCH_AARCH64=arm64

# Use a single-quoted heredoc so {SHELL} stays literal until the runner
# substitutes it. The inner `fzf --{SHELL}` guard keeps the block safe even
# if an older fzf somehow ends up first on PATH.
RC_BLOCK_NAME=fzf
RC_BLOCK_CONTENT=$(cat <<'EOF'
if command -v fzf >/dev/null 2>&1 && fzf --{SHELL} >/dev/null 2>&1; then
  eval "$(fzf --{SHELL})"
  if command -v fd >/dev/null 2>&1; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
  fi
  if command -v bat >/dev/null 2>&1; then
    export FZF_CTRL_T_OPTS="--preview 'bat --color=always --line-range :200 {}' --preview-window=right:60%"
  fi
fi
EOF
)
