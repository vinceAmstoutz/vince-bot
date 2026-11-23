---
name: fixing-a-production-error
description: Fix an error reported by the error tracker (Bugsink or Sentry), from its stack trace to a tested fix. Use when the bot's errors job hands over a production error.
---

# Fixing a production error

Load the `working-in-a-repository` and `finding-bugs` skills first. You are checked out on the default branch. The error, its latest events and the stack trace of the newest one are in `$AGENT_CONTEXT/error.md`.

## Privacy first

Events can hold personal data: request bodies, headers, cookies, user ids, emails, local variables. Use them to understand the bug, and never copy them into code, tests, commit messages, pull requests or comments. Describe the failing input in general terms ("an empty `name` field", "a GitHub API timeout") and build test data yourself.

## Understand

1. Read the exception type, message and the in-app frames of the stack trace, from the top frame down to the entry point (controller, command, message handler).
2. Read that code in the checkout and find the input or state that makes it fail. Check the error's first and last seen dates and its count: a burst after a deploy points at a recent change (`git log --since=<first seen minus a few days>`), a steady trickle at an edge case or an unreliable dependency.
3. Decide whether it is a bug in this code, an expected failure handled badly (a remote API down, a bot sending garbage), or noise from outside (a scanner hitting non-existent routes). For noise, change nothing and say why in `summary.md`.

## Fix

1. Write a failing test reproducing the failure at the highest suite the repository allows, and watch it fail with the same exception.
2. Fix the root cause with the smallest change: validate the input, handle the remote failure with a timeout and a fallback, fix the logic. Never hide the error with a broad `catch` that swallows it; log it at the right level when it is expected.
3. Run the test and the repository's checks.
4. Write `pull-request.json` following the repository's pull request rules: a title, and a body with the description block of the bot's format, what the error was in general terms (no event data), the root cause, the fix and the test. Write `commit-message.txt` and `summary.md`.

When the fix needs a decision (a design change, a dependency upgrade, a product choice), change nothing and explain the cause and the options in `summary.md`: the workflow opens an issue with it instead of a pull request.
