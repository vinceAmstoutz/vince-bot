# Review rules: GitHub Actions and CI scripts

Read a changed workflow or composite action together with the actions and the scripts it calls. A workflow is right only when the whole path through them is right.

## Checks

- **Names and scope**: compare each workflow, job, step, action and script name with the commands it runs, its conditions and the projects it covers. Flag a name that promises a check it does not run, or that hides a write behind a check-only name. Propose the exact name and list the callers to update.
- **Plain names**: compare the names with the existing workflows. Flag a complex label, or a new synonym for an operation the repository already names. For a step that only lints PHP, propose `Lint PHP`, not `Run the quality gate`.
- **Purpose**: compare an added action, workflow or script with the existing ones. Flag a duplicate, and a wrapper that adds no input, no setup, no permission and no failure handling. Name the existing one to reuse. Do not ask to merge two actions whose inputs or post-run steps differ.
- **The path**: trace inputs, outputs, `if:` conditions and failure handling from the trigger to the last step. Name the execution path that shows a mismatch: which event, which input value, which step.
- **Untrusted values**: a value from an event (a title, a body, a branch name, a comment) never appears inside a `run:` script as `${{ … }}`. It goes through `env:` and is quoted where the script expands it.
- **Secrets and permissions**: check each secret and each token permission against the steps that need it. Name any path that gives a secret or a write token to untrusted code or to the log. `pull_request_target`, `issue_comment` and `workflow_run` run with the base repository's secrets: check which code they check out and run.
- **Triggers and concurrency**: check the event filters and the concurrency groups. Name an unrelated event that can start the run, or cancel work that must finish. Before you ask to change a concurrency group, name the two events that collide and show that your change stops the collision.
- **Failure propagation**: a failed prerequisite blocks the work that depends on it. In a shell pipeline, check that the exit status belongs to the command that must succeed: look at `set -o pipefail`, `|| true` and `continue-on-error`.
- **Agent permissions**: an agent's tool allowlist is a list of command permissions. Read the tools, flags and operations it allows before you accept that access is read-only. Flag a grant wider than the steps need, and name the narrower one. Before you ask to deny a tool or a flag, check that the agent cannot get the same access another way. When it can, do not ask.
- **Parsed inputs**: when an action parses a multiline input itself, read the parser before you accept a comment or a blank line inside that input.
- **Version pins**: before you report an action's version or the way it is pinned, compare with how the other workflows pin the same action.

## Checklist items

These extend the categories of the review checklist for CI files:

1. **Naming**: workflow, job, step, action and script names use plain, established words and match their scope and side effects.
2. **Responsibility**: actions and workflows have a useful job and do not duplicate an existing one.
3. **Bugs and logic errors**: inputs, outputs, conditions, prerequisites and failure propagation.
4. **Security**: untrusted values, secret access, token permissions and agent permissions.
5. **Breaking changes**: event filters, cancellation, parsed inputs and version pins.
