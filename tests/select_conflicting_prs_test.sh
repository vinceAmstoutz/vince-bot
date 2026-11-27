#!/bin/sh
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
fail() { echo "FAIL: $1" >&2; exit 1; }

pr() { # number author cross mergeable draft
  printf '{"number":%s,"headRefName":"b%s","headRefOid":"sha%s","baseRefName":"1.x","author":{"login":"%s"},"isCrossRepository":%s,"mergeable":"%s","isDraft":%s}' "$1" "$1" "$1" "$2" "$3" "$4" "$5"
}

prs="[$(pr 1 owner false CONFLICTING false),$(pr 2 owner false MERGEABLE false),$(pr 3 owner false UNKNOWN false),$(pr 4 stranger false CONFLICTING false),$(pr 5 owner true CONFLICTING false),$(pr 6 app/dependabot false CONFLICTING false),$(pr 7 app/my-bot false CONFLICTING false),$(pr 8 owner false CONFLICTING true)]"

selected=$(printf '%s' "$prs" | jq -c --arg owner owner --arg bot my-bot -f "$root/scripts/select-conflicting-prs.jq")

[ "$(printf '%s' "$selected" | jq -r '[.[].number] | join(",")')" = 1,7 ] || fail "selected $(printf '%s' "$selected" | jq -c '[.[].number]')"
[ "$(printf '%s' "$selected" | jq -c '.[0]')" = '{"number":1,"headRefName":"b1","headRefOid":"sha1","baseRefName":"1.x"}' ] || fail 'shape'

echo 'select_conflicting_prs_test: ok'
