#!/bin/sh
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
fail() { echo "FAIL: $1" >&2; exit 1; }

cat > "$work/gh" <<'GH'
#!/bin/sh
case "$2" in
  repos/o/r/commits/signed) echo true ;;
  repos/o/r/commits/unsigned) echo false ;;
  *) exit 1 ;;
esac
GH
chmod +x "$work/gh"
export PATH="$work:$PATH"

sh "$root/scripts/assert-verified.sh" o/r signed || fail 'signed commit refused'
sh "$root/scripts/assert-verified.sh" o/r signed unsigned 2>/dev/null && fail 'unsigned commit accepted'
sh "$root/scripts/assert-verified.sh" o/r missing 2>/dev/null && fail 'unknown commit accepted'
sh "$root/scripts/assert-verified.sh" o/r 2>/dev/null && fail 'no commit accepted'

echo 'assert_verified_test: ok'
