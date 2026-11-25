#!/bin/sh
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
fail() { echo "FAIL: $1" >&2; exit 1; }

# A skill holds its instructions, the references they point to and its scripts, nothing else.
for entry in "$root"/skills/*/*; do
  case "$(basename "$entry")" in
    SKILL.md | references | scripts) ;;
    *) fail "${entry#"$root"/} sits beside SKILL.md: move it to references/ or scripts/" ;;
  esac
done

# The frontmatter is what the agent sees before it loads a skill: a name and a one-line directive description.
budget=0
for skill in "$root"/skills/*/SKILL.md; do
  name=$(basename "$(dirname "$skill")")
  [ "$(sed -n 1p "$skill")" = '---' ] || fail "$name: SKILL.md must start with its frontmatter"
  frontmatter=$(awk 'NR > 1 && /^---$/ { exit } NR > 1' "$skill")
  [ "$(printf '%s\n' "$frontmatter" | cut -d: -f1 | tr '\n' ' ')" = 'name description ' ] || fail "$name: the frontmatter holds name then description, each on one line"
  [ "$(printf '%s\n' "$frontmatter" | sed -n 's/^name: //p')" = "$name" ] || fail "$name: the name must be the directory name"
  printf '%s' "$name" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)*$' || fail "$name: the name must be kebab-case"
  description=$(printf '%s\n' "$frontmatter" | sed -n 's/^description: //p')
  printf '%s' "$description" | grep -qE '^".*"$' || fail "$name: wrap the description in double quotes"
  length=$(printf '%s' "$description" | LC_ALL=C.UTF-8 wc -m)
  [ "$length" -le 1024 ] || fail "$name: the description has $length characters, the limit is 1024"
  case "$description" in *'<'* | *'>'*) fail "$name: no angle bracket in the description" ;; esac
  case "$description" in *'ALWAYS load'*) ;; *) fail "$name: the description must say 'ALWAYS load when ...'" ;; esac
  case "$description" in *'DO NOT'*) ;; *) fail "$name: the description must say 'DO NOT ... without this skill'" ;; esac
  [ "$(wc -l < "$skill")" -lt 500 ] || fail "$name: SKILL.md must stay under 500 lines, move detail to references/"
  budget=$((budget + length))
done
[ "$budget" -le 15000 ] || fail "the descriptions add up to $budget characters, the agent truncates past 15000"

# Every Markdown link and every installed-skill path points to a file that exists.
for file in "$root"/README.md "$root"/prompts/*.md "$root"/skills/*/SKILL.md "$root"/skills/*/references/*.md; do
  [ -e "$file" ] || continue
  grep -oE '\]\([^)]+\)' "$file" | sed -E 's/^\]\(//; s/\)$//; s/#.*$//' | while IFS= read -r target; do
    case "$target" in '' | http://* | https://* | mailto:*) continue ;; esac
    [ -e "$(dirname "$file")/$target" ] || fail "${file#"$root"/} links to $target, which does not exist"
  done
  grep -oE '~/\.claude/skills/[A-Za-z0-9._/-]+' "$file" | sed -E 's#^~/\.claude/skills/##; s/\.$//' | while IFS= read -r installed; do
    [ -e "$root/skills/$installed" ] || fail "${file#"$root"/} names ~/.claude/skills/$installed, which does not exist"
  done
done

# Every skill a workflow runs, and every skill another skill or prompt names, exists.
skill_names() {
  grep -hE '^[[:space:]]*skill:' "$root"/.github/workflows/*.yaml | grep -oE "(&&|\|\|) '[a-z0-9-]+'" | grep -oE '[a-z0-9-]+'
  grep -hE '^[[:space:]]*skill: [a-z0-9-]+$' "$root"/.github/workflows/*.yaml | awk '{print $2}'
  cat "$root"/prompts/*.md "$root"/skills/*/SKILL.md "$root"/skills/*/references/*.md | grep -oE '(`[a-z0-9-]+` skill|\(use `[a-z0-9-]+`\))' | grep -oE '`[a-z0-9-]+`' | tr -d '`'
}
skill_names | sort -u | while IFS= read -r name; do
  [ -f "$root/skills/$name/SKILL.md" ] || fail "the $name skill is named but skills/$name/SKILL.md does not exist"
done

# The review example is what the agent copies: it must keep the shape the workflow posts and tag every finding.
example=$(awk '/^ *````json$/ { inside = 1; next } /^ *````$/ { inside = 0 } inside' "$root/skills/reviewing-pull-requests/SKILL.md")
[ -n "$example" ] || fail 'reviewing-pull-requests: no review.json example'
printf '%s' "$example" | jq -e '(.summary | type == "string") and (.comments | length > 0) and all(.comments[]; (.path | type == "string") and (.line | type == "number") and (.body | type == "string"))' > /dev/null \
  || fail 'reviewing-pull-requests: the review.json example lost the summary, path, line or body the workflow reads'
printf '%s' "$example" | jq -e 'all(.comments[]; .body | test("^(🟠 major|⚪ nit): "))' > /dev/null \
  || fail 'reviewing-pull-requests: every comment of the review.json example starts with its severity'

echo 'skills_test: ok'
