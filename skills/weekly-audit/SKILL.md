---
name: weekly-audit
description: "Audits one repository for bugs, security, performance and architecture problems with the specialist skills, and keeps at most five verified findings as issues. ALWAYS load when the weekly job runs on a checkout of the default branch. DO NOT write issues.json without this skill: it sets the proof each finding needs, the limit of five, the issue shape the workflow opens and the rule that keeps security findings out of public repositories. SKIP for the security auditor's report (use `triaging-security-findings`) and for one pull request (use `reviewing-pull-requests`)."
---

# Weekly audit

Load the `working-in-a-repository` skill first. You are checked out on the default branch. You change nothing in it.

## 1. Run the repository's checks once

Run the tests, the static analysis and the ecosystem's audit at the start. Keep their output: every pass below reuses it.

## 2. Run the four passes

Load each skill before its pass and follow its checklist. Keep the proof of every candidate.

| Order | Skill                                  | Also read                                                             |
| ----- | -------------------------------------- | --------------------------------------------------------------------- |
| 1     | The `finding-bugs` skill               | The mutation testing report, when the repository has one.             |
| 2     | The `finding-security-issues` skill    | `$AGENT_CONTEXT/security-report.json`, when it exists.                |
| 3     | The `finding-performance-issues` skill | `$AGENT_CONTEXT/slow-pages.md`, when it exists, and the CI durations. |
| 4     | The `reviewing-architecture` skill     | The rules the repository states about its structure.                  |

## 3. Give every candidate a verdict

List every candidate the passes produced, then give each one exactly one verdict from this list:

| Verdict                             | When                                                                                   |
| ----------------------------------- | -------------------------------------------------------------------------------------- |
| `keep`                              | It has the proof its skill asks for, it is concrete, and the fix is clear.             |
| `dropped: no proof`                 | You could not trigger it, measure it or trace it end to end.                           |
| `dropped: duplicate of #<number>`   | An open issue in `$AGENT_CONTEXT/open-issues.json` covers it, whatever its wording.    |
| `dropped: costs more than it saves` | The fix is larger than the problem.                                                    |
| `owner only`                        | A security finding on a public repository: it goes to `summary.md`, never to an issue. |

No other verdict exists. "Probably", "worth a look" and "to confirm" are `dropped: no proof`.

## 4. Keep at most five

Take the `keep` findings, the most valuable first, five at most. No finding is better than a weak one: do not reread the code to reach five.

Write them to `$AGENT_OUT/issues.json` as `[{"title": "...", "body": "...", "labels": ["..."]}]`, or `[]` when there is none:

- `title`: the problem in under 70 characters, in the repository's issue style.
- `body`, in this order: the area (bug, security, performance, architecture), what is wrong, where (file and line links on the default branch), the proof, why it matters, how to fix it, how to verify the fix. Then a last line: `To have the bot implement it, comment /bot implement this.`
- `labels`: only labels the repository already uses (see `$AGENT_CONTEXT/labels.json`).

## 5. Write the summary

Write `summary.md`:

- one line per pass: what you checked, what you ran, and `none found` when the pass produced nothing;
- one line per candidate with its verdict;
- the `owner only` findings in full, for the owner.

Count before you finish: the candidates equal the kept ones plus the dropped ones plus the `owner only` ones. When the numbers differ, a candidate has no verdict yet.
