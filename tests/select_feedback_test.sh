#!/bin/sh
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
fail() { echo "FAIL: $1" >&2; exit 1; }

reaction() { # content login date
  printf '{"content":"%s","createdAt":"%s","user":{"login":"%s"}}' "$1" "$3" "$2"
}
comment() { # login date body [reactions]
  printf '{"author":{"login":"%s"},"createdAt":"%s","body":"%s","reactions":{"nodes":[%s]}}' "$1" "$2" "$3" "${4:-}"
}
thread() { # path resolved comments
  printf '{"isResolved":%s,"isOutdated":false,"path":"%s","comments":{"nodes":[%s]}}' "$2" "$1" "$3"
}
pull_request() { # author threads
  printf '{"author":{"login":"%s"},"reviewThreads":{"nodes":[%s]}}' "$1" "$2"
}
select_feedback() { # pull requests
  printf '{"data":{"repository":{"pullRequests":{"nodes":[%s]}}}}' "$1" \
    | jq -c --arg bot my-bot --arg owner owner --arg since 2026-11-10T00:00:00Z -f "$root/scripts/select-feedback.jq"
}

declined=$(thread src/Talks.php true "$(comment my-bot 2026-11-12T08:00:00Z '🟠 major: wrong' "$(reaction THUMBS_DOWN owner 2026-11-12T09:00:00Z)")")
selected=$(select_feedback "$(pull_request owner "$declined")")
[ "$selected" = '[{"kind":"bot-finding","severity":"major","path":"src/Talks.php","resolved":true,"outdated":false,"comment":"🟠 major: wrong","reactions":["THUMBS_DOWN"],"replies":[]}]' ] || fail "a finding the owner reacted to: $selected"

silent=$(thread a.md false "$(comment my-bot 2026-11-12T08:00:00Z '⚪ nit: silent')")
stranger_only=$(thread a.md false "$(comment my-bot 2026-11-12T08:00:00Z '⚪ nit: stranger' "$(reaction THUMBS_UP stranger 2026-11-12T09:00:00Z)"),$(comment stranger 2026-11-12T09:00:00Z 'me too')")
discussed=$(thread a.md false "$(comment 'my-bot[bot]' 2026-11-12T08:00:00Z '⚪ nit: x'),$(comment owner 2026-11-12T09:00:00Z 'No, intended'),$(comment stranger 2026-11-12T09:30:00Z 'me too'),$(comment my-bot 2026-11-12T10:00:00Z 'ok')")
selected=$(select_feedback "$(pull_request owner "$silent,$stranger_only,$discussed")")
[ "$selected" = '[{"kind":"bot-finding","severity":"nit","path":"a.md","resolved":false,"outdated":false,"comment":"⚪ nit: x","reactions":[],"replies":[{"author":"owner","body":"No, intended"},{"author":"bot","body":"ok"}]}]' ] || fail "only the owner's reactions and replies count: $selected"

asked=$(thread src/B.php false "$(comment owner 2026-11-12T08:00:00Z 'Why a new helper?'),$(comment my-bot 2026-11-12T09:00:00Z 'It is used twice')")
selected=$(select_feedback "$(pull_request my-bot "$asked"),$(pull_request owner "$asked")")
[ "$selected" = '[{"kind":"owner-comment","severity":null,"path":"src/B.php","resolved":false,"outdated":false,"comment":"Why a new helper?","reactions":[],"replies":[{"author":"bot","body":"It is used twice"}]}]' ] || fail "what the owner asks on the bot's pull requests: $selected"

old=$(thread old.md true "$(comment my-bot 2026-11-01T08:00:00Z '⚪ nit: old' "$(reaction THUMBS_DOWN owner 2026-11-02T09:00:00Z)")")
revived=$(thread late.md true "$(comment my-bot 2026-11-01T08:00:00Z '⚪ nit: late' "$(reaction THUMBS_DOWN owner 2026-11-11T09:00:00Z)")")
answered_late=$(thread reply.md true "$(comment my-bot 2026-11-01T08:00:00Z '⚪ nit: reply'),$(comment owner 2026-11-11T09:00:00Z 'Not needed')")
selected=$(select_feedback "$(pull_request owner "$old,$revived,$answered_late")" | jq -c '[.[].path]')
[ "$selected" = '["late.md","reply.md"]' ] || fail "only the threads the owner touched in the period: $selected"

echo 'select_feedback_test: ok'
