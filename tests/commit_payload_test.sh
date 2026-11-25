#!/bin/sh
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

fail() { echo "FAIL: $1" >&2; exit 1; }

git -C "$work" init -q
git -C "$work" -c user.name=t -c user.email=t@t commit -q --allow-empty -m init
printf 'old\n' > "$work/kept.txt"
printf 'gone\n' > "$work/removed.txt"
git -C "$work" add -A
git -C "$work" -c user.name=t -c user.email=t@t commit -q -m base
head=$(git -C "$work" rev-parse HEAD)
printf 'new\n' > "$work/kept.txt"
printf 'added\n' > "$work/added.txt"
rm "$work/removed.txt"

payload=$(bash "$root/scripts/commit-payload.sh" "$work" owner/repo main "$head" 'fix: something')

input=$(printf '%s' "$payload" | jq '.variables.input')
[ "$(printf '%s' "$input" | jq -r '.branch.repositoryNameWithOwner')" = owner/repo ] || fail 'repository'
[ "$(printf '%s' "$input" | jq -r '.branch.branchName')" = main ] || fail 'branch'
[ "$(printf '%s' "$input" | jq -r '.expectedHeadOid')" = "$head" ] || fail 'expected head'
[ "$(printf '%s' "$input" | jq -r '.message.headline')" = 'fix: something' ] || fail 'headline'
[ "$(printf '%s' "$input" | jq -r '[.fileChanges.additions[].path] | sort | join(",")')" = added.txt,kept.txt ] || fail 'additions'
[ "$(printf '%s' "$input" | jq -r '.fileChanges.additions[] | select(.path == "kept.txt") | .contents' | base64 -d)" = new ] || fail 'contents'
[ "$(printf '%s' "$input" | jq -r '[.fileChanges.deletions[].path] | join(",")')" = removed.txt ] || fail 'deletions'

# A commit larger than one command-line argument may hold (128 KiB on Linux) still makes a payload.
for i in 1 2 3; do head -c 120000 /dev/urandom | base64 -w0 > "$work/large-$i.txt"; done
payload=$(bash "$root/scripts/commit-payload.sh" "$work" owner/repo main "$head" 'fix: something large') || fail 'a large commit makes no payload'
[ "$(printf '%s' "$payload" | jq -r '.variables.input.fileChanges.additions[] | select(.path == "large-2.txt") | .contents' | base64 -d)" = "$(cat "$work/large-2.txt")" ] || fail 'contents of a large commit'

echo 'commit_payload_test: ok'
