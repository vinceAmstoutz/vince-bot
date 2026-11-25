#!/bin/sh
# Usage: tools-pull-request.sh <changes-file> <base> [pull-request-template]
#   Prints {title, body} for the pull request of the tool updates listed in <changes-file>. With a template, the body
#   follows it: the summary under "## Summary", and of its boxes only the refactor, <base> and license ones, ticked.
set -eu

changes=$1 base=$2 template=${3:-}

tools=$(cut -d' ' -f1 "$changes" | awk 'NR > 1 { printf " and " } { printf "%s", $0 }')
if [ "$(wc -l < "$changes")" -eq 1 ]; then
  title="build(deps): bump $tools to $(cut -d' ' -f3 "$changes")"
else
  title="build(deps): bump $tools"
fi
summary="Updates $(awk '
  NR > 1 { printf " and " }
  { printf "`bin/%s` from %s to %s", $1, $2, $3; if ($1 == "infection") printf " (release signature verified)" }
' "$changes"), the newest $([ "$(wc -l < "$changes")" -eq 1 ] && echo release || echo releases) published at least 7 days ago. Dev tooling only, no user-facing change."

if [ -n "$template" ] && [ -f "$template" ]; then
  body=$(awk -v base="$base" -v summary="$summary" '
    /<!--/ { comment = 1 }
    comment { if (/-->/) comment = 0; next }
    /^## / { if (section != "" && !blank) print ""; section = $0; print; if (section == "## Summary") { print ""; print summary }; blank = 0; next }
    section == "## Summary" { next }
    /^- \[[ x]\] / {
      text = substr($0, 7)
      if (index(text, "Refactor / internal improvement") == 1 || index(text, "`" base "`") == 1 || index(text, "I license this contribution") == 1) {
        print "- [x] " text; blank = 0
      }
      next
    }
    /^[[:space:]]*$/ { if (!blank) print ""; blank = 1; next }
    { print; blank = 0 }
  ' "$template")
else
  body=$summary
fi

jq -n --arg title "$title" --arg body "$body" '{title: $title, body: $body}'
