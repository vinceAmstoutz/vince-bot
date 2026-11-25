#!/bin/sh
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
fail() { echo "FAIL: $1" >&2; exit 1; }

mkdir -p "$work/fakes"
cat > "$work/fakes/php" <<'PHP'
#!/bin/sh
grep -q 'requires PHP' "$1" && { cat "$1"; exit 1; }
cat "$1"
PHP
cat > "$work/fakes/gh" <<'GH'
#!/bin/sh
case "$2" in
  repos/infection/infection/releases*) printf '%s' "$INFECTION_RELEASES" ;;
  repos/jolicode/castor/releases*) printf '%s' "$CASTOR_RELEASES" ;;
  *) exit 1 ;;
esac | jq -r "$4"
GH
cat > "$work/fakes/curl" <<'CURL'
#!/bin/sh
while [ "$1" != -o ]; do shift; done
out=$2 url=$3
echo "$url" >> "$DOWNLOADS"
case "$url" in
  */infection.phar) tag=${url%/*}; echo "Infection version ${tag##*/}" > "$out" ;;
  */castor.linux-amd64.phar) tag=${url%/*}; tag=${tag##*/}; echo "castor ${tag#v}" > "$out" ;;
  *.asc) echo signature > "$out" ;;
  *) exit 22 ;;
esac
CURL
cat > "$work/fakes/gpgv" <<'GPGV'
#!/bin/sh
[ "$SIGNATURE" = valid ] && echo '[GNUPG:] VALIDSIG C6D76C329EBADE2FB9C458CFC5095986493B4AA0 2026-11-17 1794905578'
exit 0
GPGV
chmod +x "$work/fakes/"*
export PATH="$work/fakes:$PATH" DOWNLOADS="$work/downloads" SIGNATURE=valid
release() { printf '{"tag_name": "%s", "published_at": "%s", "draft": %s, "prerelease": %s}' "$1" "$2" "${3:-false}" "${4:-false}"; }

project() {
  rm -rf "$work/project" "$work/changes" "$DOWNLOADS"
  mkdir -p "$work/project/bin"
  : > "$work/changes"
}

project
echo 'Infection version 0.34.0' > "$work/project/bin/infection"
echo 'castor v1.6.1' > "$work/project/bin/castor"
chmod 755 "$work/project/bin/castor"
printf '{\n    "$schema": "https://raw.githubusercontent.com/infection/infection/0.33.2/resources/schema.json"\n}\n' > "$work/project/infection.json5"
INFECTION_RELEASES="[$(release 0.36.0 2026-11-24T00:00:00Z), $(release 0.35.12 2026-11-10T00:00:00Z), $(release 0.35.11 2026-11-01T00:00:00Z)]"
CASTOR_RELEASES="[$(release v2.0.0-rc1 2026-11-01T00:00:00Z false true), $(release v1.9.1 2026-10-01T00:00:00Z)]"
export INFECTION_RELEASES CASTOR_RELEASES
sh "$root/scripts/update-tools.sh" "$work/project" 2026-11-18T00:00:00Z "$work/changes" || fail 'outdated tools not updated'
[ "$(cat "$work/changes")" = "$(printf 'infection 0.34.0 0.35.12\ncastor 1.6.1 1.9.1')" ] || fail "unexpected changes: $(cat "$work/changes")"
grep -q 'Infection version 0.35.12' "$work/project/bin/infection" || fail 'infection not replaced by the release before the cutoff'
grep -q 'castor 1.9.1' "$work/project/bin/castor" || fail 'castor not replaced by the latest stable release'
[ -x "$work/project/bin/castor" ] || fail 'castor lost its executable bit'
grep -q 'infection/infection/0.35.12/resources/schema.json' "$work/project/infection.json5" || fail 'infection schema not bumped'
grep -q 'castor/releases/download/v1.9.1/castor.linux-amd64.phar' "$DOWNLOADS" || fail 'castor not downloaded from its tag'

project
echo 'Infection version 0.36.0' > "$work/project/bin/infection"
sh "$root/scripts/update-tools.sh" "$work/project" 2026-11-25T00:00:00Z "$work/changes" || fail 'up-to-date tool failed'
[ ! -s "$work/changes" ] || fail 'up-to-date tool updated'
[ ! -e "$DOWNLOADS" ] || fail 'up-to-date tool downloaded'

project
echo 'Infection version 0.36.1' > "$work/project/bin/infection"
sh "$root/scripts/update-tools.sh" "$work/project" 2026-11-25T00:00:00Z "$work/changes" || fail 'newer tool failed'
[ ! -s "$work/changes" ] || fail 'newer tool downgraded'

project
echo 'Infection version 0.34.0' > "$work/project/bin/infection"
SIGNATURE=invalid sh "$root/scripts/update-tools.sh" "$work/project" 2026-11-25T00:00:00Z "$work/changes" 2>/dev/null && fail 'invalid signature accepted'
grep -q 'Infection version 0.34.0' "$work/project/bin/infection" || fail 'infection replaced despite an invalid signature'

project
echo 'Infection version 0.34.0' > "$work/project/bin/infection"
sh "$root/scripts/update-tools.sh" "$work/project" 'yesterday"]' "$work/changes" 2>/dev/null && fail 'malformed cutoff accepted'

project
echo 'Castor requires PHP >= 8.4.0, but you are running PHP 8.3.6.' > "$work/project/bin/castor"
sh "$root/scripts/update-tools.sh" "$work/project" 2026-11-25T00:00:00Z "$work/changes" > /dev/null || fail 'unreadable version failed the run'
[ ! -s "$work/changes" ] || fail 'tool with an unreadable version updated'

echo 'update_tools_test: ok'
