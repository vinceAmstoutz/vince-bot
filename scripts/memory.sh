#!/bin/sh
# Usage: memory.sh encrypt|decrypt <dir>   (key in BOT_MEMORY_KEY)
set -eu

mode=$1 dir=$2
header='vince-bot-memory-v1'

[ -n "${BOT_MEMORY_KEY:-}" ] || { echo 'BOT_MEMORY_KEY is not set' >&2; exit 1; }

decrypt() {
  plain=$(openssl enc -d -aes-256-cbc -pbkdf2 -iter 200000 -a -A -pass env:BOT_MEMORY_KEY -in "$1") || return 1
  [ "$(printf '%s\n' "$plain" | head -n 1)" = "$header" ] || { echo "cannot decrypt $1" >&2; return 1; }
  printf '%s\n' "$plain" | tail -n +2
}

case "$mode" in
  encrypt)
    for file in "$dir"/*.md; do
      [ -e "$file" ] || continue
      if [ -e "$file.enc" ] && [ "$(decrypt "$file.enc" 2>/dev/null)" = "$(cat "$file")" ]; then continue; fi
      { echo "$header"; cat "$file"; } | openssl enc -aes-256-cbc -pbkdf2 -iter 200000 -salt -a -A -pass env:BOT_MEMORY_KEY -out "$file.enc"
    done
    ;;
  decrypt)
    for file in "$dir"/*.md.enc; do
      [ -e "$file" ] || continue
      decrypt "$file" > "${file%.enc}"
    done
    ;;
  *) echo "unknown mode $mode" >&2; exit 1 ;;
esac
