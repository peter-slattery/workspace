zi() {
  local dir

  dir=$(
    zoxide query -l |
    fzf \
      --preview '
        eza --tree --level=2 --color=always {} 2>/dev/null ||
        ls -la {}
      ' \
      --preview-window=right:60%
  ) || return

  cd "$dir"
}
