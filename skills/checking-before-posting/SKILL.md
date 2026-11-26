---
name: checking-before-posting
description: "Gates everything the bot is about to commit or post (code, commit message, pull request, review, comments, issues) against the target repository's rules, docs, skills and checks, as a second and independent reviewer. ALWAYS load after the task's own skill ran, before the workflow publishes anything. DO NOT write verdict.json without this skill: the workflow publishes exactly what this pass leaves in $AGENT_OUT, and nothing else checks it. SKIP for doing the task itself: the task's own skill does that."
---

# Checking before posting

You are a second, independent reviewer. Another agent prepared work in `$AGENT_OUT` and, for code, in the working tree. Nothing is published until you approve it, and the workflow publishes exactly what you leave behind.

Be strict. Check each claim yourself: do not trust `summary.md`. When in doubt, fix it or drop it.

## 1. Gather the rules

| Situation                      | Where the rules are                                                                                                                                                                                                                                                                                                      |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `$AGENT_CONTEXT/rules/` exists | The posts target other repositories. Their `CLAUDE.md`, `AGENTS.md`, `.claude/rules/`, `CONTRIBUTING.md` and templates are under `$AGENT_CONTEXT/rules/<repository>/`.                                                                                                                                                   |
| Otherwise                      | You are in a checkout of the target repository. Read its `CLAUDE.md`, `AGENTS.md`, `.claude/rules/`, `.claude/skills/`, `CONTRIBUTING.md`, its pull request and issue templates, its changelog rules and the checks CI runs on prose (commit lint, pull request checks, changelog checks, Markdown formatting and lint). |

## 2. Check the code

Do this when the working tree has changes.

Skip it when `$AGENT_CONTEXT/rules/` exists: you are then in the bot's own repository, checking drafts only. Its working tree holds the bot's memory, which you must leave untouched.

1. **Scope**: `git diff` does only what `summary.md` says, nothing more. Revert unrelated edits.
2. **No local commit**: the changes stay uncommitted in the working tree, because the workflow creates the one signed commit itself. `git status` shows them and `git log` shows nothing new.
3. **No shortcut**: no skipped, deleted or weakened test, no suppression or ignore entry, no lowered threshold, no secret, no generated file edited by hand.
4. **Checks**: run the repository's checks that cover the changed files, with the commands CI uses. Fix what fails and run again until it passes. When you cannot make it pass, revert the change and say why in `summary.md`.

## 3. Check the prose

Check each of these files that exists: `commit-message.txt`, `pull-request.json`, `pr-body.md`, `review.json`, `reply.md`, `summary.md`, `posts.json`, `issues.json`.

### Rules for one kind of file

- **Review** (`review.json`): read `~/.claude/skills/reviewing-pull-requests/SKILL.md` first, for its severity levels, its core principles and its skip list. Then, for each comment:
  - open the file and check the claim yourself. Drop a comment you cannot verify;
  - drop praise, a description of what the code does, a question, a guess, a comment that cancels itself ("fine if intended"), and anything in the skip list;
  - its body starts with `🟠 major` or `⚪ nit`. Lower a `🟠 major` with no proof to `⚪ nit` when the problem is still certain, and drop it otherwise;
  - `path` and `line` point at the lines it discusses, in the new version of the file;
  - a ` ```suggestion ` block replaces exactly the lines from `start_line` (or `line`) to `line`, keeps the file's indentation and applies cleanly: no line outside that range, nothing left out.
- **Thread reply** (`reply.md`): one line of at most 200 characters starting with ✅, 💬 or ❓. It says only what changed, or the answer. Shorten it rather than lose the meaning.
- **Pull request description** (`pr-body.md`):
  - it passes the repository's own pull request check when there is one, for example `PR_TITLE=… PR_BODY="$(cat pr-body.md)" BASE_REF=… sh .github/scripts/check-pull-request.sh`;
  - it follows the bot's description format inside the block, with a Before → After list whenever a user does, sees or gets something different, docs recommendations included;
  - nothing outside the block repeats it. What stays outside, unchanged, is only what the author added that the block does not cover and the diff does not show (no file lists, no code descriptions), and what the repository's pull request rules require;
  - when it does not pass, shorten the block's intro and bullets until it does, and keep its Before → After list. Delete `pr-body.md` only when it still cannot pass.
- **Skill changes from feedback**, when `$AGENT_CONTEXT/feedback.json` exists:
  - every changed file is under `skills/`. Revert any other change;
  - nothing from `feedback.json` appears in the diff, the commit message or the pull request: no quote, no file path, no repository name, no title, no link, no code. Compare them with the feedback yourself;
  - no contract and no safety rule changed: see "Never change" in `~/.claude/skills/improving-skills-from-feedback/SKILL.md`. Revert such a change;
  - each proposal of the pull request has its evidence, and the evidence matches the feedback. Count the items yourself and remove a proposal the feedback does not support, with its change;
  - `sh tests/skills_test.sh` passes.
- **Audit summary** (`summary.md` of the weekly audit and of the security triage): it is never public. The workflow posts it only in the owner's private reports repository and keeps an encrypted copy. Keep the security findings of a public repository in it in full, with the attack path, the impact and the fix, and keep them out of `issues.json`.
- **Issues** (`issues.json`) and **sweep drafts** (`posts.json`): each one has the proof its skill asks for. Remove the ones you cannot make correct.

### Rules for every file

- **Format**: follow the repository's conventions exactly: the Conventional Commits types and scopes it lists, its title length limits, its required pull request sections and only those, its changelog line format, its Markdown style (line wrapping, headings). When the repository ships a check for it (a commitlint config, a pull request check script, a changelog check, Prettier or markdownlint), run it on the text. Fix and run again until it passes.
- **Personal data**: nothing from a production event (request data, headers, cookies, user ids, emails, local variables) appears in code, tests, commit messages, pull requests, comments or issues. Failing inputs are described in general terms.
- **Content**: every claim is true for this diff and this repository. Links point to the right files and lines. Nothing promises a fix, a date or a behavior. Nothing discloses a vulnerability in public. Nothing mentions an AI tool, a model or a co-author.
- **Tone**: short and factual, written for the owner and the contributors of this repository. One point per finding. No greeting, no filler, no thanks.
- **Duplicates**: drop a comment that repeats an earlier answer in the thread, and an issue an open one already covers.

Edit the files in place to fix problems.

## 4. Decide

Write `$AGENT_OUT/verdict.json`:

```json
{
  "approved": true,
  "checks": ["what you ran, with its result"],
  "problems": []
}
```

- `checks` holds one entry per check you ran in steps 2 and 3, with its result. A check you did not run is not listed as passing.
- Set `"approved": false`, and list the blocking problems, when the code changes cannot be made correct. The workflow then commits nothing and posts only your `summary.md`, addressed to `@vinceAmstoutz`.
- Posts, issues and review comments you removed do not block approval.
