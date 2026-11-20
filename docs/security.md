[← README](../README.md)

# Security

- The manifest holds paths and public-looking URLs only. Credentials never belong in it:
  `check` and `clone` refuse `https://user:token@host/...`, usernames in https URLs and
  `?token=`-style queries, and print the URL masked.
- Clones run with `GIT_TERMINAL_PROMPT=0`: git never asks for a user/password in the terminal.
  https uses your credential helper (`git config --global credential.helper osxkeychain`, or
  `gh auth login`); ssh uses your keys / agent. An auth failure is reported and the run continues.
- The real manifest lives outside this repository (`~/.config/git-projects/`); `.gitignore`
  blocks a stray copy at the repo root. Only the commented template is versioned.
- Nothing is logged or stored by the tool itself.
