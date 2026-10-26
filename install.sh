#!/usr/bin/env bash
# Installs git-projects: checks out main in a detached worktree (~/.local/share/git-projects),
# symlinks its bin/git-projects into ~/.local/bin (so `git projects` works) and creates the
# manifest from the template if none exists. Re-run it after merging to update the installed copy.
# Usage: install.sh [--dry-run] [--bin-dir <dir>]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# the installed command runs from this worktree, so switching branches in ROOT does not change it
INSTALL_DIR="$HOME/.local/share/git-projects"
BIN_DIR="$HOME/.local/bin"
MANIFEST="${GIT_PROJECTS_FILE:-$HOME/.config/git-projects/projects.yml}"
MANIFEST="${MANIFEST/#\~/$HOME}"
dry_run=0

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) dry_run=1; shift ;;
    --bin-dir) BIN_DIR="${2:?--bin-dir needs a value}"; shift 2 ;;
    -h|--help) sed -n '2,4p' "$0" | sed 's/^# //'; exit 0 ;;
    *) echo "install: unknown option $1" >&2; exit 2 ;;
  esac
done

for tool in git python3; do
  command -v "$tool" >/dev/null 2>&1 || { echo "install: $tool is required" >&2; exit 1; }
done

echo "== source"
# prefer the remote main (what has been merged); fall back to the local branch without a remote
git -C "$ROOT" fetch --quiet origin main 2>/dev/null || true
if git -C "$ROOT" rev-parse -q --verify refs/remotes/origin/main >/dev/null; then
  ref="origin/main"
else
  ref="main"
fi
if [ "$dry_run" -eq 1 ]; then
  echo "  would: check out $ref (detached) in $INSTALL_DIR"
elif [ -e "$INSTALL_DIR/.git" ]; then
  git -C "$INSTALL_DIR" checkout --quiet --detach "$ref"
  echo "  $INSTALL_DIR updated to $ref ($(git -C "$INSTALL_DIR" rev-parse --short HEAD))"
else
  git -C "$ROOT" worktree prune
  git -C "$ROOT" worktree add --quiet --detach "$INSTALL_DIR" "$ref"
  echo "  $INSTALL_DIR checked out at $ref ($(git -C "$INSTALL_DIR" rev-parse --short HEAD))"
fi

echo "== command"
if [ "$dry_run" -eq 1 ]; then
  echo "  would: mkdir -p $BIN_DIR && ln -sfn $INSTALL_DIR/bin/git-projects $BIN_DIR/git-projects"
else
  mkdir -p "$BIN_DIR"
  ln -sfn "$INSTALL_DIR/bin/git-projects" "$BIN_DIR/git-projects"
  echo "  $BIN_DIR/git-projects -> $INSTALL_DIR/bin/git-projects"
fi
case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) echo "  note: $BIN_DIR is not in PATH; add to your shell rc:  export PATH=\"$BIN_DIR:\$PATH\"" ;;
esac

echo "== manifest"
if [ -f "$MANIFEST" ]; then
  echo "  using existing $MANIFEST"
elif [ "$dry_run" -eq 1 ]; then
  echo "  would: cp $ROOT/templates/projects.yml $MANIFEST"
else
  mkdir -p "$(dirname "$MANIFEST")"
  cp "$ROOT/templates/projects.yml" "$MANIFEST"
  echo "  created $MANIFEST from template; add your projects there"
fi
echo "done. Try: git projects list"
