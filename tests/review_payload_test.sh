#!/bin/sh
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
fail() { echo "FAIL: $1" >&2; exit 1; }

cat > "$work/files.json" <<'JSON'
[
  {"filename": "config/talks.yaml", "status": "modified", "patch": "@@ -3,4 +3,5 @@ talks:\n   - name: SymfonyCon\n-    city: Paris\n+    city: Amsterdam\n+    year: 2026\n     country: NL"},
  {"filename": "assets/logo.png", "status": "added"}
]
JSON
cat > "$work/review.json" <<'JSON'
{
  "summary": "Two findings.",
  "comments": [
    {"path": "config/talks.yaml", "line": 6, "body": "Wrong city.\n```suggestion\n    city: Amsterdam\n```"},
    {"path": "config/talks.yaml", "start_line": 4, "line": 5, "body": "Spans two lines."},
    {"path": "config/talks.yaml", "line": 40, "body": "Outside the diff."},
    {"path": "src/Other.php", "line": 3, "body": "Not in the pull request."}
  ]
}
JSON

payload=$(python3 -I "$root/scripts/review-payload.py" "$work/review.json" "$work/files.json" abc123 'FOOTER')

[ "$(printf '%s' "$payload" | jq -r .commit_id)" = abc123 ] || fail 'commit id'
[ "$(printf '%s' "$payload" | jq -r .event)" = COMMENT ] || fail 'event'
[ "$(printf '%s' "$payload" | jq -c '[.comments[] | [.path, .line, .side, (.start_line // null)]]')" = '[["config/talks.yaml",6,"RIGHT",null],["config/talks.yaml",5,"RIGHT",4]]' ] || fail "kept comments $(printf '%s' "$payload" | jq -c '.comments')"
printf '%s' "$payload" | jq -r '.comments[0].body' | grep -q '```suggestion' || fail 'suggestion block kept'
body=$(printf '%s' "$payload" | jq -r .body)
printf '%s' "$body" | grep -q '^Two findings\.' || fail 'summary first'
printf '%s' "$body" | grep -q 'config/talks.yaml.*40.*Outside the diff\.' || fail 'out-of-diff comment moved to the body'
printf '%s' "$body" | grep -q 'src/Other.php.*3.*Not in the pull request\.' || fail 'unknown file moved to the body'
printf '%s' "$body" | grep -q 'FOOTER$' || fail 'footer last'

python3 -I "$root/scripts/review-payload.py" "$work/review.json" "$work/files.json" abc123 'FOOTER' > /dev/null || fail 'exit status'
printf '{"summary": "No findings.", "comments": []}' > "$work/empty.json"
[ -z "$(python3 -I "$root/scripts/review-payload.py" "$work/empty.json" "$work/files.json" abc123 'FOOTER')" ] || fail 'no review without findings'

printf '{"summary": "No findings. The route list is correct and fully tested.", "comments": []}' > "$work/praise.json"
[ -z "$(python3 -I "$root/scripts/review-payload.py" "$work/praise.json" "$work/files.json" abc123 'FOOTER')" ] || fail 'no review for a summary without comments'

echo 'review_payload_test: ok'
