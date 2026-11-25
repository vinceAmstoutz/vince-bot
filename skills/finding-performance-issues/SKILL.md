---
name: finding-performance-issues
description: "Finds, proves and fixes performance problems in a web application (slow pages, slow endpoints, heavy assets, slow CI) by measuring before and after. ALWAYS load when the bot's probe reports a slow page, when auditing a repository for performance, and when a pull request under review adds a query, a remote call, a loop over a collection or an asset on a request path. DO NOT call code slow without this skill: a performance finding with no number is a guess. SKIP for a wrong result or a crash (use `finding-bugs`)."
---

# Finding performance issues

Every finding needs a number before. Every fix needs a number after. In a checkout, load the `working-in-a-repository` skill first.

## What you produce

| Loaded by                | Number you need                                                               | Output                                |
| ------------------------ | ----------------------------------------------------------------------------- | ------------------------------------- |
| A slow page to fix       | The median time before and after, measured the same way                       | The fix, or the cause and two options |
| The `weekly-audit` skill | A measurement, or a count of queries or remote calls per request              | A candidate finding for that skill    |
| A pull request review    | What the change adds per request or per item, counted in the code (see below) | A review comment                      |

## 1. Measure

- **A reported slow page**: the probe's measurements are in `$AGENT_CONTEXT/request.md` (time to first byte, total time, size, Lighthouse scores when available). Reproduce locally: start the stack the way the repository documents (`docker compose up`, `bin/castor up`, …) and warm it up. Then time the URL several times with `curl -s -o /dev/null -w '%{time_starttransfer} %{time_total}\n'` and keep the median.
- **Server side**: find what the request does. In Symfony, read the route's controller and everything it calls. Enable the profiler in the dev environment (`/_profiler`) to see the time spent in controllers, Twig, Doctrine queries, HTTP client calls and cache. Time a suspect block with `hrtime(true)` when nothing else tells you.
- **Front end**: run Lighthouse on the page (`npx lighthouse <url> --only-categories=performance --output=json --chrome-flags='--headless=new'`). Read the largest contentful paint element, the render-blocking resources, the image sizes and the unused JavaScript.
- **In a review**: do not start the stack. For each loop the change adds on a request path, open what its body calls and state what one iteration costs: a query, a remote call, a file read, an allocation. "No query" and "in memory only" are claims to prove with the code of the helper, not answers.

Write the baseline in your summary before you change anything.

## 2. Find the cause

Check every item, in order of how often it hurts. Note `none found` for an item with no result.

1. **Remote calls on the request path**: an HTTP API (GitHub, Mastodon, RSS, analytics) called while a page renders. Fix with a cache that has an explicit lifetime (Symfony Cache `CacheInterface::get()` with `expiresAfter`, stale-while-revalidate where the data allows), a background refresh (Messenger, a scheduled command), and a timeout plus a fallback, so an outage never becomes a 500 or a 30-second page.
2. **Database**: N+1 queries (a query per item in a loop, lazy-loaded relations in Twig), a missing index on a filtered or sorted column, an unbounded result set, entities hydrated where a scalar query is enough.
3. **Missing HTTP caching**: a read-only page without `#[Cache(maxage: …, smaxage: …, public: true)]`, ETag or Last-Modified. A personalised fragment that keeps the whole page out of the cache: move it to an ESI or a client-side request.
4. **Repeated work per request**: config parsing, file reads, regex compilation, container lookups or expensive computations that are not memoised. Under FrankenPHP worker mode, also look for state that leaks between requests (a static cache that grows, a service that keeps references) and for work that could run once at boot.
5. **Templates**: heavy logic in Twig, the same query or service call repeated in includes, a large loop that renders components one by one.
6. **Assets**: images that are oversized or not optimised (no `width` and `height`, no modern format, no lazy loading below the fold), render-blocking CSS or JavaScript, fonts without `font-display`, fingerprinted assets without compression and long cache headers.
7. **Infrastructure**: OPcache and preloading settings, Caddy compression and cache headers, PHP worker count, container memory limits.
8. **CI**: a step that reinstalls what could be cached, serial jobs that could run in parallel, an oversized test matrix.

## 3. Fix and prove it

1. Fix the root cause with the smallest change, following the repository's rules. When it asks for tests first, write them first: for example a test proving the page still renders when the remote API fails or times out, and one proving the second call hits the cache.
2. Measure again the same way. Report before and after side by side.
3. When the number does not move, the change is not a performance fix: revert it and look again.

Never trade correctness for speed silently. A cache needs a lifetime and an invalidation story, both written in the summary.

## Reporting without a fix

When the fix is too large or needs a decision (a new service, a schema change, a product choice), change nothing. Describe the cause, the evidence (the numbers, the call path with file and line) and two options with their cost.

## What to skip

- A micro-optimisation with no measured effect.
- Code off the request path, such as a migration or a one-shot command, unless you can show the data volume that makes it slow.
- "This could be cached" with no lifetime and no way to invalidate.
- A slow test or CI step you did not time.
