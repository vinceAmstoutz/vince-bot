#!/bin/sh
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
fail() { echo "FAIL: $1" >&2; exit 1; }

repo() { # name: a repository whose 1.x and pr branches both add a CHANGELOG bullet at the same place
  r="$work/$1"
  git init -q -b 1.x "$r"
  git -C "$r" config user.email t@t
  git -C "$r" config user.name t
  printf '# Changelog\n\n## [Unreleased]\n\n### Added\n\n- Old entry.\n' > "$r/CHANGELOG.md"
  git -C "$r" add CHANGELOG.md
  git -C "$r" commit -qm base
  git -C "$r" checkout -qb pr
  printf -- '- PR entry.\n' >> "$r/CHANGELOG.md"
  git -C "$r" commit -qam pr
  git -C "$r" checkout -q 1.x
  printf -- '- Base entry.\n' >> "$r/CHANGELOG.md"
  git -C "$r" commit -qam other
  git -C "$r" checkout -q pr
}

repo union
sh "$root/scripts/merge-base-branch.sh" "$work/union" 1.x CHANGELOG.md || fail 'union conflict not resolved'
[ "$(tail -n 2 "$work/union/CHANGELOG.md")" = "$(printf -- '- Base entry.\n- PR entry.')" ] || fail "kept $(cat "$work/union/CHANGELOG.md")"
[ -z "$(git -C "$work/union" diff --name-only --diff-filter=U)" ] || fail 'conflict left unmerged'
git -C "$work/union" rev-parse -q --verify MERGE_HEAD > /dev/null || fail 'not left as a merge in progress'

repo code
status=0
sh "$root/scripts/merge-base-branch.sh" "$work/code" 1.x 2> "$work/code.err" || status=$?
[ "$status" = 3 ] || fail "a conflict outside the scriptable paths exited $status"
grep -q 'CHANGELOG.md' "$work/code.err" || fail 'the conflicting path is not named'
[ -z "$(git -C "$work/code" status --porcelain)" ] || fail 'the merge was not aborted'

repo edit
sed -i 's/Old entry/Old entry, edited by the pull request/' "$work/edit/CHANGELOG.md"
git -C "$work/edit" commit -qam edit
git -C "$work/edit" checkout -q 1.x
sed -i 's/Old entry/Old entry, edited on 1.x/' "$work/edit/CHANGELOG.md"
git -C "$work/edit" commit -qam edit
git -C "$work/edit" checkout -q pr
status=0
sh "$root/scripts/merge-base-branch.sh" "$work/edit" 1.x CHANGELOG.md 2> /dev/null || status=$?
[ "$status" = 3 ] || fail "a conflict that edits a line exited $status"
[ -z "$(git -C "$work/edit" status --porcelain)" ] || fail 'the edit merge was not aborted'

entry() { printf "    [\n        'reason' => '%s',\n        'changelog' => '%s',\n    ],\n" "$1" "$1"; }
r="$work/entries"
git init -q -b 1.x "$r"
git -C "$r" config user.email t@t
git -C "$r" config user.name t
{ echo '<?php'; echo 'return ['; entry a; echo '];'; } > "$r/list.php"
git -C "$r" add list.php
git -C "$r" commit -qm base
git -C "$r" checkout -qb pr
{ echo '<?php'; echo 'return ['; entry a; entry pr; echo '];'; } > "$r/list.php"
git -C "$r" commit -qam pr
git -C "$r" checkout -q 1.x
{ echo '<?php'; echo 'return ['; entry a; entry base; echo '];'; } > "$r/list.php"
git -C "$r" commit -qam other
git -C "$r" checkout -q pr
sh "$root/scripts/merge-base-branch.sh" "$r" 1.x list.php || fail 'entry conflict not resolved'
[ "$(cat "$r/list.php")" = "$({ echo '<?php'; echo 'return ['; entry a; entry base; entry pr; echo '];'; })" ] || fail "entries interleaved: $(cat "$r/list.php")"

echo 'merge_base_branch_test: ok'
