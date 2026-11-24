#!/bin/sh
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
fail() { echo "FAIL: $1" >&2; exit 1; }

reviews='[
  {"node_id": "R1", "user": {"login": "my-bot[bot]"}, "body": "first", "submitted_at": "2026-11-20T10:00:00Z"},
  {"node_id": "R2", "user": {"login": "owner"}, "body": "looks good", "submitted_at": "2026-11-20T11:00:00Z"},
  {"node_id": "R3", "user": {"login": "my-bot[bot]"}, "body": "second", "submitted_at": "2026-11-21T10:00:00Z"},
  {"node_id": "R4", "user": {"login": "my-bot[bot]"}, "body": "", "submitted_at": "2026-11-21T11:00:00Z"},
  {"node_id": "R5", "user": {"login": "my-bot[bot]"}, "body": "latest", "submitted_at": "2026-11-22T10:00:00Z"}
]'

outdated() { printf '%s' "$reviews" | jq -c --arg bot 'my-bot[bot]' --argjson posted "$1" --argjson unresolved "$2" -f "$root/scripts/outdated-reviews.jq"; }

[ "$(outdated true 2)" = '["R1","R3"]' ] || fail "a new review hides the bot's earlier ones, got $(outdated true 2)"
[ "$(outdated false 1)" = '["R1","R3"]' ] || fail "with open threads the latest stays visible, got $(outdated false 1)"
[ "$(outdated false 0)" = '["R1","R3","R5"]' ] || fail "a clean pull request with nothing open hides them all, got $(outdated false 0)"

echo 'outdated_reviews_test: ok'
