#!/bin/sh
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
fail() { echo "FAIL: $1" >&2; exit 1; }

export BOT_MEMORY_KEY=test-key
printf 'Security: none found.\n' > "$work/summary.md"

sh "$root/scripts/owner-summary.sh" seal "$work/summary.md" "$work/sealed"
[ -s "$work/sealed/summary.md.enc" ] || fail 'sealed summary'
[ "$(ls "$work/sealed")" = summary.md.enc ] || fail 'something else than the sealed summary is handed out'
! grep -q 'none found' "$work/sealed/summary.md.enc" || fail 'plaintext in the sealed summary'

# The artifact is public: its size must not tell a summary holding a finding from one holding none.
{ printf 'Security: SQL injection in the search form.\n'; seq 1 400; } > "$work/finding.md"
sh "$root/scripts/owner-summary.sh" seal "$work/finding.md" "$work/sealed-finding"
[ "$(wc -c < "$work/sealed-finding/summary.md.enc")" = "$(wc -c < "$work/sealed/summary.md.enc")" ] || fail 'the size of the sealed summary follows its content'

BOT_MEMORY_KEY= sh "$root/scripts/owner-summary.sh" seal "$work/summary.md" "$work/unsealed" 2>/dev/null && fail 'sealed without a key'
[ ! -e "$work/unsealed" ] || fail 'a summary is handed out without a key'

# The owner reads a run's summaries with gh, which downloads each artifact into a directory named after it.
cat > "$work/gh" <<'GH'
#!/bin/sh
[ "$1 $2 $3 $4 $5 $6" = 'run download 42 --pattern owner-summary-* --dir' ] || exit 1
mkdir -p "$7/owner-summary-alpha" "$7/owner-summary-beta"
cp "$SEALED/sealed/summary.md.enc" "$7/owner-summary-alpha/"
cp "$SEALED/sealed-finding/summary.md.enc" "$7/owner-summary-beta/"
GH
chmod +x "$work/gh"
export PATH="$work:$PATH" SEALED="$work"

read=$(sh "$root/scripts/owner-summary.sh" read 42)
[ "$read" = "# owner-summary-alpha

$(cat "$work/summary.md")

# owner-summary-beta

$(cat "$work/finding.md")" ] || fail 'the summaries the owner reads are not the ones sealed'

BOT_MEMORY_KEY=wrong-key sh "$root/scripts/owner-summary.sh" read 42 > "$work/wrong" 2>/dev/null && fail 'wrong key accepted'
[ ! -s "$work/wrong" ] || fail 'something is printed with a wrong key'
sh "$root/scripts/owner-summary.sh" read 43 2>/dev/null && fail 'a run without a summary is read'

# Both audits hand their summary to the owner, and no workflow uploads anything unencrypted from this public repository.
for workflow in weekly security-audit; do
  grep -q 'scripts/owner-summary.sh seal "\$OUT/summary.md"' "$root/.github/workflows/$workflow.yaml" || fail "$workflow.yaml discards summary.md"
done
grep -h -A 6 'uses: actions/upload-artifact@' "$root"/.github/workflows/*.yaml | grep -E '^ +path:' > "$work/paths" || fail 'no workflow uploads the sealed summary'
! grep -v '\.enc$' "$work/paths" || fail 'a workflow uploads a file that is not encrypted'

echo 'owner_summary_test: ok'
