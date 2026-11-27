#!/bin/sh
# Usage: conflict-comment.sh <owner> <base-branch> <head-sha> < paths
#   Prints the comment that tells <owner> a pull request conflicts in the paths read from stdin. Its first line marks
#   <head-sha>, so the bot comments once per head commit.
set -eu

owner=$1 base=$2 head=$3

echo "<!-- bot-conflicts $head -->"
echo "@$owner this pull request conflicts with \`$base\` in files the bot does not resolve:"
echo
while IFS= read -r path; do
  [ -n "$path" ] && echo "- \`$path\`"
done
