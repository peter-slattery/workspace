# Manifest: delta — syntax-highlighting pager for git/diff output.
# Consumed by bin/installs/_manifest_runner.sh.
# Reference: https://github.com/dandavison/delta
#
# delta is wired into git via config/git/config and into lazygit via
# config/lazygit/config.yml — both written by their respective install
# scripts. Nothing to do at configure time here.

NAME=delta
BIN=delta

# Note: brew formula is `git-delta`, not `delta`.
BREW=git-delta
WINGET=dandavison.delta

# delta's release tags are unprefixed (e.g. "0.18.2"), so {TAG} == {VERSION}.
GH_REPO=dandavison/delta
GH_ASSET='delta-{VERSION}-{ARCH}.tar.gz'
GH_BIN_IN_ARCHIVE='delta-{VERSION}-{ARCH}/delta'
GH_ARCH_X86_64=x86_64-unknown-linux-gnu
GH_ARCH_AARCH64=aarch64-unknown-linux-gnu
