# workspace
A clone-able working setup

## Setup
1. Clone this repo.
2. Run `bin/start.sh`. On first run it generates `~/.ssh/id_personal` and prints the pubkey.
3. Add that pubkey to your personal GitHub account: <https://github.com/settings/ssh/new>
4. Point this repo's remote at the personal SSH alias (one-time, per machine):
   ```
   git remote set-url origin git@github-personal:peter-slattery/workspace.git
   ```
5. Verify with `ssh -T git@github-personal` — it should greet you as `peter-slattery`.

Re-running `bin/start.sh` after the first time is safe and idempotent — it picks up new tools and config changes only.

## Tools
- neovim + a basic configuration
- lazygit
- ripgrep
- clang
