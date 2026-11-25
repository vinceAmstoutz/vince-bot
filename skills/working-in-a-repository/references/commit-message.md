# Commit message and pull request title

Write `$AGENT_OUT/commit-message.txt` with these four steps. The pull request title follows the same rules as the subject line.

## 1. Look at the change first

Run `git status --porcelain` and `git diff --stat`. Name the change from what the diff does, never from what you planned to do.

## 2. Find the repository's convention

Read the first source that exists, in this order:

1. a commit lint configuration: `commitlint.config.*`, `.commitlintrc*`, or a `commitlint` key in `package.json`;
2. the commit rules in `CLAUDE.md`, `AGENTS.md` or `CONTRIBUTING.md`;
3. the last commits of the branch: `git log --oneline -20`.

Use only the types and the scopes that source lists. Do not invent a type or a scope. With no convention at all, use Conventional Commits.

## 3. Pick the type by what a user of the project sees

| Type       | Use it when                                           |
| ---------- | ----------------------------------------------------- |
| `feat`     | A user of the project can do something new.           |
| `fix`      | Something that was wrong for a user is right again.   |
| `perf`     | The same behaviour, faster, with a number to show it. |
| `refactor` | The code changes and the behaviour does not.          |
| `test`     | Only tests change.                                    |
| `docs`     | Only documentation changes.                           |
| `ci`       | Only workflows or CI scripts change.                  |
| `build`    | Dependencies or build tooling change.                 |
| `chore`    | Maintenance that fits none of the above.              |

A change no user can see is never `feat` or `fix`, even when it repairs something internal. When the repository lists fewer types, use the closest one it lists.

## 4. Build the message

```text
<type>(<scope>): <subject>

<body>
```

- **Subject**: imperative, lower case, no final period, within the repository's length limit (72 characters when it gives none).
- **Scope**: the one the repository's convention gives for the changed paths. Leave it out when the convention has no scopes.
- **Body**: one to three lines saying why, when the subject does not say it. Leave it out when the repository asks for a subject line only.

Examples:

- `fix(talks): keep the page up when the events API times out`
- `build(deps): adapt the mailer configuration to symfony/mailer 8`
- `ci: cache the Composer downloads between runs`

## Never

- A co-author trailer, or any mention of an AI tool or a model.
- Data from a production event: describe the failing input in general terms.
- The name of a security weakness in a public repository.

## Check it

When the repository ships a commit lint check, run it on the file. Fix the message and run it again until it passes.
