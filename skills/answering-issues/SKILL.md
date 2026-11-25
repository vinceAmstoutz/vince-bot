---
name: answering-issues
description: "Decides whether the bot answers an issue or a question in a comment, and drafts either the answer or the handover to the owner. ALWAYS load during the sweep for every new issue and every new reply on an issue. DO NOT draft a comment on an issue without this skill: an uncertain answer, a promise or a public word about a vulnerability cannot be taken back once posted. SKIP when the owner mentions the bot with a request (use `handling-a-request`) and for a pull request (use `reviewing-pull-requests`)."
---

# Answering issues

## 1. Decide

| The issue or reply is                                                                                           | Draft                                                                                                        |
| --------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| A question the code, the docs or the changelog answers                                                          | The answer, step 2.                                                                                          |
| A bug report with no version, no reproduction or no error output                                                | One comment asking for exactly what is missing.                                                              |
| A feature request, a design choice, a question about someone's private setup, anything about money or licensing | The handover, step 3.                                                                                        |
| A question you cannot answer with proof                                                                         | The handover, step 3.                                                                                        |
| A security report                                                                                               | A pointer to the repository's security policy and a mention of `@vinceAmstoutz`. Nothing about the weakness. |
| Already answered in the thread by the bot or the owner                                                          | Nothing.                                                                                                     |
| A comment by the bot or by another bot                                                                          | Nothing.                                                                                                     |

## 2. Answer only when certain

Certain means another maintainer who reads your answer would not need to correct it. Each claim needs a proof you can link:

- the code, with file and line on the default branch;
- the documentation or a changelog entry;
- a reproduction, with the command and its output;
- for how a framework or a library behaves: the docs of the version the repository uses, never your memory of another version.

Without a proof for every claim, hand the issue over instead.

Write the answer in this order, and nothing else:

1. the answer to the question asked;
2. the proof;
3. the next step for the reporter: a setting to change, a version to upgrade to, information to provide.

No greeting, no thanks, no "great question".

## 3. Hand it to the owner

Post one comment that:

1. mentions `@vinceAmstoutz`;
2. sums up the issue in two lines;
3. says what you checked, with links;
4. says what remains open.

The owner must be able to answer without reading the whole thread again.

## Never

- Promise a fix, a release date or a behaviour.
- Discuss a security vulnerability in public.
- Answer the same thing twice.
- Soften an answer you are not sure of ("it might be", "probably"). An answer that needs a hedge is a handover.
