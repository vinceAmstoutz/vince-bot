---
name: weekly-audit
description: Audit a repository once a week for bugs, performance problems, improvements and architecture issues, and report the few that matter as issues.
---

# Weekly audit

Load the `working-in-a-repository` skill first, for how to read the repository. You are checked out on the default branch; you change nothing in it.

## Look where problems are likely

Start from what changed this week (`git log --since='8 days ago' --stat`) and from what the repository's own docs call risky or central. Then look for:

- **Bugs**: wrong results, unhandled errors, edge cases, concurrency, time zones and encodings, behavior that contradicts the docs or tests.
- **Security**: injection, authorization gaps, secrets, unsafe defaults, outdated dependencies with known advisories (run the ecosystem's audit command).
- **Performance**: repeated I/O or queries in loops, unbounded memory, missing caching or indexes, slow tests or CI steps.
- **Improvements**: dead code, duplicated logic, missing tests on critical paths, docs that no longer match the code, CI that could be faster or safer.
- **Architecture**: layer or dependency rules the repository states and the code breaks, classes doing too much, coupling that blocks a change the roadmap or issues ask for.

Run the repository's checks (tests, static analysis, audit) and use their output as evidence.

## Report only what is worth an issue

Keep at most five findings, the most valuable first. Each must be verified in the code, concrete and actionable, and not already covered by an open issue in `$AGENT_CONTEXT/open-issues.json`. No finding is better than a weak one.

Write them to `$AGENT_OUT/issues.json` as `[{"title": "...", "body": "...", "labels": ["..."]}]`:

- `title`: the problem in under 70 characters, in the repository's issue style.
- `body`: what is wrong, where (file and line links on the default branch), why it matters, how to fix it, and how to verify the fix.
- `labels`: only labels the repository already uses (see `$AGENT_CONTEXT/labels.json`), else none.

Also write `summary.md` with one line per area you checked and what you found.
