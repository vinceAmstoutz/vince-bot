#!/bin/sh
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
fail() { echo "FAIL: $1" >&2; exit 1; }

cat > "$work/gh" <<'GH'
#!/bin/sh
for last; do :; done
case "$*" in
  *"repos/o/r/git/commits/head "*|*"repos/o/r/git/commits/head") echo head-tree; exit 0 ;;
  "api -X PATCH repos/o/r/git/refs/heads/feat/x"*) echo "ref $*" >> "$CALLS"; exit 0 ;;
esac
endpoint=$2
input=$(jq -c .)
echo "$endpoint $input" >> "$CALLS"
case "$endpoint" in
  repos/o/r/git/blobs) printf '%s' "$input" | jq -r '"blob-" + (.content | @base64d | rtrimstr("\n"))' ;;
  repos/o/r/git/trees) echo new-tree ;;
  repos/o/r/git/commits) echo merge-commit ;;
  *) exit 1 ;;
esac
GH
chmod +x "$work/gh"
export PATH="$work:$PATH" CALLS="$work/calls"

r="$work/repo"
git init -q -b 1.x "$r"
git -C "$r" config user.email t@t
git -C "$r" config user.name t
echo old > "$r/gone"
echo a > "$r/CHANGELOG.md"
git -C "$r" add .
git -C "$r" commit -qm base
git -C "$r" checkout -qb pr
echo pr > "$r/pr"
git -C "$r" add pr
git -C "$r" commit -qm pr
git -C "$r" checkout -q 1.x
echo b > "$r/CHANGELOG.md"
echo é > "$r/a résumé.md"
printf '#!/bin/sh\n' > "$r/tool"
chmod 755 "$r/tool"
git -C "$r" rm -q gone
git -C "$r" add .
git -C "$r" commit -qm other
git -C "$r" checkout -q pr
git -C "$r" merge -q --no-commit --no-ff 1.x > /dev/null

commit=$(sh "$root/scripts/git-data-merge.sh" "$r" o/r feat/x head base-sha 'Merge 1.x into feat/x')
[ "$commit" = merge-commit ] || fail "printed $commit"
grep '^repos/o/r/git/trees ' "$CALLS" | cut -d' ' -f2- | jq -e '
  .base_tree == "head-tree" and (.tree | sort_by(.path)) == [
    {path: "CHANGELOG.md", mode: "100644", type: "blob", sha: "blob-b"},
    {path: "a résumé.md", mode: "100644", type: "blob", sha: "blob-é"},
    {path: "gone", mode: "100644", type: "blob", sha: null},
    {path: "tool", mode: "100755", type: "blob", sha: "blob-#!/bin/sh"}
  ]' > /dev/null || fail "tree $(grep '^repos/o/r/git/trees ' "$CALLS")"
grep '^repos/o/r/git/commits ' "$CALLS" | cut -d' ' -f2- \
  | jq -e '.message == "Merge 1.x into feat/x" and .tree == "new-tree" and .parents == ["head", "base-sha"]' > /dev/null || fail 'commit'
grep -q 'refs/heads/feat/x -f sha=merge-commit -F force=false' "$CALLS" || fail "branch not moved without force: $(grep '^ref' "$CALLS")"

echo 'git_data_merge_test: ok'
