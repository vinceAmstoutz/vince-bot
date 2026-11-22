---
name: fixing-a-pull-request
description: Make a red pull request green, including Dependabot updates that break the build. Use when a pull request's CI checks fail.
---

# Fixing a pull request

Load the `working-in-a-repository` skill first. You are checked out on the pull request's head branch.

## Understand the failure

1. Read `$AGENT_CONTEXT/pull-request.json` (title, author, base, changed files) and `$AGENT_CONTEXT/failed-checks.md` (the failing jobs and the end of their logs).
2. Reproduce the failure locally with the same command CI runs. If it does not reproduce, compare environments (PHP/Node version, extensions, services) before changing code.
3. Rule out failures that are not this pull request's: a check also red on the base branch, an outage of an external service, a runner problem. Then change nothing and explain it in the summary.

## Fix a dependency update

For a Dependabot (or other dependency) pull request:

- Read the upstream release notes, changelog and upgrade guide between the old and the new version (fetch them from the project's repository or documentation).
- Adapt the code to the breaking changes the failure points at: renamed APIs, new deprecations turned into errors, changed defaults, new required configuration.
- Keep the version the pull request chose. Do not pin back, downgrade, or add the package to an ignore list. If the update cannot work yet (a missing extension release, an unfixed upstream bug), change nothing and explain why, with the upstream link, so the owner can decide.
- For a GitHub Actions bump, check the action's new inputs and outputs and the runner requirements.

## Fix any other pull request

Fix what the failing check reports, within the scope of the pull request. When the fix would change the pull request's intent or design, change nothing and describe the fix you propose instead.

## Finish

Run the failing check again, then the repository's fast checks. Write `summary.md` with the root cause, the fix and the commands you ran with their results, and `commit-message.txt` when you changed files.
