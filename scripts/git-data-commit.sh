#!/bin/sh
# Usage: git-data-commit.sh <workdir> <owner/repo> <new-branch> <head-sha> <message> <path>...
#   Commits the paths of <workdir> on top of <head-sha> through the Git Data API, each with the mode git records for
#   it, creates <new-branch> on that commit and prints its sha. GitHub signs a commit an App makes this way.
set -eu

workdir=$1 repo=$2 branch=$3 head=$4 message=$5
shift 5

base_tree=$(gh api "repos/$repo/git/commits/$head" --jq .tree.sha)
entries='[]'
for path in "$@"; do
  mode=$(git -C "$workdir" ls-files -s -- "$path" | cut -d' ' -f1)
  [ -n "$mode" ] || { echo "::error::$path is not tracked" >&2; exit 1; }
  blob=$(base64 -w0 "$workdir/$path" | jq -Rn '{content: input, encoding: "base64"}' \
    | gh api "repos/$repo/git/blobs" --input - --jq .sha)
  entries=$(printf '%s' "$entries" | jq -c --arg path "$path" --arg mode "$mode" --arg sha "$blob" \
    '. + [{path: $path, mode: $mode, type: "blob", sha: $sha}]')
done

tree=$(jq -n --arg base "$base_tree" --argjson tree "$entries" '{base_tree: $base, tree: $tree}' \
  | gh api "repos/$repo/git/trees" --input - --jq .sha)
commit=$(jq -n --arg message "$message" --arg tree "$tree" --arg parent "$head" \
  '{message: $message, tree: $tree, parents: [$parent]}' \
  | gh api "repos/$repo/git/commits" --input - --jq .sha)
gh api "repos/$repo/git/refs" -f ref="refs/heads/$branch" -f sha="$commit" --silent
echo "$commit"
