#!/usr/bin/env bash
# Usage: commit-payload.sh <workdir> <owner/repo> <branch> <expected-head-sha> <message> [pathspec...]
# File contents go through temporary files, never through arguments: Linux refuses an argument over 128 KiB.
set -euo pipefail

workdir=$1 repo=$2 branch=$3 head=$4 message=$5
shift 5

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

git -C "$workdir" add -A -- "$@"

git -C "$workdir" diff --cached --no-renames --name-only -z --diff-filter=AM -- "$@" \
  | while IFS= read -r -d '' path; do
      base64 -w0 "$workdir/$path" > "$tmp/contents"
      jq -n --arg path "$path" --rawfile contents "$tmp/contents" '{path: $path, contents: $contents}'
    done > "$tmp/additions"
git -C "$workdir" diff --cached --no-renames --name-only -z --diff-filter=D -- "$@" \
  | while IFS= read -r -d '' path; do jq -n --arg path "$path" '{path: $path}'; done > "$tmp/deletions"

jq -n \
  --arg repo "$repo" \
  --arg branch "$branch" \
  --arg head "$head" \
  --arg headline "$(printf '%s\n' "$message" | head -n 1)" \
  --arg body "$(printf '%s\n' "$message" | tail -n +3)" \
  --slurpfile additions "$tmp/additions" \
  --slurpfile deletions "$tmp/deletions" \
  '{
    query: "mutation($input: CreateCommitOnBranchInput!) { createCommitOnBranch(input: $input) { commit { oid url } } }",
    variables: {input: {
      branch: {repositoryNameWithOwner: $repo, branchName: $branch},
      expectedHeadOid: $head,
      message: ({headline: $headline} + (if $body == "" then {} else {body: $body} end)),
      fileChanges: {additions: $additions, deletions: $deletions}
    }}
  }'
