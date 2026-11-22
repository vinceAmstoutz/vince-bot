# Vince bot

Coding agents working for @vinceAmstoutz open issues and pull requests and post comments as **Vince bot** (`vince-bot[bot]`), never under the maintainer's own account.

## Use

Dispatch the `Post as Vince bot` workflow (`.github/workflows/post.yaml`) on `main` with:

- `repository`: the repository name, under the same owner;
- `action: create-issue` with a `title`, a `body` and optional comma-separated `labels`;
- `action: create-pull-request` with the `head` and `base` branches, a `title`, a `body` and optional `labels` (the agent pushes `head` itself first);
- `action: comment` with the issue or pull request `number` and a `body`.

The run's summary links what it posted. Only the owner of this repository can dispatch it.

## One-time setup

1. Create a GitHub App named `Vince bot`: no webhook, installable **Only on this account**, with the repository permissions **Contents: Read-only**, **Issues: Read and write** and **Pull requests: Read and write**.
2. Install it on **All repositories** of the account.
3. In this repository, store its Client ID as the `BOT_CLIENT_ID` variable and a private key it generated as the `BOT_PRIVATE_KEY` secret.
