#!/bin/sh
# Usage: git-data-merge.sh <workdir> <owner/repo> <branch> <head-sha> <base-sha> <message>
#   Commits the merge staged in <workdir> through the Git Data API, with <head-sha> and <base-sha> as parents, moves
#   <branch> onto it without force (so a push made meanwhile wins) and prints its sha. GitHub signs a commit an App
#   makes this way.
set -eu

workdir=$1 repo=$2 branch=$3 head=$4 base=$5 message=$6

head_tree=$(gh api "repos/$repo/git/commits/$head" --jq .tree.sha)
entries='[]'
for path in $(git -C "$workdir" diff --cached --no-renames --name-only HEAD); do
  mode=$(git -C "$workdir" ls-files -s -- "$path" | cut -d' ' -f1)
  if [ -n "$mode" ]; then
    blob=$(base64 -w0 "$workdir/$path" | jq -Rn '{content: input, encoding: "base64"}' \
      | gh api "repos/$repo/git/blobs" --input - --jq .sha)
    entry=$(jq -nc --arg path "$path" --arg mode "$mode" --arg sha "$blob" '{path: $path, mode: $mode, type: "blob", sha: $sha}')
  else
    mode=$(git -C "$workdir" ls-tree HEAD -- "$path" | cut -d' ' -f1)
    entry=$(jq -nc --arg path "$path" --arg mode "$mode" '{path: $path, mode: $mode, type: "blob", sha: null}')
  fi
  entries=$(printf '%s' "$entries" | jq -c --argjson entry "$entry" '. + [$entry]')
done

tree=$(jq -n --arg base "$head_tree" --argjson tree "$entries" '{base_tree: $base, tree: $tree}' \
  | gh api "repos/$repo/git/trees" --input - --jq .sha)
commit=$(jq -n --arg message "$message" --arg tree "$tree" --arg head "$head" --arg base "$base" \
  '{message: $message, tree: $tree, parents: [$head, $base]}' \
  | gh api "repos/$repo/git/commits" --input - --jq .sha)
gh api -X PATCH "repos/$repo/git/refs/heads/$branch" -f sha="$commit" -F force=false --silent
echo "$commit"
