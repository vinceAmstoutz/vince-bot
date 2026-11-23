---
name: weekly-audit
description: Audit a repository once a week for bugs, security, performance and architecture problems with the specialist skills, and report the few verified findings that matter as issues.
---

# Weekly audit

Load the `working-in-a-repository` skill first. You are checked out on the default branch; you change nothing in it.

## Run the specialists

Run each pass with its skill, in this order, and keep its evidence:

1. `finding-bugs`: recent changes, hotspots, error paths and edge cases; the test suite, static analysis and mutation testing as leads.
2. `finding-security-issues`: access control, injection, XSS, CSRF, secrets and configuration, abuse, dependencies, CI. Also read the security auditor's latest findings if `$AGENT_CONTEXT/security-report.json` exists.
3. `finding-performance-issues`: the request paths of the main pages and anything the code calls remotely while rendering; the slow pages in `$AGENT_CONTEXT/slow-pages.md` when it exists; CI duration.
4. `reviewing-architecture`: the rules the repository states, misplaced responsibilities, coupling, missing seams, dead weight.

Run the repository's checks (tests, static analysis, the ecosystem's audit) once at the start and reuse their output.

## Keep only what is worth an issue

At most five findings across all passes, the most valuable first. Each must be verified (a failing test, a command output, a measurement, or an end-to-end trace), concrete and actionable, and not already covered by an open issue in `$AGENT_CONTEXT/open-issues.json`. No finding is better than a weak one. Security findings on a public repository go to `summary.md` only, never to `issues.json`.

Write them to `$AGENT_OUT/issues.json` as `[{"title": "...", "body": "...", "labels": ["..."]}]`:

- `title`: the problem in under 70 characters, in the repository's issue style.
- `body`: the area (bug, security, performance, architecture), what is wrong, where (file and line links on the default branch), the evidence, why it matters, how to fix it, how to verify the fix, and a last line `To have the bot implement it, comment /bot implement this.`
- `labels`: only labels the repository already uses (see `$AGENT_CONTEXT/labels.json`).

Also write `summary.md`: one line per pass with what you checked, what you ran and what you found or dropped.
