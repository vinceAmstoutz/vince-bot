#!/bin/sh
# Usage: assert-no-repository-name.sh <comma-separated repository names> <file>...
# Fails when a file holds one of the names as a whole word, whatever its case.
# What the bot publishes in its own public repository must not name the repositories it watches.
set -eu

names=$1
shift

status=0
for file in "$@"; do
  [ -e "$file" ] || continue
  for name in $(printf '%s' "$names" | tr ',' ' '); do
    if grep -qiwF -- "$name" "$file"; then
      echo "::error::$(basename "$file") names the watched repository $name" >&2
      status=1
    fi
  done
done
exit "$status"
