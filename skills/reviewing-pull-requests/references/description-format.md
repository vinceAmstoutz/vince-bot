# Pull request description format

The bot writes this block, markers included, and replaces only what lies between the markers on later runs:

```markdown
<!-- github-pr-review-description:start -->

### 🤖 Description

<One sentence: the user-visible outcome, with the key words in **bold**.>

- <emoji> <One change as the user experiences it, key words in **bold**.>
- <emoji> <…one line per change worth knowing, at most six.>

**🕰️ Before → 👉 After:**

- <What happened before> → <what happens now.>
<!-- github-pr-review-description:end -->
```

- Write for the people who use the project, not for those who read its code: outcomes, not file names or class names.
- Pick emojis that say what kind of change each line is (🏷️ naming, 🛠️ behavior, 📖 docs, 🔑 configuration or secrets, 🐛 fix, 🚀 performance, 🔒 security, 🧪 tests).
- The Before → After list is required whenever a user does, sees or gets something different, whether from code, configuration or a recommendation in the docs (docs that move shell completion from an `eval` to a file written once); keep it to those changes, and drop it only when no user would notice (wording, links or formatting in the docs, such as linking pull requests in changelog entries; a pure refactor; tooling).
- Nothing outside the block repeats it: what the author wrote below stays only when the block does not cover it and the diff does not show it.
- When the repository's rules impose a pull request template, keep every required section and put the block inside the section meant for the summary, within its length limit: shorten the intro and the bullets first and keep at least one Before → After line; never break the rule.

Example:

```markdown
<!-- github-pr-review-description:start -->

### 🤖 Description

Makes it **easier for new developers to set up their local environment**, including Mangopay.

- 🏷️ New developers name their environment with their **first name**, and add a **last name initial** if needed to stay easy to identify.
- 🛠️ The environment sync step **ignores commented-out placeholder lines**, so it no longer stops setup for no reason.
- 📖 The README gives clearer steps for **Mangopay setup, database reset and creating a support admin**.
- 🔑 The Mangopay setup command **shows where to find the sandbox API key**.

**🕰️ Before → 👉 After:**

- A commented placeholder line stops setup → only real unfilled placeholders stop it.
<!-- github-pr-review-description:end -->
```
