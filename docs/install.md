[← README](../README.md)

# Install

Requires `git` and `python3` (3.9+, standard library only; both ship with the macOS CLT).
Pick one of the two options; both give the same result.

**Option 1: without cloning** (also needs `curl` and `tar`):
```sh
curl -fsSL https://raw.githubusercontent.com/milyzc/git-projects-manager/main/install.sh | bash
```
Options go after `bash -s --`, e.g. `... | bash -s -- --dry-run`:
`--ref <branch|tag>` (default `main`), `--dry-run`, `--bin-dir <dir>`.
`GIT_PROJECTS_REPO=<owner>/<repo>` installs from a fork.

**Option 2: from a clone** (for development), in any directory you choose:
```sh
git clone https://github.com/milyzc/git-projects-manager.git <clone-dir>
<clone-dir>/install.sh    # --dry-run to preview, --bin-dir <dir> to link elsewhere
```

## What gets installed
Either option installs:
- the code, in `~/.local/share/git-projects`;
- the command `~/.local/bin/git-projects`, a symlink into it, so `git projects` works;
- the manifest `~/.config/git-projects/projects.yml`, copied from `templates/projects.yml`
  only if no manifest exists yet (an existing one is never touched).

If `~/.local/bin` is not in your `PATH`, the installer prints the line to add to your shell rc
(`~/.zshrc`). Then check that it works:
```sh
git projects list
```

## Update
Run the same install command again.
- Without cloning, the tarball of `<ref>` is downloaded and replaces the previous copy only once
  the download is complete; the installed ref is recorded in `~/.local/share/git-projects/.installed-ref`.
- From a clone, `install.sh` checks out `origin/main` (or local `main` without a remote) in a
  detached worktree, so the installed command always runs `main`, whatever branch the clone has
  checked out. Re-run it after merging.

The two options do not mix: to switch from one to the other, remove `~/.local/share/git-projects`
first (the installer says so).

The manifest is read with PyYAML when it is installed; otherwise a built-in parser is used, which
only understands nested `key: value` mappings (no lists, no `{}` / `[]` flow syntax, no multi-line values).

## Install a fixed version
```sh
curl -fsSL https://raw.githubusercontent.com/milyzc/git-projects-manager/main/install.sh | bash -s -- --ref v0.1.1   # any tag from the releases page
```
Releases: https://github.com/milyzc/git-projects-manager/releases
