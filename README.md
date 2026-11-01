# git-projects-manager

Keeps a registry of the git repositories on this machine in one YAML file and clones the missing
ones. Repositories that already exist are left alone. Works as a git subcommand: `git projects`.

## Install
Requires `git` and `python3` (3.9+, standard library only; both ship with the macOS CLT).
```sh
git clone <this-repo> ~/Documents/personal/git-projects-manager
~/Documents/personal/git-projects-manager/install.sh    # --dry-run to preview, --bin-dir <dir> to link elsewhere
```
The manifest is read with PyYAML when it is installed; otherwise a built-in parser is used, which
only understands nested `key: value` mappings (no lists, no `{}` / `[]` flow syntax, no multi-line values).
`install.sh` checks out `origin/main` (or local `main` without a remote) in a detached worktree at
`~/.local/share/git-projects`, symlinks its `bin/git-projects` into `~/.local/bin` and copies
`templates/projects.yml` to `~/.config/git-projects/projects.yml` if no manifest exists yet.
The installed command always runs `main`, whatever branch the clone has checked out; re-run
`install.sh` after merging to update it.

## Manifest
Resolution order: `--file <yml>` → `$GIT_PROJECTS_FILE` → `~/.config/git-projects/projects.yml`.
To share the registry with another tool that uses the same layout (e.g. ai-memory's
`projects.yml`), point `GIT_PROJECTS_FILE` at that file; unknown keys are ignored on both sides.

```yaml
work:
  defaults:                               # reserved: not a project, inherited by the section
    user:
      name: Your Name
      email: you@work.example
      signingkey: ~/.ssh/work_signing.pub # optional: public key file, or "key::ssh-ed25519 AAAA..."
      sign: true                          # optional: commit.gpgsign + tag.gpgsign
      format: ssh                         # optional: ssh (default) | openpgp | x509
  project-a:
    path: ~/work/project-a               # required, ~ expanded
    remote: git@github.com:org/a.git     # single URL -> remote "origin"; optional: without it the
                                          # project is listed but never cloned
    status: active                        # active (default) | paused | archived
    notes: Main service
personal:
  project-b:
    path: ~/personal/project-b
    remote:                               # several named remotes
      origin: https://github.com/me/b.git # cloned from origin (or the first one)
      upstream: git@github.com:org/b.git  # added with `git remote add`
    branch: main                          # optional, passed as -b
    submodules: true                      # optional: --recurse-submodules on clone
    user:                                 # optional, overrides the section defaults per key
      email: you@personal.example
```
`user:` (from the project, or the section's `defaults:`) is written to the local git config of the
repo and of every initialized submodule, so commits there never ask for an identity and are signed
with the right key:

| `user:` key | local git config |
|---|---|
| `name`, `email` | `user.name`, `user.email` |
| `signingkey` | `user.signingkey` (`~` expanded) |
| `format` | `gpg.format`; defaults to `ssh` when `signingkey` or `sign: true` is set |
| `sign` | `commit.gpgsign` and `tag.gpgsign` |

`clone` sets each key on new repos and on existing ones where it is unset; a different value
already in a repo is left untouched with a warning. `check` reports missing or differing values.
For ssh, `signingkey` must be a `.pub` file or `key::<public key>`: a private key path is rejected.
`sign: true` without `signingkey` is only a warning, because your global config may provide the key.

Machine-wide settings stay in your global config, not in the manifest. With 1Password as the
signer, for example:
```sh
git config --global gpg.ssh.program /Applications/1Password.app/Contents/MacOS/op-ssh-sign
```
The `.pub` file only has to hold the public key (1Password: copy it from the key item). To verify
signatures locally (`git log --show-signature`), also set `gpg.ssh.allowedSignersFile`.

With `submodules: true`, `clone` passes `--recurse-submodules`; on a repo that already exists it
runs `git submodule update --init --recursive` when any submodule is still uninitialized.
`check` warns when a cloned repo has a `.gitmodules` but the manifest does not set the flag.

## Commands
| command | what it does |
|---|---|
| `git projects [list] [--section s] [--status st] [--identity]` | the default command. Table with repo state (`missing`, `not-git`, `clean`, `dirty`, `no-path`; a trailing `*` means no remote declared), branch and ahead/behind (`+n -m`, no fetch). `--identity` (`-i`) swaps the path column for the `name <email>` each repo commits with: `(global)` marks a value inherited from your git config, `!` one that differs from the manifest, `(unset)` a missing one. `[signed]` means `commit.gpgsign` is on; `[!signed]` / `[!unsigned]` that it differs from the manifest's `sign:` |
| `git projects clone [--section s] [--status st] [--dry-run] [--adopt] [--protocol ssh\|https]` | clones every project whose path does not exist or is an empty directory; existing repos are skipped and only get missing remotes, submodules and `user:` identity / signing config added. Skips `archived` by default. |
| `git projects paths [--section s] [--status st]` | one path per line for the repos present on disk (`for d in $(git projects paths); do ...`) |
| `git projects check` | validates the manifest: syntax, required fields, duplicate paths, credentials in URLs. On cloned repos it also warns about remote URL drift, remotes not yet added, uninitialized submodules and missing or differing identity / signing config. It also rejects a private key as `signingkey` and warns when the key file does not exist |
| `git projects init` | creates the manifest from the template if it does not exist |
| `git projects help` (or `-h`) | usage summary. `git projects --help` does not work: git intercepts `--help` and looks for a man page |

Every command accepts `--file <yml>` (`-f`). Short forms: `-s` for `--section`, `-n` for `--dry-run`,
`-i` for `--identity`. `--status` takes `active`, `paused`, `archived` or `all`.

A path that already holds files but no `.git` is reported as an error and left alone. With
`--adopt`, `clone` turns it into a repo instead: `git init`, the manifest remotes, a fetch, and HEAD
plus the index set to the remote branch (`branch:` or the remote's default) while every local file
stays as it is. `git status` in that repo then shows how the local files differ from the remote, and
you decide what to commit. If the remote has no commits yet, the repo is just initialized with its
remotes for you to commit and push.

When the remote is empty and the project declares `branch:`, a plain `git clone -b` would fail; `clone`
then clones without `-b` and points HEAD at that branch, ready for the first commit and push.

`--protocol` rewrites GitHub/GitLab style URLs on the fly (`git@host:org/repo.git` ⇄
`https://host/org/repo.git`) for a machine that has no ssh key, without editing the manifest.

Exit codes: `0` ok, `1` something failed (a clone, a check error), `2` bad usage, `3` a remote in
the manifest carries credentials (`list`, `clone`, `paths`; `check` reports it as an error and exits `1`).

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
