#!/bin/sh
# Usage: assert-verified.sh <owner/repo> <sha>...   Fails unless GitHub shows every commit as Verified.
set -eu

repo=$1
shift
[ "$#" -gt 0 ] || { echo '::error::no commit to check' >&2; exit 1; }

for sha in "$@"; do
  verified=$(gh api "repos/$repo/commits/$sha" --jq .commit.verification.verified 2>/dev/null) || verified=''
  if [ "$verified" != true ]; then
    echo "::error::commit $sha is not Verified: every commit the bot makes must be signed" >&2
    exit 1
  fi
done
