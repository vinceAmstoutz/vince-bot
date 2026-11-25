# Naming audit

Run this audit on every changed file, before the other categories. It replaces "I would name it differently" with a count.

A naming finding is always `⚪ nit`. Never raise the severity for a name alone.

## 1. List the names the diff owns

One entry per name:

- **Declarations the diff adds**, whatever their visibility: classes, interfaces, enums and their cases, functions, methods, properties, constants, parameters.
- **Declarations whose body the diff changes**, even when the declaration line is untouched. A name is judged against what the body does now.
- **Tests**: test methods and titles, scenario titles, data-provider keys, fixtures and helpers.
- **Names outside code**: added files and scripts, manifest script keys, workflow, job and step names, action inputs, configuration keys, routes, tables and columns, translation keys.
- **Local variables**, only when the value assigned contradicts the name.

Judge only what the diff adds or changes. A behaviour that is already on the base branch is out of scope.

## 2. List what each name does

Read the whole body: not the signature, not the docblock. Write one line per behaviour, with the file and line that shows it.

Look for each of these before you close the list. They are the ones reviewers miss:

- what the call drops, skips, filters out or deduplicates;
- what it truncates, reorders or moves in time;
- what it creates: a row, a file, an id, a timestamp;
- a conversion, when the type that comes out differs from the type that goes in;
- the subset it selects: the latest, the active ones, the first match;
- a write, a dispatch or a cache invalidation behind a name that reads or checks;
- work the verb promises and the body does not do: a `send` that only builds a payload;
- a guarantee the body skips: a validation, a permission check, a date boundary.

Leave out what no caller relies on: a log line, a metric, a retry safeguard, the undo of the call's own failed writes.

For a class, the list is its methods' responsibilities. For a test, it is the condition the setup really creates and the outcome the assertions really prove.

## 3. Find the word that covers each behaviour

A covering word is **one word** of the name or of its signature: a word of the member name, a parameter name, a word of the class, file or namespace name, a declared type. One word covers one behaviour.

A behaviour with no covering word is **uncovered**.

These never cover a behaviour:

- a docblock, a comment, a `@param`, `@return` or `@throws` tag;
- the directory, the call site, a caller's variable, a test name, the pull request description;
- the whole identifier quoted at once: split it into words and name the one that carries the behaviour;
- "it is obvious in context", "it is private", "it has one caller", "it is an implementation detail".

A nullable return type covers a `null` returned for an absent value. It does not cover a `null` returned for an invalid input.

## 4. Take the verdict from the count

| Uncovered behaviours             | Verdict          |
| -------------------------------- | ---------------- |
| `0`                              | `keep`           |
| `1` or more                      | `rename`         |
| The name belongs to someone else | `fixed-contract` |

No other verdict exists. "Rename or document" is a check you skipped.

A `fixed-contract` name is never reported. It is one of these:

- a framework hook or a lifecycle method;
- a serialized field, a published route or a public API;
- a vendor interface;
- a convention of the language or the tool: `__construct`, `setUp`, `main`;
- a name built on the pattern every file of its folder follows;
- an id that unchanged files use for the same thing.

## 5. Write the finding

A finding names the file and line, the current name, the uncovered behaviour with the line that shows it, and **one** exact replacement.

The replacement:

- covers every behaviour of the name;
- uses the project's word for the concept. Grep it first, and never propose a term that exists nowhere in the code or the docs;
- says what the symbol does and returns, never who calls it or when;
- holds five words and 50 characters at most. When covering everything needs more, the finding is a split, not a rename: say which behaviours belong to which owner, under the "Responsibility" category;
- comes with the callers, imports and tests the rename touches.

A docblock never resolves an uncovered behaviour. Propose one replacement, never a choice between renaming and documenting.

Leave a name alone when the replacement would only:

- add words the class, the namespace or the parameter types already carry;
- swap a word for a synonym;
- be longer without covering an uncovered behaviour;
- differ from its twin in a file that does the same work.

## Consistency

- The same concept keeps the same name through a class, a module and its tests.
- Before you call a word vague, grep it in the folder. The word most names there use for the concept is the project's term.
- Flag generic names (`data`, `item`, `temp`, `x`) and abbreviations nothing explains.
- A parameter or a property is named for the value inside the receiver, not for the caller's workflow.

## What reaches the review

The audit runs on every name. The review posts three naming findings at most, in this order:

1. names that hide a write, a deletion or a skipped guarantee;
2. names that promise work the body does not do;
3. the others.

Write three numbers in `summary.md`: the names audited, the names with an uncovered behaviour, the naming findings posted.

## Worked example

`TalkRepository::findUpcoming(): array`. The body reads the talks, keeps the ones dated after today, drops the ones with no published slug, and returns their titles.

| Behaviour, with its line                        | Covering word |
| ----------------------------------------------- | ------------- |
| reads the talks, line 31                        | `Talk`        |
| keeps the ones dated after today, line 33       | `Upcoming`    |
| drops the talks with no published slug, line 34 | uncovered     |
| returns the titles, not the talks, line 38      | uncovered     |

Two behaviours are uncovered, so the verdict is `rename`. Replacement: `findPublishedUpcomingTitles(): array`, four words, with `Talk` still carried by the class name.

`findUpcoming` would be a `keep` only if the unpublished talks were included and the return value were the talks themselves.
