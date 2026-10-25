# git-projects-manager

Keeps a registry of the git repositories on this machine in one YAML file and clones the missing
ones. Repositories that already exist are left alone. Works as a git subcommand: `git projects`.

## Install
Requires `git` and `python3` (3.9+, standard library only; both ship with the macOS CLT).
```sh
git clone <this-repo> ~/Documents/personal/git-projects-manager
~/Documents/personal/git-projects-manager/install.sh    # --dry-run to preview
```
`install.sh` symlinks `bin/git-projects` into `~/.local/bin` and copies `templates/projects.yml` to
`~/.config/git-projects/projects.yml` if no manifest exists yet.

## Manifest
Resolution order: `--file <yml>` → `$GIT_PROJECTS_FILE` → `~/.config/git-projects/projects.yml`.
To share the registry with another tool that uses the same layout (e.g. ai-memory's
`projects.yml`), point `GIT_PROJECTS_FILE` at that file; unknown keys are ignored on both sides.

```yaml
work:
  project-a:
    path: ~/work/project-a               # required, ~ expanded
    remote: git@github.com:org/a.git     # single URL -> remote "origin"
    status: active                        # active (default) | paused | archived
    notes: Main service
personal:
  project-b:
    path: ~/personal/project-b
    remote:                               # several named remotes
      origin: https://github.com/me/b.git # cloned from origin (or the first one)
      upstream: git@github.com:org/b.git  # added with `git remote add`
    branch: main                          # optional, passed as -b
```

## Commands
| command | what it does |
|---|---|
| `git projects list [--section s] [--status st]` | table with repo state (`missing`, `not-git`, `clean`, `dirty`), branch and ahead/behind (`+n -m`, no fetch) |
| `git projects clone [--section s] [--status st] [--dry-run] [--protocol ssh\|https]` | clones every project whose path does not exist; existing repos are skipped and only get missing remotes added. Skips `archived` by default. |
| `git projects paths [--section s] [--status st]` | one path per line for the repos present on disk (`for d in $(git projects paths); do ...`) |
| `git projects check` | validates the manifest: syntax, required fields, duplicate paths, credentials in URLs, remote URL drift in cloned repos |
| `git projects init` | creates the manifest from the template if it does not exist |

`--protocol` rewrites GitHub/GitLab style URLs on the fly (`git@host:org/repo.git` ⇄
`https://host/org/repo.git`) for a machine that has no ssh key, without editing the manifest.

Exit codes: `0` ok, `1` something failed (a clone, a check error), `2` bad usage, `3` a remote in
the manifest carries credentials.

## Security
- The manifest holds paths and public-looking URLs only. Credentials never belong in it:
  `check` and `clone` refuse `https://user:token@host/...`, usernames in https URLs and
  `?token=`-style queries, and print the URL masked.
- Clones run with `GIT_TERMINAL_PROMPT=0`: git never asks for a user/password in the terminal.
  https uses your credential helper (`git config --global credential.helper osxkeychain`, or
  `gh auth login`); ssh uses your keys / agent. An auth failure is reported and the run continues.
- The real manifest lives outside this repository (`~/.config/git-projects/`); `.gitignore`
  blocks a stray copy at the repo root. Only the commented template is versioned.
- Nothing is logged or stored by the tool itself.
