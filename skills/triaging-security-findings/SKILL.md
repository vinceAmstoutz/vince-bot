---
name: triaging-security-findings
description: Turn the Symfony Security Auditor's report into verified, deduplicated issues. Use after the weekly security audit has written its JSON report.
---

# Triaging security findings

Load the `working-in-a-repository` and `finding-security-issues` skills first. The auditor's JSON report is at `$AGENT_CONTEXT/security-report.json`; the open issues are in `$AGENT_CONTEXT/open-issues.json` and the repository's labels in `$AGENT_CONTEXT/labels.json`.

## Verify every finding

The auditor's attacker and reviewer agents can still be wrong. For each finding, read the code at its location, trace the input to the sink, and check the guards the report may have missed (firewall rules, voters, validation, escaping, framework defaults). Keep a finding only when you can confirm it; note the ones you dropped and why in `summary.md`.

## Deduplicate

Skip a finding already covered by an open issue (same vulnerability at the same place, whatever the wording), and merge findings that share one root cause into one issue.

## Write the issues

Write `$AGENT_OUT/issues.json` as `[{"title": "...", "body": "...", "labels": ["..."]}]`, most severe first, at most five:

- `title`: the weakness and where, under 70 characters.
- `body`: severity, the attack path with file and line links on the default branch, the impact, the fix, how to verify it, and the finding's fingerprint from the report so later runs recognise it.
- `labels`: only labels the repository already has (`security` when it exists).

When the repository is public, write no issue: put the verified findings in `summary.md` for the owner instead, and leave `issues.json` as `[]`.
