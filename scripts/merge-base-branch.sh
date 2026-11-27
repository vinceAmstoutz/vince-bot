#!/bin/bash
# Usage: merge-base-branch.sh <workdir> <base-ref> <scriptable-path>...
#   Merges <base-ref> into the branch checked out in <workdir> and leaves the merge staged, uncommitted.
#   A conflict in a <scriptable-path> where the pull request only added lines is resolved by keeping both sides:
#   the base branch's lines first, then the pull request's whole blocks (insert-both.py). Any other conflict aborts the merge, prints every
#   conflicting path on stdout and exits 3: it needs a person or an agent.
set -eu

workdir=$1 base=$2
shift 2

git -C "$workdir" merge --no-commit --no-ff "$base" > /dev/null 2>&1 && exit 0

needs_hand() {
  tr '\0' '\n' < "$conflicts"
  git -C "$workdir" merge --abort
  echo "::warning::the conflict in $1 cannot be resolved by script" >&2
  exit 3
}

scriptable=$(printf '%s\n' "$@")
conflicts=$(mktemp)
trap 'rm -f "$conflicts"' EXIT
git -C "$workdir" diff --name-only --diff-filter=U -z > "$conflicts"
while IFS= read -r -d '' path; do
  printf '%s\n' "$scriptable" | grep -qxF -- "$path" || needs_hand "$path"
done < "$conflicts"

while IFS= read -r -d '' path; do
  tmp=$(mktemp -d)
  git -C "$workdir" show ":1:$path" > "$tmp/base"
  git -C "$workdir" show ":2:$path" > "$tmp/ours"
  git -C "$workdir" show ":3:$path" > "$tmp/theirs"
  if ! python3 "$(dirname "$0")/insert-both.py" "$tmp/base" "$tmp/ours" "$tmp/theirs" > "$tmp/merged"; then
    rm -rf "$tmp"
    needs_hand "$path"
  fi
  cp "$tmp/merged" "$workdir/$path"
  git -C "$workdir" add -- "$path"
  rm -rf "$tmp"
done < "$conflicts"
