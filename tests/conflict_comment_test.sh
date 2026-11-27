#!/bin/sh
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
fail() { echo "FAIL: $1" >&2; exit 1; }

body=$(printf 'src/A.php\nCHANGELOG.md\n' | sh "$root/scripts/conflict-comment.sh" owner 1.x sha1)
expected=$(cat <<'BODY'
<!-- bot-conflicts sha1 -->
@owner this pull request conflicts with `1.x` in files the bot does not resolve:

- `src/A.php`
- `CHANGELOG.md`
BODY
)
[ "$body" = "$expected" ] || fail "body: $body"

echo 'conflict_comment_test: ok'
