#!/bin/sh
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
fail() { echo "FAIL: $1" >&2; exit 1; }

printf 'Flag a query in a loop.\n' > "$work/clean.md"
printf 'As seen in the Private-Shop pull request.\n' > "$work/named.md"

status=0
message=$(sh "$root/scripts/assert-no-repository-name.sh" 'blog,private-shop' "$work/clean.md" "$work/named.md" 2>&1) || status=$?
[ "$status" = 1 ] || fail "a text naming a watched repository must be refused with status 1, got $status"
case "$message" in *named.md*private-shop*) ;; *) fail "the refusal must name the file and the repository: $message" ;; esac

printf 'Blogging is not the blog repository name used as a word here: weblog.\n' > "$work/longer.md"
sh "$root/scripts/assert-no-repository-name.sh" 'blog,private-shop' "$work/clean.md" || fail 'a text naming no repository was refused'
sh "$root/scripts/assert-no-repository-name.sh" 'weblo,loggin' "$work/longer.md" || fail 'a name inside a longer word was refused'
sh "$root/scripts/assert-no-repository-name.sh" '' "$work/named.md" || fail 'an empty list of names refused a text'
sh "$root/scripts/assert-no-repository-name.sh" 'blog' "$work/missing.md" || fail 'a missing file was refused'

echo 'assert_no_repository_name_test: ok'
