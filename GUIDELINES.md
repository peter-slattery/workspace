# Development Guidelines

Notes to guide development of this repo. Read this before making changes.

## Core Principles

- **Cross-platform**: This repo must work out of the box on Windows, macOS, and Linux. The only required step after cloning is running `bin/start.sh`.
- **Bash for scripts**: All scripts in this repo are written in bash. On Windows, they are run via git-bash (which ships with Git for Windows). Do not introduce PowerShell, batch, or other script languages.
- **Target the OS default interactive shell**: When wiring shell init (rc-file blocks, `--bash`/`--zsh` flags, `init bash`/`init zsh`), match the platform default — zsh on macOS, bash on Linux and git-bash on Windows. The `rc_shell_name` and `RC_FILE` helpers in `bin/utils/shell_rc.sh` encode this; use them rather than hard-coding bash.
- **Consistent environment**: The working environment produced by `bin/start.sh` should be mostly identical across OSes. A user moving between Linux, macOS, and Windows should see the same tools, versions, and behavior.

## Implications

- Avoid GNU-only flags (e.g. `sed -i` without an extension argument, `readlink -f`, `date` extensions) unless you provide a portable wrapper. macOS ships BSD userland; git-bash on Windows ships a MinGW subset.
- Don't assume tool availability — detect or install. Common gaps: `realpath`, `gnu-sed`, `coreutils`, `wget`, `jq`.
- Prefer paths built with `/` and let git-bash translate. Avoid hardcoded `C:\` or `/usr/local` style paths.
- Line endings: enforce LF in `.gitattributes` so Windows checkouts don't break bash scripts.
- File permissions: scripts under `bin/` must be executable (`chmod +x`) and committed that way.
- `bin/start.sh` must be idempotent: running it repeatedly is safe. On a clean machine it sets things up; on an already-configured machine it should be a no-op, except to pick up changes since the last run. Check before you act (is the tool already installed at the right version? is the config already in place?) rather than blindly re-applying steps.
