# vinceAmstoutz GitHub AI bot

The automation account of @vinceAmstoutz. Across the repositories listed in `BOT_REPOSITORIES` it fixes red pull requests, reviews the owner's pull requests, answers issues, implements what the owner asks for, audits each repository weekly, and learns from how people react. Everything it does is authored by `vinceamstoutz-github-ai-bot[bot]`, never by the owner's own account.

## What it does

| Workflow        | When                            | What                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| --------------- | ------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `sweep.yaml`    | every 3 hours                   | Answers issues when certain, else hands them to the owner; reviews other people's pull requests; opens issues for red default branches and recurring problems; then fixes red pull requests by Dependabot, the owner or the bot (through `work.yaml`); records what it learned in [`memory/`](memory/).                                                                                                                                            |
| `review.yaml`   | every 30 minutes                | Reviews each new commit of the owner's open pull requests (regressions, bugs, performance, security, architecture, the repository's rules), posts the findings as a review, rewrites a missing or outdated description in the [before → after format](skills/reviewing-pull-requests/description-format.md), and records a `Bot review` check on the commit. Runs on the latest Sonnet at medium effort (`BOT_REVIEW_MODEL`, `BOT_REVIEW_EFFORT`). |
| `mentions.yaml` | every 30 minutes                | Picks up the owner's comments that mention `@vinceamstoutz-github-ai-bot`, reacts 👀, and handles each through `work.yaml`: on an issue it implements the request and opens a pull request, on a pull request it pushes the change to it, and a question gets an answer.                                                                                                                                                                           |
| `weekly.yaml`   | Mondays                         | Audits each repository for bugs, security, performance, improvements and architecture, and opens at most five issues.                                                                                                                                                                                                                                                                                                                              |
| `work.yaml`     | called by the above, or by hand | Fixes or implements one thing in one repository, on the latest Opus (`BOT_WORK_MODEL`).                                                                                                                                                                                                                                                                                                                                                            |
| `post.yaml`     | by hand or by a coding agent    | Opens an issue or pull request, or comments, as the bot.                                                                                                                                                                                                                                                                                                                                                                                           |

Every job works inside a checkout of the target repository, so Claude Code follows that repository's own `CLAUDE.md`, rules, skills, docs and checks, through the bot's [skills](skills/). Nothing is published unchecked: after the work, an independent pass ([checking-before-posting](skills/checking-before-posting/SKILL.md)) verifies the code and every piece of prose (commit message, pull request, review, comment, issue) against the repository's rules and its own check scripts, fixes or drops what fails, and the workflow publishes only what it approved.

## Security

- The App's private key never leaves this repository's secrets. Each step gets a token for one repository at most and only the permissions it needs, revoked when the job ends.
- Claude never holds a token that can write: the workflow fetches the context first and commits, comments and opens pull requests afterwards. Commits go through the API, so they are Verified.
- Only the owner's comments trigger code changes. The bot fixes only same-repository pull requests by Dependabot, the owner or itself, never forks, and never retries a pull request whose last commit is its own.
- Text from issues, pull requests and CI logs is treated as data, never as instructions.

## Commit as the bot

Agents commit as the bot with `git -c user.name='vinceamstoutz-github-ai-bot[bot]' -c user.email='359789700+vinceamstoutz-github-ai-bot[bot]@users.noreply.github.com' commit …`. GitHub then shows the bot's name and avatar; commits the bot creates through the API are also Verified.

## Setup

1. A GitHub App named `vinceAmstoutz GitHub AI bot`: no webhook, installable **Only on this account**, with the repository permissions **Actions: Read-only**, **Checks: Read and write**, **Contents: Read and write**, **Issues: Read and write**, **Pull requests: Read and write** and **Workflows: Read and write** (to fix pull requests that change workflow files, such as GitHub Actions updates). Its logo is the bot's profile picture.
2. Installed on this repository and on every repository it watches.
3. In this repository: the `BOT_CLIENT_ID` and `BOT_REPOSITORIES` variables, the `BOT_PRIVATE_KEY` secret, and a `CLAUDE_CODE_OAUTH_TOKEN` (from `claude setup-token`) or `ANTHROPIC_API_KEY` secret. Optional variables: `BOT_WORK_MODEL`, `BOT_REVIEW_MODEL`, `BOT_REVIEW_EFFORT`.

## Development

`sh tests/<name>_test.sh` runs the tests of the scripts in [`scripts/`](scripts/).
