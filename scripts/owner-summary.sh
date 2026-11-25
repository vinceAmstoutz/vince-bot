#!/bin/sh
# Usage: owner-summary.sh seal <summary.md> <dir>   (key in BOT_MEMORY_KEY, format of memory.sh)
#   Writes <dir>/summary.md.enc, the only form in which an audit's summary leaves the runner.
# Usage: owner-summary.sh read <run-id>             (same key; gh logged in as the owner, in a clone of the bot)
#   Prints the summaries a weekly or security audit run handed out, each under its artifact's name.
# Usage: owner-summary.sh post <summary.md> <owner> <reports-repository> <title> <run-url>   (token in GH_TOKEN)
#   Opens an issue holding the summary in the owner's private reports repository, which notifies them.
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
  post)
    summary=$2 owner=$3 reports=$4 title=$5 run_url=$6
    [ -n "$reports" ] || { echo '::error::BOT_REPORTS_REPOSITORY is not set: the owner was not told about this summary' >&2; exit 1; }
    private=$(gh api "repos/$owner/$reports" --jq .private 2>/dev/null) || private=''
    if [ "$private" != true ]; then
      echo '::error::the reports repository is not private, or the bot is not installed on it: the summary was not posted' >&2
      exit 1
    fi
    gh api "repos/$owner/$reports/issues" -f title="$title" -f body="$(cat "$summary")

---
_For @$owner · [run]($run_url)_" --silent
    ;;
  *) echo "unknown mode $mode" >&2; exit 1 ;;
esac
