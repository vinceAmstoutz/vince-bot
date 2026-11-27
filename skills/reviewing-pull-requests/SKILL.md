---
name: reviewing-pull-requests
description: "Reviews one pull request against the repository's own rules: regressions, bugs, security, performance, architecture, naming, tests and the description. ALWAYS load when the task is to review a pull request: the owner's or the bot's in a checkout (review job), someone else's through the API (sweep). DO NOT write a review comment without this skill: every finding MUST carry a severity (🟠 major or ⚪ nit), a proof and a fix, and review.json must keep the shape the workflow posts. SKIP when a red pull request must be fixed (use `fixing-a-pull-request`), when the owner asks for a change in a thread (use `handling-a-request`) and when gating what another agent drafted (use `checking-before-posting`)."
---

# Reviewing pull requests

You review. You do not fix. Be direct and specific.

Comment only on problems. Never praise, never describe what the code does, never note that something is correct.

## Severity

Every finding has one of two levels, and its comment starts with it.

- `🟠 major`: must be fixed before merge. A wrong result, a regression, a security hole, lost or corrupted data, a broken rule the repository enforces.
- `⚪ nit`: optional. A name, clarity, a simpler design, a comment.

The default is `⚪ nit`. A finding is `🟠 major` only when you hold the proof that something breaks.

## Core principles

These decide whether a finding is posted at all. They apply to both levels.

- **Certainty only.** Report what you are certain of. Before you say something is missing or wrong, read the file that proves it. No "not sure this works", no "check whether this is intended".
- **Proof for a `🟠 major`.** Name the file and line, the test output or the doc that shows the problem is real. With no proof, lower it to `⚪ nit`. The claims of the next rule are the exception: with no proof they are dropped.
- **Prove the claim.** Each kind of claim has its proof. With no proof, do not post it, not even as a `⚪ nit`.

  | Claim                                                    | Proof                                                                           |
  | -------------------------------------------------------- | ------------------------------------------------------------------------------- |
  | How a language, a framework, a tool or a library behaves | The docs of the installed version, or the code in `vendor/` or `node_modules/`. |
  | A symbol is unused, renamed or missing                   | A `git grep` on the branch.                                                     |
  | The change breaks something that worked                  | The caller that breaks, with its file and line.                                 |

- **The pull request's own tests are not proof.** A test the diff adds records what the author intended, a wrong behaviour included. Check the behaviour against code the diff did not touch: the code that reads what it writes, and the data already stored.
- **A comment that justifies the code settles intent, not consequence.** It shows the author chose it on purpose. It says nothing about what the choice costs. When your finding is about the cost, trace it in the code and report it when the code disagrees with the comment.
- **Earlier rounds.** Read `$AGENT_CONTEXT/previous-threads.json` first, resolved threads included. Never repeat a finding an open thread still holds. Never ask to undo what an earlier round asked for, or what the owner declined with a reason you cannot refute with the code.
- **No comment that cancels itself.** A comment that ends with "but this is fine if intended" is not posted. A comment with no required action is not a finding.
- **Be specific.** Each comment names the file and line, says why it is a problem and gives the fix. "This could be improved" has no value.
- **Changed code only.** Comment on what the pull request changes. Read the surrounding code, the callers and the tests to verify a finding. Do not review them.
- **Look for regressions.** Ask what the change can break silently: a changed signature, a removed default, a changed return type, a shared service other code calls.

## 1. Understand the change

In a checkout, load the `working-in-a-repository` skill for how to read the repository. Then read `$AGENT_CONTEXT/pull-request.json` and the diff: `git diff origin/<base>...HEAD`, after `git fetch origin <base>` when needed.

Answer three questions before anything else. What is the pull request trying to do? Does the approach fit this codebase? Is it one feature or one fix? When the approach is wrong, report that first: every other finding is secondary.

## 2. Load the rules for what the diff touches

**This step is mandatory.** Read every file of each row that matches, before you write a finding. Do not assume you know what they say.

| The diff touches                                                                                                                | Read                                                      |
| ------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------- |
| Any file                                                                                                                        | [naming.md](references/naming.md)                         |
| Application code: PHP, JavaScript, TypeScript, templates                                                                        | The `finding-bugs` skill                                  |
| Input handling, authentication, access control, output escaping, secrets, configuration                                         | The `finding-security-issues` skill                       |
| A query, a remote call, a cache, a loop over a collection or an asset on a request path                                         | The `finding-performance-issues` skill                    |
| A new class, service, module, abstraction or dependency                                                                         | The `reviewing-architecture` skill                        |
| `.github/workflows/**`, `.github/actions/**` and the scripts they call                                                          | [rules-ci.md](references/rules-ci.md)                     |
| A manifest or a lock file: `composer.json`, `composer.lock`, `package.json`, `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml` | [rules-dependencies.md](references/rules-dependencies.md) |
| Docs, Markdown, agent skills or prompts                                                                                         | Nothing more: the checklist below covers them.            |

The repository's own rules come on top: its `CLAUDE.md`, its `.claude/rules/`, its skills, its contributing guide. They win when they disagree with a file of this table.

## 3. Check every changed file

Work through every category for each changed file, in this order. A rules file of step 2 can end with "Checklist items": they extend these categories and never replace them.

Note `none found` for a category with no finding. Never leave one out.

1. **Naming**: the audit of [naming.md](references/naming.md), on every name the diff adds or whose body it changes.
2. **Bugs and logic errors**: a wrong condition, an off-by-one, the wrong variable, a branch that cannot be reached. When the change writes a status, a date or a format, find the code that reads it later and say what that reader returns for the rows written before the change.
3. **Null and edge cases**: null or undefined, an empty collection, zero, a boundary value, an empty string, a missing default branch.
4. **Error handling**: an exception nobody catches, a missing guard at an I/O boundary, a swallowed error, missing cleanup on failure.
5. **Security**: injection, unvalidated input at a boundary, a missing permission check, exposed sensitive data.
6. **Performance**: a query or a remote call per item of a loop, a loop over a large collection, a missing limit. Use the proof the `finding-performance-issues` skill asks for.
7. **Responsibility**: each class, function, component and script has one clear job. Name the methods that do not match the class, and the existing owner they belong to.
8. **Breaking changes**: a changed signature, a removed or renamed parameter, a changed return type, a renamed configuration key, route, command option or environment variable, a modified shared interface or event.
9. **Tests**: flag a missing test only when the repository's rules require one for this kind of change. Always flag a changed behaviour that an existing test contradicts, a deleted test with no replacement, and a test that cannot fail.
10. **Dead code**: for each method, property, parameter or option the diff adds or touches, grep its name in the repository and count the references outside its own declaration. Flag it at zero. Flag an unused variable and an unreachable branch too.
11. **Comments and docs**:
    - a comment or a doc that says what the code does, what it returns, how often or in what order it runs: read that code, and flag the claim when the code does something else;
    - a name in backticks that the diff adds to a doc or a comment: grep it, and flag it when it does not exist;
    - a symbol, a command or a file the diff renames or deletes: grep its name in comments and docs, and flag each mention that is now wrong;
    - a comment that tells history ("previously", "now uses … instead of") or only repeats the code: comments describe the code as it is now;
    - a wording problem in a doc, a skill or a prompt is `⚪ nit` at most. It is `🟠 major` only when a command or a path written there fails when followed literally.
12. **Repository rules**: what the repository's rules forbid or require: a changelog entry, docs, the commit and title format, the pull request sections.
    - Before you ask for a new changelog entry, find the last release tag (`git tag --sort=-creatordate`) and check that the changed behaviour exists at that tag (`git show <tag>:<path>`; in a sweep, read the file at that tag through the API). A fix of code added after the last release changes nothing a user saw: ask for no new entry, unless the repository's rules say so in words. Ask only to amend an existing entry when it is no longer true.
    - Example: a fix to a command option that no release has shipped yet needs no bug-fix line.

## 4. Check the change as a whole

After the files, answer these three questions about the whole pull request:

1. **Together**: do the pieces meet the goal together, failure paths and deployment order included?
2. **Owner**: does each business rule have one clear owner?
3. **Approach**: can an existing part of the codebase, or a smaller mechanism, do the same with less to maintain?

Report at most the three problems with the largest consequence, each in three sentences at most: the files, what it costs, the simpler design. Do not repeat a finding already made on a file.

## 5. Run the fast checks

In a checkout, run the checks that cover the changed files when they are fast. A failure is a finding, and its output is the proof.

## 6. Cut what does not matter

Before you keep a comment, ask: does fixing this change anything, in behaviour, in correctness, in structure, or in how well a developer understands the code? If not, drop it.

Always skip:

- what a linter, a formatter, a type checker or the static analysis of the repository already enforces: formatting, unused imports, type errors, line length;
- teaching how something works when the code is not wrong;
- TODOs and future work: if it does not need a fix now, do not mention it;
- making two documents more consistent with each other when both are right;
- a tool that might break: it is a finding only when the tool exists and you show it breaks;
- a compatible swap of one framework method for another;
- a duplicate of a few lines in two or three places;
- a minor configuration or environment value, unless you show a regression;
- a version constraint written differently that resolves to the same version;
- code marked temporary, legacy or one-shot: report only what can lose data or open a security hole;
- personal preference.

Keep at most ten comments, `🟠 major` first. Finding nothing is a valid result: do not reread files to find something to say.

## 7. Write the review

In a checkout, write two files.

`$AGENT_OUT/review.json` is posted as a GitHub review whose findings sit on the lines they are about:

````json
{
  "summary": "One or two plain sentences, no Markdown: the overall verdict and the most important finding.",
  "comments": [
    {
      "path": "config/talks.yaml",
      "line": 12,
      "body": "🟠 major: What goes wrong and what proves it, in one or two sentences.\n\n```suggestion\n    city: Amsterdam\n```"
    },
    {
      "path": "src/Talks.php",
      "start_line": 40,
      "line": 43,
      "body": "⚪ nit: What is wrong over these lines, and the fix."
    }
  ],
  "resolve": [{ "thread": "<thread id>", "outcome": "fixed", "note": "What the diff changed, in one sentence of 150 characters or fewer." }]
}
````

- **Body**: it starts with `🟠 major: ` or `⚪ nit: `, then says what goes wrong, what proves it, and the fix. One comment per finding.
- **Lines**: `path` is relative to the repository root. `line`, and `start_line` for a range, are line numbers in the **new** version of the file, on lines the diff shows: the added or context lines of the patches in `$AGENT_CONTEXT/files.json`. A finding elsewhere still gets a comment with its file and line: the workflow moves it into the review body.
- **Suggestion**: when the fix replaces the commented lines, end the body with a ` ```suggestion ` block. It holds the **complete** replacement for exactly the lines from `start_line` (or `line`) to `line`, with the file's indentation, so the author applies it in one click. Describe a larger fix in words.
- **Resolve**: list every unresolved thread of `$AGENT_CONTEXT/previous-threads.json` whose finding the current diff fixes or makes irrelevant (`"outcome": "fixed"`), or that the owner answered with a reason you accept (`"outcome": "declined"`). Give each a `note`: one sentence of 150 characters or fewer saying what the diff changed, or for `declined` why it stays as is. The workflow replies ✅ or ❌ with that note in the thread and resolves it, so nobody has to write "fixed". Keep an unresolved thread open while its finding still applies. Leave the key out when there is none.
- **Nothing to say**: write `{"summary": "No findings.", "comments": []}`.

`$AGENT_OUT/summary.md` holds, in this order:

1. the files of step 2 you read;
2. one line per category of step 3: the number of findings, or `none found`;
3. the three numbers of the naming audit;
4. the checks you ran, with their results.

## 8. Give the description the owner's format

Do this in a checkout. Every pull request of the owner or of the bot carries the bot's description block, between its markers, as its summary: see [description-format.md](references/description-format.md).

On every review, compare the description (`body` in `$AGENT_CONTEXT/pull-request.json`) with the **whole** diff, not only the latest commit. When `$AGENT_CONTEXT/description-notes.md` exists, it names what the workflow already found missing: act on it.

| The description                                                                               | Do this                                                                                                                                                    |
| --------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Has no block                                                                                  | Build it from the diff and from the author's summary. Keep the author's facts (versions, advisories, issue numbers, migration notes) in the block's lines. |
| Has a block with no Before → After list, and a user does, sees or gets something different    | Add the list.                                                                                                                                              |
| Has a block that no longer covers the whole diff, or announces something the diff does not do | Rewrite what lies between the markers.                                                                                                                     |
| Repeats outside the block what the block says                                                 | Remove the repeated parts.                                                                                                                                 |
| Has a block that covers the whole diff, with nothing outside that repeats it                  | Write nothing.                                                                                                                                             |

In the first four cases, write the whole new description to `$AGENT_OUT/pr-body.md`.

The block **replaces whatever the author wrote that it covers**. A summary, an explanation or a detail that says the same thing goes. So does anything the diff already shows: lists of changed files, descriptions of what the code does or how it is built.

Keep, exactly as written, only:

- what the author added that the block does not cover **and** that a reader needs but cannot get from the diff: a "before merging" action, a migration note, the reason for a choice, a screenshot;
- issue links such as `Closes #12`;
- the sections, checkboxes and lines the repository's own pull request rules require, with the block in the section meant for the summary.

## Sweep reviews

During the sweep there is no checkout. Read the same rule files with `gh api -X GET repos/{owner}/{repo}/contents/{path}` and the diff with `gh pr diff`. Apply the severity levels, the core principles and steps 3 to 6.

Draft one comment per pull request, only when there is a finding, once per head SHA. It holds one line per finding, each starting with its severity. Do not diagnose a red pull request there: the fix job handles those of Dependabot, the owner and the bot.
