#!/bin/sh
# Usage: owner-summary.sh seal <summary.md> <dir>   (key in BOT_MEMORY_KEY, format of memory.sh)
#   Writes <dir>/summary.md.enc, the only form in which an audit's summary leaves the runner.
# Usage: owner-summary.sh read <run-id>             (same key; gh logged in as the owner, in a clone of the bot)
#   Prints the summaries a weekly or security audit run handed out, each under its artifact's name.
set -eu

mode=$1
memory="$(dirname "$0")/memory.sh"
block=16384

case "$mode" in
  seal)
    summary=$2 dir=$3
    work=$(mktemp -d)
    trap 'rm -rf "$work"' EXIT
    cp "$summary" "$work/summary.md"
    # Blank lines fill the summary up to the next 16 KiB, so the public artifact's size does not tell a finding from
    # none; memory.sh drops them when it decrypts.
    size=$(wc -c < "$work/summary.md")
    head -c $(((block - size % block) % block)) /dev/zero | tr '\0' '\n' >> "$work/summary.md"
    sh "$memory" encrypt "$work"
    mkdir -p "$dir"
    mv "$work/summary.md.enc" "$dir/summary.md.enc"
    ;;
  read)
    run=$2
    work=$(mktemp -d)
    trap 'rm -rf "$work"' EXIT
    gh run download "$run" --pattern 'owner-summary-*' --dir "$work"
    for sealed in "$work"/*/summary.md.enc; do
      [ -e "$sealed" ] || continue
      sh "$memory" decrypt "$(dirname "$sealed")"
      printf '# %s\n\n' "$(basename "$(dirname "$sealed")")"
      cat "${sealed%.enc}"
      echo
    done
    ;;
  *) echo "unknown mode $mode" >&2; exit 1 ;;
esac
