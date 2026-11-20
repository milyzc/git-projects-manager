# git-projects-manager

[![CI](https://github.com/milyzc/git-projects-manager/actions/workflows/ci.yml/badge.svg)](https://github.com/milyzc/git-projects-manager/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Release](https://img.shields.io/github/v/release/milyzc/git-projects-manager)](https://github.com/milyzc/git-projects-manager/releases)

**All your git projects in one portable file. Keep it in your vault; rebuild any machine with one command.**

Sooner or later you set up a machine from scratch: a new laptop, a reinstall, a broken or stolen one.
Then you have to remember every repository, where it lived, its remotes, and which name, email and
signing key you commit with in each. `git-projects` keeps all of that in one small YAML file. The
file holds no secrets, so it fits next to your SSH keys in 1Password, Bitwarden or an `age`-encrypted
file. On the new machine you restore it and run `git projects clone`.

- **One file, every repo**: path, remotes, branch, submodules, status, grouped in sections (`projects-ai`, `projects-marketing`, `architecture`...).
- **Safe to re-run**: missing repos are cloned, existing ones are never overwritten.
- **Right identity everywhere**: per-section `user.name` / `user.email` / signing key written to each
  repo and its submodules, so nothing commits as `you@your-hostname.local`.
- **No dependencies**: `git` and `python3` (standard library). Works as a git subcommand: `git projects`.

## Rebuild a machine from scratch
```sh
curl -fsSL https://raw.githubusercontent.com/milyzc/git-projects-manager/main/install.sh | bash
op document get projects.yml --out-file ~/.config/git-projects/projects.yml   # or Bitwarden, age...
git projects check
git projects clone            # --protocol https if this machine has no ssh key yet
git projects list -i
```
```text
SECTION      PROJECT                STATUS    REPO     BRANCH             USER
-------      -------                ------    ----     ------             ------------
projects-ai  agent                  active    clean    main               Ada Lovelace <ada@ai-lab.example>
projects-ai  rag-service            active    dirty    main               Ada Lovelace <ada@ai-lab.example>
architecture diagrams               active    clean    main               Ada (global) <ada@studio.example>
architecture side-project           paused    missing  -                  -
```
Save the file back to the vault whenever you add a project. Recipes for 1Password, Bitwarden, `age`
and a dotfiles repo: [docs/vault.md](docs/vault.md).

## First time
```sh
curl -fsSL https://raw.githubusercontent.com/milyzc/git-projects-manager/main/install.sh | bash
git projects init             # creates ~/.config/git-projects/projects.yml from the template
$EDITOR ~/.config/git-projects/projects.yml
git projects check && git projects clone
```
Requires `git` and `python3` 3.9+. Installing from a clone, a fork or a fixed release (`--ref <tag>`),
and updating: [docs/install.md](docs/install.md).

<!-- demo: docs/demo.gif (record with vhs or asciinema) -->

## Manifest
```yaml
projects-ai:
  defaults:                        # inherited by every project in the section
    user:
      name: Ada Lovelace
      email: ada@ai-lab.example
      signingkey: ~/.ssh/ai_signing.pub
      sign: true
  agent:
    path: ~/projects-ai/agent
    remote: git@github.com:ada-lab/agent.git
architecture:
  diagrams:
    path: ~/architecture/diagrams
    remote:
      origin: git@github.com:ada/diagrams.git
      upstream: git@github.com:ada-studio/diagrams.git
    submodules: true
    status: paused                 # active (default) | paused | archived
    user:
      email: ada@studio.example
```
Every field, GPG / x509 signing and identity in submodules: [docs/manifest.md](docs/manifest.md).

## Commands
| command | what it does |
|---|---|
| `git projects` / `list` | table of every repo: state, branch, ahead/behind; `-i` shows who you commit as |
| `git projects clone` | clones what is missing; existing repos only get missing remotes, submodules and identity |
| `git projects check` | validates the manifest and reports drift on cloned repos |
| `git projects paths` | one path per line, for scripts |
| `git projects init` | creates the manifest from the template |
| `git projects version` / `help` | version / usage |

Flags (`--section`, `--status`, `--dry-run`, `--adopt`, `--protocol`), exit codes and details:
[docs/commands.md](docs/commands.md).

## Security
- Credentials never go in the manifest: URLs with a user, token or password are refused and printed masked.
- Git never prompts: https uses your credential helper (or `gh auth login`), ssh your keys / agent.
- Existing repos are never overwritten, and the tool logs or stores nothing.

Full details: [docs/security.md](docs/security.md).

## Contributing
Issues and pull requests are welcome. Before opening a PR:
```sh
tests/smoke.sh                                       # offline, uses a throwaway $HOME
shellcheck -S warning bin/git-projects install.sh tests/smoke.sh
```
Both run in CI on Linux and macOS. Update the README or `docs/` in the same PR as any behaviour change.

## License
[MIT](LICENSE)
