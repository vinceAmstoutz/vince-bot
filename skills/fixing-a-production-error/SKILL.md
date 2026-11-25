---
name: fixing-a-production-error
description: "Fixes an error reported by the error tracker (Bugsink or Sentry), from its stack trace to a tested fix in a pull request, without leaking event data. ALWAYS load when the errors job hands over a production error in $AGENT_CONTEXT/error.md. DO NOT read an event or write a fix without this skill: events hold personal data that must never reach code, tests, commits or pull requests, and a broad catch hides an error instead of fixing it. SKIP for a failing CI check (use `fixing-a-pull-request`) and for a slow page (use `finding-performance-issues`)."
---

# Fixing a production error

Load the `working-in-a-repository` skill and the `finding-bugs` skill first. You are checked out on the default branch. The error, its latest events and the stack trace of the newest one are in `$AGENT_CONTEXT/error.md`.

## Privacy first

Events can hold personal data: request bodies, headers, cookies, user ids, emails, local variables.

- Use them to understand the bug.
- Never copy them into code, tests, commit messages, pull requests or comments.
- Describe the failing input in general terms: "an empty `name` field", "a GitHub API timeout".
- Build the test data yourself.

## 1. Understand

1. Read the exception type, its message and the in-app frames of the stack trace, from the top frame down to the entry point (controller, command, message handler).
2. Read that code in the checkout. Find the input or the state that makes it fail.
3. Read the first and last seen dates and the count. A burst after a deploy points at a recent change: `git log --since=<first seen minus a few days>`. A steady trickle points at an edge case or an unreliable dependency.

## 2. Decide what it is

| The error is                                                                         | Do this                                                                                                                           |
| ------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------- |
| A bug in this code                                                                   | Fix it, step 3.                                                                                                                   |
| An expected failure handled badly: a remote API down, a client sending garbage       | Handle it, step 3: a timeout and a fallback, or a validation and a 4xx.                                                           |
| Noise from outside: a scanner hitting routes that do not exist                       | Change nothing. Say why in `summary.md`.                                                                                          |
| A fix that needs a decision: a design change, a dependency upgrade, a product choice | Change nothing. Explain the cause and the options in `summary.md`. The workflow opens an issue with it instead of a pull request. |

## 3. Fix

1. Write a failing test that reproduces the failure, at the highest suite the repository allows. Watch it fail with the same exception as the event.
2. Fix the root cause with the smallest change: validate the input, handle the remote failure with a timeout and a fallback, or fix the logic.
3. Run the test, then the repository's checks. When one fails, fix the cause and run it again until it passes.
4. Review your own diff as the `working-in-a-repository` skill says.

## Never

- Hide the error with a broad `catch` that swallows it. Log an expected failure at the right level instead.
- Fix the line of the top frame when the wrong value comes from a caller: fix where the value becomes wrong.
- Write a test that passes without your fix.

## 4. Write the outputs

- `pull-request.json`, following the repository's pull request rules: a title, and a body with the bot's description block, what the error was in general terms (no event data), the root cause, the fix and the test.
- `commit-message.txt` and `summary.md`.
