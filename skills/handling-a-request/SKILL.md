---
name: handling-a-request
description: Carry out what the owner asked when they mention the bot in an issue or pull request comment, such as "/bot fix this" or "@vinceamstoutz-github-ai-bot fix this".
---

# Handling a request

Load the `working-in-a-repository` skill first. The owner's comment is in `$AGENT_CONTEXT/request.md`; the issue or pull request and its whole conversation are in `$AGENT_CONTEXT/thread.json`, and `$AGENT_CONTEXT/pull-request.json` exists when the comment is on a pull request.

## Decide what is asked

- **A change** ("fix", "implement", "handle", "update", "rebase onto the review", …): make it.
- **A question** ("why", "can you check", "what do you think"): answer it in `summary.md` with evidence from the code (file and line), and change nothing.
- **Unclear or risky** (a schema or public API change the thread does not settle, a choice between designs, a destructive operation): change nothing and ask the owner one precise question in `summary.md`.

## On an issue

You are checked out on the default branch. Implement what the issue and the owner's comment ask, completely: code, tests, docs and changelog as the repository's rules require. Then write `pull-request.json` with a title and a body that follow the repository's pull request rules; the workflow opens the pull request from a new branch and links it to the issue.

## On a pull request

You are checked out on its head branch. Apply what the owner asked to this branch: review feedback, a fix, a follow-up. Stay within the pull request's scope; propose anything larger in `summary.md` instead.

## Finish

Run the repository's checks for what you changed, then write `summary.md` and, when you changed files, `commit-message.txt`.
