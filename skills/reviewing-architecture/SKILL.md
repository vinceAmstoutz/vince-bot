---
name: reviewing-architecture
description: "Judges a codebase's structure against the architecture its own rules state (layers, boundaries, responsibilities, coupling) and proposes only changes that pay for themselves. ALWAYS load when auditing a repository's architecture and when a pull request under review adds a class, a service, a module, an abstraction or a dependency. DO NOT report a design problem without this skill: a design finding with no broken rule and no concrete cost is personal taste. SKIP for a wrong result (use `finding-bugs`) and for a name alone, which the naming reference of the `reviewing-pull-requests` skill owns."
---

# Reviewing architecture

Judge the code against the architecture the repository states: its `CLAUDE.md`, its rules, its docs, its deptrac or similar configuration. Never judge it against your own taste. In a checkout, load the `working-in-a-repository` skill first.

## Map it

Do this for an audit. In a pull request review, map only the modules the diff touches.

- List the top-level modules and what each is for, from the docs and the directory layout.
- Draw the dependencies between them from the `use` statements and the service wiring. For PHP: `grep -rhoE '^use [A-Za-z\\]+' src | sort | uniq -c`, or the repository's own dependency tooling when it has one.
- Note the external services the code depends on and where each one is called from.

## Checklist

Work through every check, in this order. Note `none found` for a check with no result. Never skip one.

1. **Broken stated rules**: a layer that imports one it must not, a framework type that leaks into domain code, a controller with several actions where the rules require one, a class that is not `final` or `readonly` where the rules require it.
2. **Misplaced responsibilities**: business logic in a controller, a template or a console command. HTTP or persistence details in a domain object. One class that parses, fetches, caches and renders.
3. **Coupling that blocks change**: a concrete class injected where an interface exists, the same external API called from several places, a cycle between modules, global state.
4. **Missing seams**: an external service with no abstraction, so it cannot be cached, replaced or tested. No single place for its timeout and fallback policy.
5. **Duplication**: the same business rule implemented twice, copied handlers or templates that drift apart.
6. **Dead weight**: unused services, routes, configuration or dependencies (`composer why`, `composer-unused`, `depcheck`), a feature flag that is always on.

## Checks for added code

Apply these to each class, abstraction or dependency a change adds.

- **Closest existing owner**: find the existing class that already does this kind of work. Compare responsibilities and callers. Name that file in the finding.
- **Neighbours**: compare the addition with the files next to it that do the same kind of work: placement, naming and contract. Name the file you compared it with when you report a difference.
- **One consumer proves nothing**: a single caller or a single implementation is not redundancy. Name the maintenance cost or the misplaced responsibility, and the simpler alternative.
- **Check the alternative**: before you propose to remove or reuse something, verify that the alternative keeps the behaviour and the contract.
- **Size is a lead, not a finding**: a function over about 50 lines or a class over about 200 lines deserves a closer look. Report the distinct responsibilities to separate, never the length alone.
- **Producers and consumers**: read them together when their interaction depends on behaviour that types do not enforce.

## Propose only what pays

For each finding, give:

1. the problem, with file and line;
2. the concrete cost today: a bug it caused, a change it made harder, a test it prevents;
3. the smallest change that fixes it, and the risk of doing it.

Skip a finding whose fix costs more than the problem.

In a pull request review, report at most the three design problems with the largest consequence, in three sentences each at most. Pieces that do not work together are `🟠 major`. A design that works but costs more to maintain than a simpler one is `⚪ nit`. Finding none is a valid answer: do not reread files to find something to report.

## What to skip

- A duplicate of a few lines in two or three places. Do not ask for a new helper to remove it.
- A dependency rule that deptrac, a linter or static analysis already enforces.
- Code marked temporary, legacy or one-shot: report only what can lose data or open a security hole.
- A pattern the repository's rules do not ask for, however common it is elsewhere.
- A refactor of code the change did not touch.
