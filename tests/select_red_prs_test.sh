#!/bin/sh
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
fail() { echo "FAIL: $1" >&2; exit 1; }

pr() { # number author cross conclusion last-commit-author-login
  printf '{"number":%s,"headRefName":"b%s","headRefOid":"sha%s","author":{"login":"%s"},"isCrossRepository":%s,"statusCheckRollup":[{"__typename":"CheckRun","status":"COMPLETED","conclusion":"SUCCESS"},{"__typename":"CheckRun","status":"COMPLETED","conclusion":"%s"}],"commits":[{"authors":[{"login":"someone","email":"s@x"}]},{"authors":[{"login":"%s","email":"%s@x"}]}]}' "$1" "$1" "$1" "$2" "$3" "$4" "$5" "$5"
}

prs="[$(pr 1 app/dependabot false FAILURE dependabot),$(pr 2 app/dependabot false SUCCESS dependabot),$(pr 3 stranger false FAILURE stranger),$(pr 4 owner true FAILURE owner),$(pr 5 owner false TIMED_OUT owner),$(pr 6 app/dependabot false FAILURE 'my-bot[bot]'),$(pr 7 app/my-bot false FAILURE owner),$(pr 8 owner false CANCELLED owner)]"

selected=$(printf '%s' "$prs" | jq -c --arg owner owner --arg bot my-bot -f "$root/scripts/select-red-prs.jq")

[ "$(printf '%s' "$selected" | jq -r '[.[].number] | join(",")')" = 1,5,7 ] || fail "selected $(printf '%s' "$selected" | jq -c '[.[].number]')"
[ "$(printf '%s' "$selected" | jq -c '.[0]')" = '{"number":1,"headRefName":"b1","headRefOid":"sha1"}' ] || fail 'shape'

echo 'select_red_prs_test: ok'
