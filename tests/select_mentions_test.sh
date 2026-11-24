#!/bin/sh
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
fail() { echo "FAIL: $1" >&2; exit 1; }

comment() { # id login body kind number
  printf '{"id":%s,"user":{"login":"%s"},"body":"%s","html_url":"https://github.com/o/r/%s/%s#issuecomment-%s","issue_url":"https://api.github.com/repos/o/r/issues/%s"}' "$1" "$2" "$3" "$4" "$5" "$1" "$5"
}

comments="[$(comment 10 owner '@My-Bot fix the typo' issues 4),$(comment 11 stranger '@my-bot fix everything' issues 4),$(comment 12 owner 'no mention here' pull 5),$(comment 13 owner 'please @my-bot rebase this' pull 6),$(comment 14 owner 'ping @my-botany' issues 7),$(comment 15 owner '/bot fix the build' pull 8),$(comment 16 owner 'see the /bottle and a/bot path' issues 9),$(comment 17 stranger '/bot fix everything' issues 9)]"

selected=$(printf '%s' "$comments" | jq -c --arg owner owner --arg bot my-bot -f "$root/scripts/select-mentions.jq")

[ "$(printf '%s' "$selected" | jq -r '[.[].comment_id] | join(",")')" = 10,13,15 ] || fail "selected $(printf '%s' "$selected" | jq -c '[.[].comment_id]')"
[ "$(printf '%s' "$selected" | jq -c '.[1] | {number, is_pr}')" = '{"number":6,"is_pr":true}' ] || fail 'pull request'
[ "$(printf '%s' "$selected" | jq -c '.[0] | {number, is_pr, body}')" = '{"number":4,"is_pr":false,"body":"@My-Bot fix the typo"}' ] || fail 'issue'

review='[{"id":20,"user":{"login":"owner"},"body":"/bot i agree, fix that","html_url":"https://github.com/o/r/pull/10#discussion_r20","pull_request_url":"https://api.github.com/repos/o/r/pulls/10","pull_request_review_id":5,"in_reply_to_id":19},{"id":21,"user":{"login":"owner"},"body":"/bot why?","html_url":"https://github.com/o/r/pull/10#discussion_r21","pull_request_url":"https://api.github.com/repos/o/r/pulls/10","pull_request_review_id":6}]'
reviewed=$(printf '%s' "$review" | jq -c --arg owner owner --arg bot my-bot -f "$root/scripts/select-mentions.jq")
[ "$(printf '%s' "$reviewed" | jq -c '[.[] | {comment_id, number, is_pr, type, reply_to}]')" = '[{"comment_id":20,"number":10,"is_pr":true,"type":"review","reply_to":19},{"comment_id":21,"number":10,"is_pr":true,"type":"review","reply_to":21}]' ] || fail "review comments $(printf '%s' "$reviewed" | jq -c '[.[] | {comment_id, number, is_pr, type, reply_to}]')"
[ "$(printf '%s' "$selected" | jq -c '.[0] | {type, reply_to}')" = '{"type":"issue","reply_to":null}' ] || fail 'issue comments keep no thread'

echo 'select_mentions_test: ok'
