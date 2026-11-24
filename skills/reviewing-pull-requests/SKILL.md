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

- `$AGENT_OUT/review.json`: the review, posted as a GitHub review whose findings sit on the lines they are about:

  ````json
  {
    "summary": "One or two plain sentences, no Markdown: the overall verdict and the most important finding.",
    "comments": [
      {
        "path": "config/talks.yaml",
        "line": 12,
        "body": "What goes wrong, in one sentence.\n\n```suggestion\n    city: Amsterdam\n```"
      },
      {
        "path": "src/Talks.php",
        "start_line": 40,
        "line": 43,
        "body": "What goes wrong over these lines, and the fix."
      }
    ]
  }
  ````

  - `path` is relative to the repository root; `line` (and `start_line` for a range) are line numbers in the **new** version of the file, on lines the diff shows (added or context lines of `$AGENT_CONTEXT/files.json`'s patches). A finding elsewhere still gets a comment with its file and line: the workflow moves it into the review body.
  - When the fix replaces the commented lines, end the body with a ` ```suggestion ` block holding the **complete** replacement for exactly the lines from `start_line` (or `line`) to `line`, with the file's indentation, so the author can apply it in one click. Keep each suggestion to the lines it replaces; describe larger fixes in words.
  - One comment per finding. When there is nothing worth saying, write `{"summary": "No findings.", "comments": []}`.
  - Read the bot's earlier threads on this pull request in `$AGENT_CONTEXT/previous-threads.json` first. List in `"resolve": ["<thread id>", ...]` every unresolved one whose finding the current diff fixes or makes irrelevant, or that the owner answered with a reason you accept: the workflow resolves them. Never repeat a finding a thread still holds open, and keep an unresolved one open while it applies. The workflow also hides the bot's earlier review summaries as outdated, so only the latest stays visible.

- `$AGENT_OUT/summary.md`: one line per area you checked and the checks you ran with their results.

## Keep the description accurate (in a checkout)

On every review, whoever opened the pull request (the owner or the bot), compare its description (`body` in `$AGENT_CONTEXT/pull-request.json`) with the **whole** diff, not only the latest commit. Rewrite it when:

- the summary is missing, empty or a leftover template;
- a change in the diff is not described, or the description announces something the diff does not do (a pull request that grew with new commits needs its description to grow too).

Then write the whole new description to `$AGENT_OUT/pr-body.md`: the current description with its summary replaced by the block described in [description-format.md](description-format.md), between its markers (when the markers are already there, replace only what lies between them). Keep everything else the author wrote (checklists, issue links, notes) exactly as it is. When the description already covers the whole diff, write nothing.

## Sweep reviews

During the sweep, comment only when there is a finding, once per head SHA. Do not diagnose a red pull request there: the fix job handles those by Dependabot, the owner and the bot.
