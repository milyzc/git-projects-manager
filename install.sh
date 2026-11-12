#!/usr/bin/env bash
# Installs git-projects into ~/.local/share/git-projects, symlinks its bin/git-projects into
# ~/.local/bin (so `git projects` works) and creates the manifest from the template if none exists.
# From a clone: checks out main in a detached worktree. Without a clone (curl | bash): downloads <ref>.
# Usage: install.sh [--dry-run] [--bin-dir <dir>] [--ref <branch|tag>]   (re-run it to update)
set -euo pipefail

main() {
  local INSTALL_DIR="$HOME/.local/share/git-projects"
  local BIN_DIR="$HOME/.local/bin"
  local MANIFEST="${GIT_PROJECTS_FILE:-$HOME/.config/git-projects/projects.yml}"
  MANIFEST="${MANIFEST/#\~/$HOME}"
  local REPO="${GIT_PROJECTS_REPO:-milyzc/git-projects-manager}"
  local dry_run=0 ref="" ROOT="" SRC

  while [ $# -gt 0 ]; do
    case "$1" in
      --dry-run) dry_run=1; shift ;;
      --bin-dir) BIN_DIR="${2:?--bin-dir needs a value}"; shift 2 ;;
      --ref) ref="${2:?--ref needs a value}"; shift 2 ;;
      -h|--help)
        echo "Usage: install.sh [--dry-run] [--bin-dir <dir>] [--ref <branch|tag>]"
        echo "  from a clone it installs origin/main; otherwise it downloads <ref> (default main) of $REPO"
        exit 0 ;;
      *) echo "install: unknown option $1" >&2; exit 2 ;;
    esac
  done

  # clone mode when this script is a file inside a git checkout; standalone when piped (curl | bash)
  if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
    ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
    [ -e "$ROOT/.git" ] || ROOT=""
  fi

  local tools="git python3"
  [ -n "$ROOT" ] || tools="$tools curl tar"
  for tool in $tools; do
    command -v "$tool" >/dev/null 2>&1 || { echo "install: $tool is required" >&2; exit 1; }
  done

  echo "== source"
  if [ -n "$ROOT" ]; then
    [ -z "$ref" ] || { echo "install: --ref only applies without a clone; from a clone main is installed" >&2; exit 2; }
    install_from_clone "$ROOT" "$INSTALL_DIR" "$dry_run"
    SRC="$ROOT"
  else
    install_from_download "$REPO" "${ref:-main}" "$INSTALL_DIR" "$dry_run"
    SRC="$INSTALL_DIR"
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
    echo "  would: cp $SRC/templates/projects.yml $MANIFEST"
  else
    mkdir -p "$(dirname "$MANIFEST")"
    cp "$SRC/templates/projects.yml" "$MANIFEST"
    echo "  created $MANIFEST from template; add your projects there"
  fi
  echo "done. Try: git projects list"
}

# detached worktree of the clone: switching branches in the clone does not change the installed copy
install_from_clone() {
  local root="$1" dir="$2" dry_run="$3" ref
  # prefer the remote main (what has been merged); fall back to the local branch without a remote
  git -C "$root" fetch --quiet origin main 2>/dev/null || true
  if git -C "$root" rev-parse -q --verify refs/remotes/origin/main >/dev/null; then
    ref="origin/main"
  else
    ref="main"
  fi
  if [ "$dry_run" -eq 1 ]; then
    echo "  would: check out $ref (detached) in $dir"
  elif [ -e "$dir/.git" ]; then
    git -C "$dir" checkout --quiet --detach "$ref"
    echo "  $dir updated to $ref ($(git -C "$dir" rev-parse --short HEAD))"
  else
    [ ! -e "$dir" ] || { echo "install: $dir exists and is not a worktree (installed without a clone); remove it first" >&2; exit 1; }
    git -C "$root" worktree prune
    git -C "$root" worktree add --quiet --detach "$dir" "$ref"
    echo "  $dir checked out at $ref ($(git -C "$dir" rev-parse --short HEAD))"
  fi
}

# tarball of <ref> from GitHub, swapped into place only once it is complete
install_from_download() {
  local repo="$1" ref="$2" dir="$3" dry_run="$4"
  local url="https://codeload.github.com/$repo/tar.gz/$ref"
  if [ "$dry_run" -eq 1 ]; then
    echo "  would: download $url into $dir"
    return
  fi
  if [ -e "$dir/.git" ]; then
    echo "install: $dir is a worktree of a clone; run install.sh from that clone, or remove $dir first" >&2
    exit 1
  fi
  mkdir -p "$(dirname "$dir")"
  local tmp="$dir.new"
  rm -rf "$tmp"
  mkdir "$tmp"
  trap 'rm -rf "'"$tmp"'"' EXIT
  if ! curl -fsSL "$url" | tar -xz --strip-components=1 -C "$tmp"; then
    echo "install: could not download $url (does the ref exist and is the repo public?)" >&2
    exit 1
  fi
  local f
  for f in bin/git-projects templates/projects.yml; do
    [ -f "$tmp/$f" ] || { echo "install: $url has no $f" >&2; exit 1; }
  done
  printf 'ref: %s\nrepo: %s\ninstalled: %s\n' "$ref" "$repo" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >"$tmp/.installed-ref"
  rm -rf "$dir"
  mv "$tmp" "$dir"
  trap - EXIT
  echo "  $dir installed from $repo@$ref"
}

main "$@"
