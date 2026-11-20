# Changelog

## Unreleased
- `list`: section and project columns widen to the longest name, so long section names stay aligned.
- Landing page in `site/`, deployed to GitHub Pages; README shows a `list -i` capture.
- Landing: tabbed terminal demo (`list -i`, `clone`, `check`) as real text instead of an image,
  restore commands per vault in tabs, copy buttons, 1200×630 social card and a dev.to cover.

## 0.1.1 – 2026-11-20
- README shortened to the essentials; full reference moved to `docs/` (install, manifest,
  commands, security) plus a new `docs/vault.md` with 1Password, Bitwarden, `age` and dotfiles recipes.
- Examples use `projects-ai`, `projects-marketing` and `architecture` sections.

## 0.1.0 – 2026-11-20
First public release.

- One YAML manifest for every repository of a machine, grouped in sections, meant to be kept in
  a vault and restored on a new machine.
- `clone` clones what is missing and never touches existing repos beyond adding missing remotes,
  submodules and identity; `--dry-run`, `--adopt`, `--protocol ssh|https`.
- `list` (with `--identity`), `paths`, `check`, `init`, `help`, `version`.
- Per-section and per-project `user:` identity and commit signing (ssh, openpgp, x509), also for
  current and future submodules through a managed `includeIf`.
- Credentials in remote URLs are refused and masked; git prompts are disabled.
- Installer that works from a clone or piped from `curl`.
- Fix: `paths` exited 1 when the last project in the manifest was not on disk.
