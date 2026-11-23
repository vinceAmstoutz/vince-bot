---
name: reviewing-pull-requests
description: Review a pull request against the repository's own rules and decide what the bot says. Use for the owner's pull requests (in a checkout of the pull request) and, during the sweep, for other people's (through the API only).
---

# Reviewing pull requests

## Read the rules, then the diff

In a checkout, load the `working-in-a-repository` skill for how to read the repository, then read `$AGENT_CONTEXT/pull-request.json` and the diff (`git diff origin/<base>...HEAD`, after `git fetch origin <base>` if needed). During the sweep, read the same rule files with `gh api -X GET repos/{owner}/{repo}/contents/{path}` and the diff with `gh pr diff`.

Look for, in order, applying the checks of the specialist skills to the changed code and what it touches:

1. **Regressions and bugs** (`finding-bugs`): behavior that worked before and changes, wrong results, unhandled cases, broken error paths, race conditions. Read the callers and the tests of what changed, not only the diff.
2. **Security** (`finding-security-issues`): access control, injection, XSS, CSRF, secrets, configuration, CI workflows.
3. **Performance** (`finding-performance-issues`): remote calls or queries added to a request path, N+1 queries, lost HTTP caching, heavier assets.
4. **Architecture** (`reviewing-architecture`): broken layer or design rules the repository states, misplaced responsibilities, new coupling.
5. **Broken repository rules**: what its `CLAUDE.md`, `.claude/rules/`, skills or contributing guide forbid or require: tests, changelog entry, docs, commit and title format, pull request sections.
6. **Missing tests** for new behavior, when the repository expects them.

In a checkout, run the checks that cover the changed files when they are fast, and use failures as findings. Skip style points a linter enforces and personal preferences.

## Say only what matters

Keep findings you verified by reading the surrounding code. For each: the file and line, what goes wrong in one sentence, and a concrete fix. At most ten, most severe first.

In a checkout, write:

- `$AGENT_OUT/review.md`: the findings as a Markdown list, or the single line `No findings.` when there is nothing worth saying;
- `$AGENT_OUT/summary.md`: one line per area you checked and the checks you ran with their results.

## Keep the description accurate (owner's pull requests, in a checkout)

Compare the pull request's description (`body` in `$AGENT_CONTEXT/pull-request.json`) with the diff. When its summary is missing, empty, a leftover template, or no longer matches what the diff does, write the whole new description to `$AGENT_OUT/pr-body.md`: the current description with its summary replaced by the block described in [description-format.md](description-format.md). Keep everything else the author wrote (checklists, issue links, notes) exactly as it is. When the summary is accurate, or the block is already there and still right, write nothing.

## Sweep reviews

During the sweep, comment only when there is a finding, once per head SHA. Do not diagnose a red pull request there: the fix job handles those by Dependabot, the owner and the bot.
