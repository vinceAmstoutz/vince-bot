---
name: finding-bugs
description: Hunt for real bugs (wrong results, crashes, broken edge cases, regressions) systematically and prove each one with a failing test or a reproduction. Use during the weekly audit, when reviewing a pull request, and when fixing a production error.
---

# Finding bugs

Load the `working-in-a-repository` skill first. A bug report without a reproduction is an opinion: prove every finding with a failing test, a command and its output, or a production event.

## Where to look first

- **What changed recently**: `git log --since='14 days ago' --stat`, then read the diffs. Fresh code holds most new bugs.
- **What breaks in production**: the error tracker's events when available (`$AGENT_CONTEXT/error.md`), error logs, and issues labelled as bugs.
- **Hotspots**: files that change often and are complex (`git log --format= --name-only | sort | uniq -c | sort -rn | head -30`, crossed with file size or cyclomatic complexity). Bugs cluster there.
- **Boundaries**: code that talks to the outside (HTTP clients, mail, filesystem, queues, third-party APIs, user input, environment variables).

## What to check in each piece of code

1. **Error paths**: what happens when a remote call fails, times out, returns an unexpected status or malformed JSON; exceptions swallowed or turned into a 500; a retry that duplicates side effects.
2. **Edge inputs**: empty, null, zero, negative, huge, duplicated, unsorted, Unicode and right-to-left text, very long strings, missing optional fields, unexpected types from decoded JSON.
3. **Time and locale**: time zones and daylight saving changes, `DateTime` mutation, date boundaries, locale-dependent formatting and parsing, every supported locale having its translations.
4. **State**: shared mutable state, static caches, long-running workers keeping data between requests, race conditions between concurrent requests or messages, idempotency of handlers and commands.
5. **Contracts**: a caller's assumptions against the callee's actual behaviour, nullable returns used as non-null, interfaces implemented partially, configuration keys read but never defined.
6. **Data**: validation missing or only client-side, truncation, rounding with floats for money, encoding issues, migrations that lose data.
7. **Tests that lie**: tests asserting implementation details instead of behaviour, mocks hiding a broken integration, a mutation testing report with surviving mutants on critical code.

Run the repository's static analysis and test suite first: a failing or flaky test, a new static analysis error or a surviving mutant is a lead, not noise.

## Prove it

Write the smallest failing test at the highest suite the repository allows (end-to-end over integration over unit), run it and watch it fail for the reason you expect. When you are allowed to fix, make it pass with the minimal change and run the related suites. When you only report, include the test or the reproduction command and its output in the finding.

## Do not report

Style, naming, personal preference, hypothetical issues you could not trigger, and anything a linter already enforces.
