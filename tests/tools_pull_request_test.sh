#!/bin/sh
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
fail() { echo "FAIL: $1" >&2; exit 1; }

cat > "$work/template.md" <<'MD'
## Summary

<!--
Explain the change.
-->

## Type of change

<!-- Keep only the boxes you tick. -->

- [ ] Bug fix
- [ ] Refactor / internal improvement

## Target branch

- [ ] `1.x`: the next minor release
- [ ] `main`: release merges only

## Checklist

- [ ] I license this contribution under the project's MIT License (`LICENSE`)
- [ ] A bug fix comes with a test
MD

printf 'castor 1.9.1 1.10.0\n' > "$work/one"
printf 'infection 0.35.12 0.36.0\ncastor 1.9.1 1.10.0\n' > "$work/two"

out=$(sh "$root/scripts/tools-pull-request.sh" "$work/one" main)
[ "$(printf '%s' "$out" | jq -r .title)" = 'build(deps): bump castor to 1.10.0' ] || fail 'single-tool title'
[ "$(printf '%s' "$out" | jq -r .body)" = 'Updates `bin/castor` from 1.9.1 to 1.10.0, the newest release published at least 7 days ago. Dev tooling only, no user-facing change.' ] \
  || fail "plain body: $(printf '%s' "$out" | jq -r .body)"

out=$(sh "$root/scripts/tools-pull-request.sh" "$work/two" 1.x "$work/template.md")
[ "$(printf '%s' "$out" | jq -r .title)" = 'build(deps): bump infection and castor' ] || fail 'two-tool title'
expected='## Summary

Updates `bin/infection` from 0.35.12 to 0.36.0 (release signature verified) and `bin/castor` from 1.9.1 to 1.10.0, the newest releases published at least 7 days ago. Dev tooling only, no user-facing change.

## Type of change

- [x] Refactor / internal improvement

## Target branch

- [x] `1.x`: the next minor release

## Checklist

- [x] I license this contribution under the project'"'"'s MIT License (`LICENSE`)'
[ "$(printf '%s' "$out" | jq -r .body)" = "$expected" ] || fail "templated body: $(printf '%s' "$out" | jq -r .body)"

echo 'tools_pull_request_test: ok'
