---
name: fixing-a-pull-request
description: "Makes a red pull request green: reproduces the failing check, finds the cause and fixes it within the pull request's scope, Dependabot updates that break the build included. ALWAYS load when the task is a pull request whose CI checks fail and the owner asked nothing more. DO NOT touch a failing check without this skill: a skipped test, a pinned-back version or an ignore entry turns the check green and hides the failure. SKIP when the owner asks for a change in a comment (use `handling-a-request`) and for an error from the error tracker (use `fixing-a-production-error`)."
---

# Fixing a pull request

Load the `working-in-a-repository` skill first. You are checked out on the pull request's head branch.

## 1. Understand the failure

1. Read `$AGENT_CONTEXT/pull-request.json` (title, author, base, changed files) and `$AGENT_CONTEXT/failed-checks.md` (the failing jobs and the end of their logs).
2. Reproduce the failure locally with the same command CI runs.
3. When it does not reproduce, compare the environments (PHP or Node version, extensions, services) before you change any code.

## 2. Decide whose failure it is

| The failure                                                           | Do this                                                                                |
| --------------------------------------------------------------------- | -------------------------------------------------------------------------------------- |
| Is also red on the base branch, or comes from an outage or the runner | Change nothing. Explain it in the summary.                                             |
| Passes locally and fails at random in CI                              | Find what makes it flaky and fix that. With no cause found, change nothing and say so. |
| Comes from a dependency update                                        | Follow step 3.                                                                         |
| Comes from the pull request's own code                                | Follow step 4.                                                                         |
| Needs a fix that changes the pull request's intent or design          | Change nothing. Describe the fix you propose.                                          |

## 3. Fix a dependency update

For a Dependabot pull request, or any other dependency update:

- Read the upstream release notes, changelog and upgrade guide between the old and the new version. Fetch them from the project's repository or documentation.
- Adapt the code to the breaking changes the failure points at: renamed APIs, deprecations turned into errors, changed defaults, new required configuration.
- Keep the version the pull request chose. Do not pin back, do not downgrade, do not add the package to an ignore list.
- When the update cannot work yet (a missing extension release, an upstream bug with no fix), change nothing. Explain why with the upstream link, so the owner can decide.
- For a GitHub Actions update, check the action's new inputs and outputs and its runner requirements.

## 4. Fix any other pull request

Fix what the failing check reports, within the scope of the pull request. Fix the cause the log shows, not the first line that looks wrong.

## 5. Run the check until it passes

1. Run the failing check again.
2. When it still fails, read the new output. It is often a different failure: go back to step 2 with it.
3. Stop after three fixes that leave the check red. Revert them and explain what you found.
4. Then run the repository's fast checks, and review your own diff as the `working-in-a-repository` skill says.

## Never

- Skip, delete or weaken a test.
- Add an ignore entry, a suppression or a baseline line.
- Lower a threshold or a required version.
- Rerun a check until it turns green and call that a fix.

## 6. Write the outputs

Write `summary.md` with the root cause, the fix and the commands you ran with their results. Write `commit-message.txt` when you changed files.
