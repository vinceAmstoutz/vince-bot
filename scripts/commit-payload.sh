#!/usr/bin/env bash
# Usage: commit-payload.sh <workdir> <owner/repo> <branch> <expected-head-sha> <message> [pathspec...]
set -eu

workdir=$1 repo=$2 branch=$3 head=$4 message=$5
shift 5

git -C "$workdir" add -A -- "$@"

additions=$(git -C "$workdir" diff --cached --no-renames --name-only -z --diff-filter=AM -- "$@" \
  | while IFS= read -r -d '' path; do
      jq -n --arg path "$path" --arg contents "$(base64 -w0 "$workdir/$path")" '{path: $path, contents: $contents}'
    done | jq -s .)
deletions=$(git -C "$workdir" diff --cached --no-renames --name-only -z --diff-filter=D -- "$@" \
  | while IFS= read -r -d '' path; do jq -n --arg path "$path" '{path: $path}'; done | jq -s .)

jq -n \
  --arg repo "$repo" \
  --arg branch "$branch" \
  --arg head "$head" \
  --arg headline "$(printf '%s\n' "$message" | head -n 1)" \
  --arg body "$(printf '%s\n' "$message" | tail -n +3)" \
  --argjson additions "$additions" \
  --argjson deletions "$deletions" \
  '{
    query: "mutation($input: CreateCommitOnBranchInput!) { createCommitOnBranch(input: $input) { commit { oid url } } }",
    variables: {input: {
      branch: {repositoryNameWithOwner: $repo, branchName: $branch},
      expectedHeadOid: $head,
      message: ({headline: $headline} + (if $body == "" then {} else {body: $body} end)),
      fileChanges: {additions: $additions, deletions: $deletions}
    }}
  }'
