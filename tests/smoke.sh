#!/usr/bin/env bash
# Smoke test: runs every command against local file:// remotes inside a throwaway $HOME.
# No network, no changes outside the temp dir. Usage: tests/smoke.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
BIN="$ROOT/bin/git-projects"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

export HOME="$TMP/home"
export GIT_CONFIG_NOSYSTEM=1
unset GIT_PROJECTS_FILE
mkdir -p "$HOME"
git config --global user.name "Seed"
git config --global user.email "seed@example.invalid"
git config --global init.defaultBranch main

fails=0
pass() { echo "ok   $1"; }
fail() { echo "FAIL $1"; fails=$((fails + 1)); }
expect_exit() { # expect_exit <code> <label> <cmd...>
  local want="$1" label="$2" got=0
  shift 2
  "$@" >"$TMP/out" 2>&1 || got=$?
  if [ "$got" = "$want" ]; then pass "$label"; else fail "$label (exit $got, want $want)"; cat "$TMP/out"; fi
}
expect_out() { # expect_out <pattern> <label>  (greps the last command output)
  if grep -qE -- "$1" "$TMP/out"; then pass "$2"; else fail "$2 (no match: $1)"; cat "$TMP/out"; fi
}

# Two remotes with one commit each
for r in alpha beta; do
  git init -q --bare "$TMP/remotes/$r.git"
  git clone -q "$TMP/remotes/$r.git" "$TMP/seed-$r" 2>/dev/null
  echo "$r" >"$TMP/seed-$r/README"
  git -C "$TMP/seed-$r" add README
  git -C "$TMP/seed-$r" commit -qm init
  git -C "$TMP/seed-$r" push -q origin main
done

MANIFEST="$TMP/projects.yml"
cat >"$MANIFEST" <<EOF
work:
  defaults:
    user:
      name: Work Me
      email: me@work.invalid
  alpha:
    path: $TMP/code/alpha
    remote: file://$TMP/remotes/alpha.git
personal:
  beta:
    path: $TMP/code/beta
    remote: file://$TMP/remotes/beta.git
    user:
      name: Personal Me
      email: me@personal.invalid
  old:
    path: $TMP/code/old
    remote: file://$TMP/remotes/old.git
    status: archived
EOF
export GIT_PROJECTS_FILE="$MANIFEST"

expect_exit 0 "version" "$BIN" --version
expect_out '^git-projects [0-9]+\.[0-9]+\.[0-9]+$' "version format"
expect_exit 0 "help" "$BIN" help
expect_exit 2 "unknown command exits 2" "$BIN" nope
expect_exit 0 "check passes" "$BIN" check

expect_exit 0 "clone --dry-run" "$BIN" clone --dry-run
[ ! -e "$TMP/code/alpha" ] && pass "dry-run clones nothing" || fail "dry-run created a path"

expect_exit 0 "clone" "$BIN" clone
[ -d "$TMP/code/alpha/.git" ] && [ -d "$TMP/code/beta/.git" ] && pass "repos cloned" || fail "repos missing"
[ ! -e "$TMP/code/old" ] && pass "archived skipped" || fail "archived was cloned"
[ "$(git -C "$TMP/code/alpha" config --local user.email)" = "me@work.invalid" ] \
  && pass "section defaults identity" || fail "alpha identity"
[ "$(git -C "$TMP/code/beta" config --local user.email)" = "me@personal.invalid" ] \
  && pass "project identity" || fail "beta identity"

expect_exit 0 "clone again is a no-op" "$BIN" clone
expect_exit 0 "list" "$BIN" list
expect_out 'alpha.*clean' "list shows clean repo"
expect_exit 0 "list -i" "$BIN" list -i
expect_out 'Personal Me <me@personal.invalid>' "list -i shows identity"
expect_exit 0 "paths" "$BIN" paths
[ "$(wc -l <"$TMP/out" | tr -d ' ')" = 2 ] && pass "paths lists present repos" || { fail "paths count"; cat "$TMP/out"; }

echo dirty >"$TMP/code/alpha/README"
expect_exit 0 "list after edit" "$BIN" list
expect_out 'alpha.*dirty' "list shows dirty repo"

# Credentials in a URL are refused
BAD="$TMP/bad.yml"
printf 'x:\n  p:\n    path: %s/code/p\n    remote: https://user:secret@example.invalid/p.git\n' "$TMP" >"$BAD"
expect_exit 3 "credential URL refused by list" "$BIN" list --file "$BAD"
expect_exit 1 "credential URL is a check error" "$BIN" check --file "$BAD"
if grep -q secret "$TMP/out"; then fail "credential masked in output"; else pass "credential masked in output"; fi

# A non-empty folder without .git is left alone, and adopted with --adopt
ADOPT="$TMP/adopt.yml"
mkdir -p "$TMP/code/gamma"
echo local >"$TMP/code/gamma/README"
printf 'x:\n  gamma:\n    path: %s/code/gamma\n    remote: file://%s/remotes/alpha.git\n' "$TMP" "$TMP" >"$ADOPT"
expect_exit 1 "non-git folder is an error" "$BIN" clone --file "$ADOPT"
expect_exit 0 "--adopt" "$BIN" clone --adopt --file "$ADOPT"
[ -d "$TMP/code/gamma/.git" ] && [ "$(cat "$TMP/code/gamma/README")" = local ] \
  && pass "adopt keeps local files" || fail "adopt"

echo
if [ "$fails" -eq 0 ]; then echo "all passed"; else echo "$fails failed"; exit 1; fi
