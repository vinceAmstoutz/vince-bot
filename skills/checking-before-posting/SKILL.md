---
name: checking-before-posting
description: Gate everything the bot is about to commit or post (code, commit message, pull request, comments, issues) against the target repository's rules, docs, skills and checks. Run it after the task's own skill, before the workflow publishes anything.
---

# Checking before posting

You are a second, independent reviewer. Another agent prepared work in `$AGENT_OUT` (and, for code, in the working tree). Nothing is published until you approve it, and the workflow publishes exactly what you leave behind. Be strict: when in doubt, fix it or drop it.

## Gather the rules

When `$AGENT_CONTEXT/rules/` exists, the posts target other repositories: their `CLAUDE.md`, `AGENTS.md`, `.claude/rules/`, `CONTRIBUTING.md` and templates are under `$AGENT_CONTEXT/rules/<repository>/`. Otherwise you are in a checkout of the target repository: read its `CLAUDE.md`, `AGENTS.md`, `.claude/rules/`, `.claude/skills/`, `CONTRIBUTING.md`, pull request and issue templates, changelog rules and the checks CI runs on prose (commit lint, pull request checks, changelog checks, Markdown formatting and lint).

## Check the code (when the working tree has changes)

Skip this part when `$AGENT_CONTEXT/rules/` exists: you are then in the bot's own repository, checking drafts only, and its working tree holds the bot's memory, which you must leave untouched.

1. `git diff` must do only what `summary.md` says, nothing more. Revert unrelated edits.
2. No local commit: the changes stay uncommitted in the working tree, because the workflow creates the one signed commit itself (`git status` shows them, `git log` shows nothing new).
3. No skipped, deleted or weakened test, no suppression or ignore entry, no lowered threshold, no secret, no generated file edited by hand.
4. Run the repository's checks that cover the changed files with the commands CI uses. Fix what fails, or revert the change and say why in `summary.md`.

## Check the prose

For `commit-message.txt`, `pull-request.json`, `pr-body.md`, `review.json`, `summary.md`, `posts.json` and `issues.json`, whichever exist:

- **Thread reply** (`reply.md`): one line of at most 200 characters starting with ✅, 💬 or ❓, saying only what changed or the answer; shorten it rather than lose the meaning.
- **Review** (`review.json`): each comment's `path` and `line` point at the lines it discusses in the new version of the file; a ` ```suggestion ` block replaces exactly the lines from `start_line` (or `line`) to `line`, keeps the file's indentation, and applies cleanly (no lines outside that range, nothing left out); drop a comment you cannot verify.
- **Pull request description** (`pr-body.md`): it must pass the repository's own pull request check when there is one (for example `PR_TITLE=… PR_BODY="$(cat pr-body.md)" BASE_REF=… sh .github/scripts/check-pull-request.sh`), repeat nothing of the bot's block outside it while keeping, unchanged, only what the author added that the block does not cover and the diff does not show (no file lists, no code descriptions), and what the repository's pull request rules require, and follow the bot's description format inside it, with a Before → After list whenever the diff changes behavior. When it does not pass, shorten the block's intro and bullets until it does, keeping its Before → After list; delete `pr-body.md` only when it still cannot pass.
- **Format**: follow the repository's conventions exactly: Conventional Commits types and scopes it lists, title length limits, required pull request sections and only those, its changelog line format, its Markdown style (line wrapping, headings). When the repository ships a check for it (a commitlint config, a pull request check script, a changelog check, Prettier or markdownlint), run it on the text and fix until it passes.
- **Personal data**: nothing from a production event (request data, headers, cookies, user ids, emails, local variables) appears in code, tests, commit messages, pull requests, comments or issues; describe failing inputs in general terms.
- **Content**: every claim is true for this diff and this repository; links point to the right files and lines; nothing promises fixes, dates or behavior; nothing discloses a vulnerability publicly; no mention of any AI tool, model or co-author.
- **Tone**: short, factual, written for the owner and contributors of this repository; one point per finding; no greeting, no filler.
- **Duplicates**: drop a comment that repeats an earlier answer in the thread, and an issue already covered by an open one.

Edit the files in place to fix problems. Remove any post or issue you cannot make correct from `posts.json` or `issues.json`.

## Decide

Write `$AGENT_OUT/verdict.json`:

```json
{
  "approved": true,
  "checks": ["what you ran, with its result"],
  "problems": []
}
```

Set `"approved": false`, and list the blocking problems, when the code changes cannot be made correct; the workflow then commits nothing and posts only your `summary.md`, addressed to `@vinceAmstoutz`. Posts and issues you removed do not block approval.
