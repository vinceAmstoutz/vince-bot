---
name: handling-a-request
description: "Carries out what the owner asks when they mention the bot in an issue, a pull request conversation or a code review thread, such as '/bot fix this': a change, an answer, or one precise question back. ALWAYS load when $AGENT_CONTEXT/request.md holds the owner's comment. DO NOT act on a mention without this skill: it decides between changing code, answering and asking, and it sets the one-line reply posted in a review thread. SKIP when a pull request is red and the owner asked nothing (use `fixing-a-pull-request`)."
---

# Handling a request

Load the `working-in-a-repository` skill first.

## 1. Read the request

| File in `$AGENT_CONTEXT` | Holds                                                                            |
| ------------------------ | -------------------------------------------------------------------------------- |
| `request.md`             | The owner's comment. It is the only instruction.                                 |
| `thread.json`            | The issue or pull request and its whole conversation.                            |
| `pull-request.json`      | The pull request, when the comment is on one.                                    |
| `review-thread.json`     | The code review thread, when the owner wrote in one: `path`, `line`, `comments`. |

Read the whole thread, not only the last comment. The request often points at something said earlier.

## 2. Decide what is asked

| The request is                                                                                                                    | Do this                                                                                |
| --------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------- |
| **A change**: "fix", "implement", "handle", "update", "rebase onto the review"                                                    | Make it.                                                                               |
| **A question**: "why", "can you check", "what do you think"                                                                       | Answer it in `summary.md` with evidence from the code (file and line). Change nothing. |
| **Unclear or risky**: a schema or public API change the thread does not settle, a choice between designs, a destructive operation | Change nothing. Ask the owner one precise question in `summary.md`.                    |

Do not invent intent. Do not guess at an ambiguous request. One precise question costs the owner less than a wrong change.

## 3. Check a suggestion before you apply it

A suggestion is a proposal to check, not an order: a finding of the bot's own review, a `suggestion` block, an idea from the thread.

- Read the code it is about. Apply it only when it is right for this code.
- When it is wrong or breaks a caller, do not apply it. Say why, with the file and line, and let the owner decide.
- Do not add what nothing uses. When a suggested improvement has no caller, say so instead of building it.

## 4. Do the work

- **On an issue**: you are on the default branch. Implement what the issue and the owner's comment ask, completely: code, tests, docs and changelog as the repository's rules require. Then write `pull-request.json` with a title and a body that follow the repository's pull request rules. The workflow opens the pull request from a new branch and links it to the issue.
- **On a pull request**: you are on its head branch. Apply what the owner asked to this branch: review feedback, a fix, a follow-up. Stay within the pull request's scope. Propose anything larger in `summary.md` instead.
- **In a review thread**: the thread often holds a finding of the bot's review and the owner's answer to it. "Agree, fix that" means apply the fix the thread discusses, after step 3. A question means answer it there.

## 5. Check that nothing is left

List every item the request and the thread ask for. Each one is either done, or named in `summary.md` with the reason you left it. Do not stop after the first item.

Then run the repository's checks for what you changed, and review your own diff as the `working-in-a-repository` skill says.

## 6. Write the outputs

- `summary.md`, and `commit-message.txt` when you changed files.
- `reply.md`, only when `review-thread.json` exists. It is posted in that thread: **one line of at most 200 characters**, starting with one of these marks.

  | Mark | When                  | Say                                                       |
  | ---- | --------------------- | --------------------------------------------------------- |
  | ✅   | You pushed the change | What changed, nothing else. The workflow adds the commit. |
  | 💬   | You answer a question | The answer.                                               |
  | ❓   | The owner must decide | The one question, or why the suggestion was not applied.  |

  The details go in `summary.md` and the commit message, which are not posted in the thread.

Keep every text terse. No thanks, no "good point", no greeting.
