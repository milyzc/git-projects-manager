[← README](../README.md)

# Commands

| command | what it does |
|---|---|
| `git projects [list] [--section s] [--status st] [--identity]` | the default command. Table with repo state (`missing`, `not-git`, `clean`, `dirty`, `no-path`; a trailing `*` means no remote declared), branch and ahead/behind (`+n -m`, no fetch). `--identity` (`-i`) swaps the path column for the `name <email>` each repo commits with: `(global)` marks a value inherited from your git config, `!` one that differs from the manifest, `(unset)` a missing one. `[signed]` means `commit.gpgsign` is on; `[!signed]` / `[!unsigned]` that it differs from the manifest's `sign:`; `!sub` that a submodule would commit with other values (details in `check`) |
| `git projects clone [--section s] [--status st] [--dry-run] [--adopt] [--protocol ssh\|https]` | clones every project whose path does not exist or is an empty directory; existing repos are skipped and only get missing remotes, submodules and `user:` identity / signing config added. Skips `archived` by default. |
| `git projects paths [--section s] [--status st]` | one path per line for the repos present on disk (`for d in $(git projects paths); do ...`) |
| `git projects check` | validates the manifest: syntax, required fields, duplicate paths, credentials in URLs. On cloned repos it also warns about remote URL drift, remotes not yet added, uninitialized submodules and missing or differing identity / signing config, in the repo and in each initialized submodule, plus a missing submodule identity include. It also rejects a private key as `signingkey` and warns when the ssh key file does not exist or the gpg secret key is not on this machine |
| `git projects init` | creates the manifest from the template if it does not exist |
| `git projects version` (or `--version`, `-V`) | prints the version |
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
