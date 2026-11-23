---
name: reviewing-architecture
description: Assess a codebase's structure against the architecture its own rules describe (layers, boundaries, responsibilities, coupling) and propose changes that pay for themselves. Use during the weekly audit and when a pull request adds a new component or dependency.
---

# Reviewing architecture

Load the `working-in-a-repository` skill first. Judge the code against the architecture the repository states (its `CLAUDE.md`, rules, docs, deptrac or similar configuration), not against your own taste.

## Map it

- List the top-level modules and what each is for, from the docs and the directory layout.
- Draw the dependencies between them from the `use` statements and the service wiring (for PHP: `grep -rhoE '^use [A-Za-z\\]+' src | sort | uniq -c`, or the repository's deptrac or dependency tooling when it has one).
- Note the external services the code depends on and where each one is called from.

## Look for

1. **Broken stated rules**: a layer importing one it must not, a framework type leaking into domain code, a controller doing more than one action when the rules require single-action controllers, classes not `final`/`readonly` where the rules require it.
2. **Misplaced responsibilities**: business logic in controllers, templates or console commands; HTTP or persistence details in domain objects; one class doing parsing, fetching, caching and rendering.
3. **Coupling that blocks change**: concrete classes injected where an interface exists, the same external API called from several places, cyclic dependencies between modules, global state.
4. **Missing seams**: external services without an abstraction, so they cannot be cached, replaced or tested; no timeout or fallback policy in one place.
5. **Duplication**: the same rule implemented twice, copy-pasted handlers or templates drifting apart.
6. **Dead weight**: unused services, routes, configuration, dependencies (`composer why`, `composer-unused`, `depcheck`), feature flags that are always on.

## Propose only what pays

For each finding: the problem with file and line links, the concrete cost today (a bug it caused, a change it made harder, a test it prevents), the smallest change that fixes it, and the risk of doing it. Skip findings whose fix costs more than the problem.
