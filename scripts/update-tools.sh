#!/bin/sh
# Usage: update-tools.sh <workdir> <cutoff> <changes-file>
#   Replaces bin/infection and bin/castor of <workdir> by the newest stable release published at or before <cutoff>
#   (UTC, YYYY-MM-DDTHH:MM:SSZ) when it is newer, and appends "<tool> <old> <new>" to <changes-file> for each one replaced.
set -eu

workdir=$(cd "$1" && pwd) cutoff=$2 changes=$3
root=$(cd "$(dirname "$0")/.." && pwd)
infection_key=C6D76C329EBADE2FB9C458CFC5095986493B4AA0
: "${PHP:=php}"

case $cutoff in
  [0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]T[0-2][0-9]:[0-5][0-9]:[0-5][0-9]Z) ;;
  *) echo "::error::invalid cutoff: $cutoff" >&2; exit 1 ;;
esac

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

version_of() {
  output=$(cd "$tmp" && "$PHP" "$1" --version 2>/dev/null) || return 0
  printf '%s\n' "$output" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n 1
}

is_newer() {
  [ "$1" != "$2" ] && [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -n 1)" = "$2" ]
}

release_before() {
  gh api "repos/$1/releases?per_page=50" \
    --jq "[.[] | select(.draft | not) | select(.prerelease | not) | select(.published_at <= \"$cutoff\")][0].tag_name // empty"
}

verify_infection() {
  curl -fsSL --retry 3 -o "$tmp/infection.asc" "$1.asc"
  gpgv --status-fd 1 --keyring "$root/assets/infection-release-key.gpg" "$tmp/infection.asc" "$tmp/infection" 2>/dev/null \
    | grep -q "^\[GNUPG:\] VALIDSIG $infection_key "
}

update() {
  tool=$1 upstream=$2 asset=$3
  file="$workdir/bin/$tool"
  [ -f "$file" ] || return 0
  current=$(version_of "$file")
  if [ -z "$current" ]; then
    echo "::warning::the version of bin/$tool cannot be read, so it is left as it is"
    return 0
  fi
  tag=$(release_before "$upstream")
  [ -n "$tag" ] || return 0
  latest=${tag#v}
  is_newer "$current" "$latest" || return 0

  url="https://github.com/$upstream/releases/download/$tag/$asset"
  curl -fsSL --retry 3 -o "$tmp/$tool" "$url"
  if [ "$tool" = infection ] && ! verify_infection "$url"; then
    echo "::error::the signature of infection $latest is not valid" >&2
    exit 1
  fi
  if [ "$(version_of "$tmp/$tool")" != "$latest" ]; then
    echo "::error::the downloaded $tool does not report version $latest" >&2
    exit 1
  fi

  cat "$tmp/$tool" > "$file"
  if [ "$tool" = infection ] && [ -f "$workdir/infection.json5" ]; then
    sed -i "s#infection/infection/[^/]*/resources/schema\.json#infection/infection/$latest/resources/schema.json#" "$workdir/infection.json5"
  fi
  echo "$tool $current $latest" >> "$changes"
}

update infection infection/infection infection.phar
update castor jolicode/castor castor.linux-amd64.phar
