# Review rules: manifests and lock files

These rules cover `composer.json`, `composer.lock`, `package.json`, `package-lock.json`, `yarn.lock` and `pnpm-lock.yaml`.

Do not review a lock file line by line. Find which packages changed, and report what is suspicious.

A lock file diff of more than about 200 changed lines is a bulk operation. Skip the per-package checks for it and say so in `summary.md`. The manifest checks still apply.

## Read the manifest and the lock file together

The manifest states the intent. The lock file shows what was resolved.

| What changed                                             | Meaning                                                                              |
| -------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| A requirement in the manifest, and the lock file follows | Check the change itself, below.                                                      |
| A requirement in the manifest, and the lock file did not | `🟠 major`: the lock file must be regenerated with the repository's own tooling.     |
| The lock file only                                       | A transitive update or a regeneration. Note it in `summary.md`. It is not a finding. |
| The manifest's scripts only                              | No proof that the dependencies are stale. Do not ask for a regeneration.             |

## Classify each direct change

Mark each direct package as added, removed or changed, with the version it comes from and the version it goes to.

Report as `🟠 major`:

- a major version jump, when the upgrade guide lists a breaking change that touches code the repository calls. Name the call site: a version number alone proves nothing;
- a removed package the code still imports or requires. Grep to prove it;
- a downgrade.

Report as `⚪ nit`:

- a new package the description does not justify, or that a package already installed covers. Name that package;
- transitive changes out of proportion with the direct change: one update that brings ten new packages.

## Manifest scripts

- Compare an added or changed script name with the commands, flags and paths it runs. Flag a name that hides a write, or that promises a check or a scope it leaves out.
- Flag a new synonym for an operation the sibling scripts already name. When they use `lint:<scope>`, propose `lint:php`, not `quality:php`, for a script that only lints PHP.
- Compare an added script with the existing scripts and entry points before you report a duplicate. A wrapper is useful when it adds a scope, a setup or a sequence of commands.
- Never ask to rename a third-party package or a generated lock entry.

## Summary line

List the direct changes in one line of `summary.md`, for example:

> Updated `symfony/http-client` 7.3 → 8.0, added `league/commonmark` 2.7, removed `erusev/parsedown`.

## Checklist items

These extend the categories of the review checklist for manifests and lock files:

1. **Naming**: script names use plain words and established command terms, and match their commands and scope.
2. **Breaking changes**: a requirement changed with no lock update, a major jump with a proven break, a downgrade.
3. **Security**: a removed package the code still imports, transitive additions out of proportion.
4. **Repository rules**: the lock file was regenerated with the repository's tooling, never by hand.
