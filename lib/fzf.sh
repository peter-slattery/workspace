# Commands for using fzf in daily terminal use

source _fzf

# Find a directory and cd to it
fcd() {
  local target
  target=$(fd --type d | fzf_common) || return
  cd "$target"
}

# Find command in history and run it
fh() {
  local cmd
  cmd=$(history | fzf --tac | sed 's/^ *[0-9]* *//') || return
  eval "$cmd"
}

# Find and check out a branch
fbr() {
    git for-each-ref --sort=-committerdate refs/heads \
      --format='%(refname:short)' \
      | fzf_common \
      | xargs git checkout
}

# Find Files
ff() {
    fd --type f | fzf_common --preview 'bat --style=numbers --color=always --line-range :300 {}'
}

# Find and kill a process
fkill() {
    ps -eo pid,comm,%cpu,%mem \
      | sed 1d \
      | fzf_common \
      | awk '{print $1}' \
      | xargs kill -9
}

# Find a host and ssh to it
fssh() {
    host=$(grep -E "^Host " ~/.ssh/config \
      | awk '{print $2}' \
      | fzf_common)

    [ -n "$host" ] && ssh "$host"
}
