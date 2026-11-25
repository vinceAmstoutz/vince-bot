---
name: finding-bugs
description: "Finds real bugs (wrong results, crashes, broken edge cases, regressions) and proves each one with a failing test, a command and its output, or a production event. ALWAYS load when auditing a repository for bugs, when a pull request under review changes application code, and when fixing a production error. DO NOT report a bug without this skill: a bug with no reproduction is an opinion, and the checker drops it. SKIP for a red CI check on a pull request (use `fixing-a-pull-request`), for a slow page (use `finding-performance-issues`) and for an exploitable weakness (use `finding-security-issues`)."
---

# Finding bugs

A bug is a behaviour that is wrong for an input that can really happen. Prove every bug you report. Report nothing you could not trigger or trace.

## What you produce

| Loaded by                 | Scope                                 | Proof                                                             | Output                             |
| ------------------------- | ------------------------------------- | ----------------------------------------------------------------- | ---------------------------------- |
| The `weekly-audit` skill  | The whole repository                  | A failing test, or a command and its output                       | A candidate finding for that skill |
| A pull request review     | The changed code and the code it uses | The path through the code, with file and line; write no test file | A review comment                   |
| A production error to fix | The failing path of the stack trace   | A failing test with the same exception, then the fix              | The fix, as that task's skill says |

In a checkout, load the `working-in-a-repository` skill first.

## Where to look first

Use this order for an audit. A review and an error fix already know where to look.

- **What changed recently**: `git log --since='14 days ago' --stat`, then read the diffs. Fresh code holds most new bugs.
- **What breaks in production**: the error tracker's events when available (`$AGENT_CONTEXT/error.md`), error logs, and issues labelled as bugs.
- **Hotspots**: files that change often and are complex (`git log --format= --name-only | sort | uniq -c | sort -rn | head -30`, crossed with file size). Bugs cluster there.
- **Boundaries**: code that talks to the outside: HTTP clients, mail, filesystem, queues, third-party APIs, user input, environment variables.

Run the repository's static analysis and test suite first. A failing or flaky test, a new static analysis error or a surviving mutant is a lead, not noise.

## Checklist

Work through every check on each piece of code, in this order. Note `none found` for a check with no result. Never skip one.

1. **Error paths**: a remote call that fails, times out, returns an unexpected status or malformed JSON. An exception swallowed or turned into a 500. A retry that repeats a side effect.
2. **Edge inputs**: empty, null, zero, negative, huge, duplicated, unsorted. Unicode and right-to-left text, very long strings. A missing optional field, an unexpected type in decoded JSON.
3. **Time and locale**: time zones and daylight saving changes, `DateTime` mutation, date boundaries, locale-dependent formatting and parsing. Every supported locale has its translations.
4. **State**: shared mutable state, static caches, a long-running worker that keeps data between requests, a race between concurrent requests or messages. A handler or a command that is not idempotent.
5. **Contracts**: what the caller assumes against what the callee does. A nullable return used as non-null, an interface implemented in part, a configuration key read but never defined.
6. **Data**: validation missing or only client-side, truncation, floats used for money, encoding problems, a migration that loses data.
7. **Stored data and its readers**: when the code changes what it writes (a status, a date, a format), find the code that reads it later. Say what that reader returns for the rows written before the change.
8. **Tests that lie**: a test that asserts an implementation detail, a mock that hides a broken integration, surviving mutants on critical code.

## Proof

These count:

- A failing test at the highest suite the repository allows (end-to-end over integration over unit). Run it and watch it fail for the reason you expect.
- A command and its output, or a production event.
- For a claim about how a framework or a library behaves: the docs of the installed version (read it in `composer.lock` or `package-lock.json`), or the code in `vendor/` or `node_modules/`.
- For a symbol that is unused, renamed or missing: a `git grep` on the branch.
- For a regression: the caller that breaks, with its file and line.

These do not count:

- **A test the same change adds.** It records what the author intended, a wrong behaviour included. Check the behaviour against code the change did not touch.
- **A comment that explains the code.** It shows the author chose it on purpose. It does not show that the consequence is right. Trace the consequence in the code.
- **A type signature alone.** Types do not enforce which subset, which order or which state a call returns.

When you may fix, make the failing test pass with the smallest change, then run the related suites. When you only report, put the test or the command and its output in the finding.

## What to skip

- A problem you could not trigger or trace.
- Style, naming and personal preference: the review owns naming, a linter owns style.
- Anything the repository's linter, static analysis or type checker already reports.
- Future work and TODOs. Report what is wrong now.
