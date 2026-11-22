#!/bin/sh
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
fail() { echo "FAIL: $1" >&2; exit 1; }

export BOT_MEMORY_KEY=test-key
printf 'learned\n' > "$work/LEARNINGS.md"

sh "$root/scripts/memory.sh" encrypt "$work"
[ -s "$work/LEARNINGS.md.enc" ] || fail 'encrypted file'
! grep -q learned "$work/LEARNINGS.md.enc" || fail 'plaintext in the encrypted file'

before=$(cat "$work/LEARNINGS.md.enc")
sh "$root/scripts/memory.sh" encrypt "$work"
[ "$(cat "$work/LEARNINGS.md.enc")" = "$before" ] || fail 'unchanged memory re-encrypted'

rm "$work/LEARNINGS.md"
sh "$root/scripts/memory.sh" decrypt "$work"
[ "$(cat "$work/LEARNINGS.md")" = learned ] || fail 'round trip'

BOT_MEMORY_KEY=wrong-key sh "$root/scripts/memory.sh" decrypt "$work" 2>/dev/null && fail 'wrong key accepted'
BOT_MEMORY_KEY= sh "$root/scripts/memory.sh" decrypt "$work" 2>/dev/null && fail 'empty key accepted'

echo 'memory_test: ok'
