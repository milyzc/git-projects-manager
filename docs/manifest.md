[← README](../README.md)

# Manifest reference

Resolution order: `--file <yml>` → `$GIT_PROJECTS_FILE` → `~/.config/git-projects/projects.yml`.
To share the registry with another tool that uses the same layout (e.g. ai-memory's
`projects.yml`), point `GIT_PROJECTS_FILE` at that file; unknown keys are ignored on both sides.

```yaml
projects-ai:
  defaults:                               # reserved: not a project, inherited by the section
    user:
      name: Your Name
      email: you@ai-lab.example
      signingkey: ~/.ssh/ai_signing.pub   # optional: public key file, or "key::ssh-ed25519 AAAA..."
      sign: true                          # optional: commit.gpgsign + tag.gpgsign
      format: ssh                         # optional: ssh (default) | openpgp | x509
  project-a:
    path: ~/projects-ai/project-a        # required, ~ expanded
    remote: git@github.com:org/a.git     # single URL -> remote "origin"; optional: without it the
                                          # project is listed but never cloned
    status: active                        # active (default) | paused | archived
    notes: Main service
projects-marketing:
  project-b:
    path: ~/projects-marketing/project-b
    remote:                               # several named remotes
      origin: https://github.com/me/b.git # cloned from origin (or the first one)
      upstream: git@github.com:org/b.git  # added with `git remote add`
    branch: main                          # optional, passed as -b
    submodules: true                      # optional: --recurse-submodules on clone
    user:                                 # optional, overrides the section defaults per key
      email: you@marketing.example
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

GPG works the same way with `format: openpgp` (or `x509` for gpgsm) and the key ID or fingerprint
as `signingkey`; `format:` is required there, since the default is ssh:
```yaml
user:
  signingkey: 3AA5C34371567BD2
  sign: true
  format: openpgp
```
`check` asks `gpg --list-secret-keys` (or `gpgsm`, or the program set in `gpg.program` /
`gpg.<format>.program`) whether the secret key is on this machine, and warns if it is not or the
program is missing.

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

## Identity in submodules
Each submodule has its own config (`<repo>/.git/modules/<sub>/config`), so the repo's local
`user.*` does not reach it. `clone` writes the identity into the submodules that exist at that
moment, but a submodule initialized later (a pull that brings a new one, `git submodule update
--init`) would have none, and git then commits as `you@your-hostname.local` without asking.

For repos with submodules (`submodules: true` or a `.gitmodules` file), `clone` therefore also:
1. writes the `user:` config to `~/.config/git-projects/identity/<section>-<project>.gitconfig`;
2. adds `[includeIf "gitdir:<repo path>/"] path = <that file>` to
   `~/.config/git-projects/includes.gitconfig`, a file owned by this tool;
3. adds `include.path = ~/.config/git-projects/includes.gitconfig` to your global git config, once.
   Nothing else in your global config is changed.

The git dir of every submodule and worktree lives under `<repo>/.git/`, so that include covers the
repo, all its submodules (current and future) and its worktrees. Local values still win, so a
submodule with a different `user.email` keeps it and `check` warns. `check` reports a missing
include, a gitlink with no `.gitmodules` entry (it makes `git submodule` commands fail; the
submodules are listed from the index, so the others still get their config) and, for each
initialized submodule, any key whose effective value differs from the
manifest; `list -i` marks such a repo with `!sub`.

To make git refuse to commit anywhere it has no identity, instead of inventing one:
`git config --global user.useConfigOnly true`.
