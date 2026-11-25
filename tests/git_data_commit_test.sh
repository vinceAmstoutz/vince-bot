#!/bin/sh
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
fail() { echo "FAIL: $1" >&2; exit 1; }

cat > "$work/gh" <<'GH'
#!/bin/sh
endpoint=$2
case "$endpoint" in
  repos/o/r/git/commits/head) echo base-tree; exit 0 ;;
  repos/o/r/git/refs) echo "ref $*" >> "$CALLS"; exit 0 ;;
esac
input=$(jq -c .)
echo "$endpoint $input" >> "$CALLS"
case "$endpoint" in
  repos/o/r/git/blobs) printf '%s' "$input" | jq -r '"blob-" + (.content | @base64d | rtrimstr("\n"))' ;;
  repos/o/r/git/trees) echo new-tree ;;
  repos/o/r/git/commits) echo new-commit ;;
  *) exit 1 ;;
esac
GH
chmod +x "$work/gh"
export PATH="$work:$PATH" CALLS="$work/calls"

git init -q "$work/repo"
mkdir "$work/repo/bin"
echo castor > "$work/repo/bin/castor"
echo infection > "$work/repo/bin/infection"
chmod 755 "$work/repo/bin/castor"
git -C "$work/repo" add bin

commit=$(sh "$root/scripts/git-data-commit.sh" "$work/repo" o/r tools head 'build(deps): bump castor' bin/castor bin/infection)
[ "$commit" = new-commit ] || fail "printed $commit"
grep '^repos/o/r/git/trees ' "$CALLS" | cut -d' ' -f2- | jq -e '
  .base_tree == "base-tree" and .tree == [
    {path: "bin/castor", mode: "100755", type: "blob", sha: "blob-castor"},
    {path: "bin/infection", mode: "100644", type: "blob", sha: "blob-infection"}
  ]' > /dev/null || fail 'tree does not keep each file mode'
grep '^repos/o/r/git/commits ' "$CALLS" | cut -d' ' -f2- \
  | jq -e '.message == "build(deps): bump castor" and .tree == "new-tree" and .parents == ["head"]' > /dev/null || fail 'commit'
grep -q 'ref=refs/heads/tools -f sha=new-commit' "$CALLS" || fail 'branch not created on the commit'

sh "$root/scripts/git-data-commit.sh" "$work/repo" o/r tools head message bin/untracked 2>/dev/null && fail 'untracked path accepted'

echo 'git_data_commit_test: ok'
