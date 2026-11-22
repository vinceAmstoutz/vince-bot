# vinceAmstoutz GitHub AI bot

The automation account of @vinceAmstoutz: it opens issues and pull requests, posts comments, reviews what happens across the repositories it watches, and learns from how people react. Everything it does is authored by `vinceamstoutz-github-ai-bot[bot]`, never by the maintainer's own account.

## Post on demand

Coding agents dispatch the `Post as vinceAmstoutz GitHub AI bot` workflow (`.github/workflows/post.yaml`) on `main` with:

- `repository`: the repository name, under the same owner;
- `action: create-issue` with a `title`, a `body` and optional comma-separated `labels`;
- `action: create-pull-request` with the `head` and `base` branches, a `title`, a `body` and optional `labels` (the agent pushes `head` itself first);
- `action: comment` with the issue or pull request `number` and a `body`.

The run's summary links what it posted. Only the owner of this repository can dispatch it.

Agents commit as the bot too: `git -c user.name='vinceamstoutz-github-ai-bot[bot]' -c user.email='<ID>+vinceamstoutz-github-ai-bot[bot]@users.noreply.github.com' commit …`, where `<ID>` is printed by `gh api users/vinceamstoutz-github-ai-bot%5Bbot%5D --jq .id`. GitHub then shows the commit with the bot's name and avatar.

## Sweep

The `vinceAmstoutz GitHub AI bot sweep` workflow (`.github/workflows/sweep.yaml`) runs every three hours, or on demand with optional `focus` instructions. Claude Code, following [`prompts/sweep.md`](prompts/sweep.md), reviews the pull requests opened, updated and merged since the last sweep, dependency updates, red default branches and new issues in the repositories listed in `BOT_REPOSITORIES`; comments or opens issues where it matters; and records what it learned in [`memory/`](memory/), which the bot commits back here. Its token reads code and writes issues and pull request comments, nothing more: it never merges, approves or pushes code.

## One-time setup

1. Create a GitHub App named `vinceAmstoutz GitHub AI bot`: no webhook, installable **Only on this account**, with the repository permissions **Actions: Read-only**, **Checks: Read-only**, **Contents: Read and write**, **Issues: Read and write** and **Pull requests: Read and write**. Upload a logo: it is the bot's profile picture. Each workflow asks for a token holding only the permissions it needs; write access to contents is used only to commit `memory/` here.
2. Install it on **All repositories** of the account.
3. In this repository, store its Client ID as the `BOT_CLIENT_ID` variable and a private key it generated as the `BOT_PRIVATE_KEY` secret.
4. For the sweep, list the repositories it watches, comma-separated, in the `BOT_REPOSITORIES` variable, and store a `CLAUDE_CODE_OAUTH_TOKEN` secret (from `claude setup-token`, billed to the Claude subscription) or an `ANTHROPIC_API_KEY` secret (billed per token).
