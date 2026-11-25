---
name: triaging-security-findings
description: "Turns the Symfony Security Auditor's JSON report into verified, deduplicated issues. ALWAYS load after the security audit job wrote $AGENT_CONTEXT/security-report.json. DO NOT copy a finding of the report into an issue without this skill: the auditor can be wrong, every finding needs its own trace through the code, and nothing is disclosed on a public repository. SKIP for the weekly audit of the whole repository (use `weekly-audit`)."
---

# Triaging security findings

Load the `working-in-a-repository` skill and the `finding-security-issues` skill first.

| File in `$AGENT_CONTEXT` | Holds                         |
| ------------------------ | ----------------------------- |
| `security-report.json`   | The auditor's findings.       |
| `open-issues.json`       | The repository's open issues. |
| `labels.json`            | The repository's labels.      |

## 1. Verify every finding

The auditor's attacker and reviewer agents can still be wrong. For each finding of the report:

1. Read the code at its location.
2. Trace the input to the sink, file by file.
3. Look for the guards the report may have missed: firewall rules, voters, validation, escaping, framework defaults.

## 2. Give every finding a verdict

Each finding of the report gets exactly one verdict from this list:

| Verdict                  | When                                                                            |
| ------------------------ | ------------------------------------------------------------------------------- |
| `confirmed`              | You traced the attack end to end and no guard stops it.                         |
| `dropped: <guard>`       | A guard stops it. Name the guard with its file and line.                        |
| `dropped: not traced`    | You could not follow the input to the sink.                                     |
| `duplicate of #<number>` | An open issue covers the same weakness at the same place, whatever its wording. |
| `merged into <finding>`  | It shares its root cause with another confirmed finding: one issue for both.    |

No other verdict exists. A finding you found "plausible" is `dropped: not traced`.

## 3. Write the issues

Write `$AGENT_OUT/issues.json` as `[{"title": "...", "body": "...", "labels": ["..."]}]`, the most severe first, five at most:

- `title`: the weakness and where, under 70 characters.
- `body`, in this order: the severity, the attack path with file and line links on the default branch, the impact, the fix, how to verify it, and the finding's fingerprint from the report, so later runs recognise it.
- `labels`: only labels the repository already has (`security` when it exists).

When the repository is public, write no issue: leave `issues.json` as `[]` and put the confirmed findings in `summary.md` for the owner.

## 4. Write the summary

Write `summary.md` with one line per finding of the report: its fingerprint, its verdict, and the file and line that justify the verdict.

Count before you finish: the findings of the report equal the confirmed ones plus the dropped ones plus the duplicates plus the merged ones. When the numbers differ, a finding has no verdict yet.
