---
name: answering-issues
description: Decide whether and how the bot answers an issue or a question in a comment. Use during the sweep for every new issue and every new reply on an issue.
---

# Answering issues

## Answer only when certain

Reply yourself only when you are certain, with evidence you can link: the code (file and line on the default branch), the documentation, a changelog entry, or a reproduction. Certain means another maintainer reading your answer would not need to correct it.

Then answer the question asked, briefly: the answer, the evidence, and the next step for the reporter (a configuration to change, a version to upgrade to, information to provide). Ask for the missing details when a bug report lacks a version, a reproduction or the error output.

## Otherwise, hand it to the owner

When you are not certain, or the issue needs a decision (a feature request, a design choice, a security report, a support question about someone's private setup, anything about money or licensing), do not answer it. Post one comment that mentions `@vinceAmstoutz`, summarizes the issue in two lines and says what you checked and what remains open, so they can answer without re-reading everything.

## Never

- Never promise a fix, a release date or a behavior.
- Never discuss a security vulnerability in public: point the reporter to the repository's security policy and mention `@vinceAmstoutz`.
- Never answer the same thing twice: check the thread for an earlier answer by the bot or the owner.
- Never reply to the bot's own comments or to other bots.
