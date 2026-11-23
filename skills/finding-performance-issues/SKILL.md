---
name: finding-performance-issues
description: Find, prove and fix performance problems in a web application (slow pages, slow endpoints, heavy assets, slow CI) by measuring first. Use for a slow page reported by the bot's probe, during the weekly audit, and when reviewing a change that touches a hot path.
---

# Finding performance issues

Load the `working-in-a-repository` skill first. Performance work without a measurement is guessing: every finding needs a number before and, for a fix, a number after.

## 1. Measure

- **A reported slow page**: the probe's measurements are in `$AGENT_CONTEXT/request.md` (time to first byte, total time, size, Lighthouse scores when available). Reproduce locally: start the stack the way the repository documents (`docker compose up`, `bin/castor up`, …), warm it up, then time the URL several times with `curl -s -o /dev/null -w '%{time_starttransfer} %{time_total}\n'` and keep the median.
- **Server side**: find what the request does. In Symfony, read the route's controller and everything it calls; enable the profiler in the dev environment (`/_profiler`) to see the time spent in controllers, Twig, Doctrine queries, HTTP client calls and cache, or use `debug:router`, `debug:container` and logs. Time a suspect block with `hrtime(true)` when nothing else tells you.
- **Front end**: run Lighthouse on the page (`npx lighthouse <url> --only-categories=performance --output=json --chrome-flags='--headless=new'`), and read the largest contentful paint element, render-blocking resources, image sizes and unused JavaScript.
- Write the baseline in your summary before changing anything.

## 2. Find the cause

Check, in order of how often they hurt:

1. **Remote calls on the request path**: HTTP APIs (GitHub, Mastodon, RSS, analytics) called while rendering a page. Fix with a cache with an explicit lifetime (Symfony Cache `CacheInterface::get()` with `expiresAfter`, stale-while-revalidate where the data allows), a background refresh (Messenger, a scheduled command), and a timeout plus a fallback so an outage never becomes a 500 or a 30-second page.
2. **Database**: N+1 queries (a query per item in a loop, lazy-loaded relations in Twig), missing indexes on filtered or sorted columns, unbounded result sets, hydrating entities where a scalar query is enough.
3. **Missing HTTP caching**: read-only pages without `#[Cache(maxage: …, smaxage: …, public: true)]`, ETag or Last-Modified; personalised fragments preventing the whole page from being cached (move them to an ESI or a client-side request).
4. **Repeated work per request**: config parsing, file reads, regex compilation, container lookups or expensive computations not memoised. Under FrankenPHP worker mode, also look for state leaking between requests (static caches that grow, services that keep references) and for work that could be done once at boot.
5. **Templates**: heavy logic in Twig, the same query or service call repeated in includes, large loops rendering components one by one.
6. **Assets**: unoptimised or oversized images (no `width`/`height`, no modern format, no lazy loading below the fold), render-blocking CSS or JavaScript, fonts without `font-display`, compression and long cache headers missing for fingerprinted assets.
7. **Infrastructure**: OPcache and preloading settings, Caddy compression and cache headers, PHP worker count, container memory limits.
8. **CI**: steps that reinstall what could be cached, serial jobs that could run in parallel, oversized test matrices.

## 3. Fix and prove it

- Fix the root cause, smallest change first, following the repository's rules (tests first when it asks for that: for example a test proving the page still renders when the remote API fails or times out, and one proving the second call hits the cache).
- Measure again the same way and report before and after side by side. A change that does not move the number is not a performance fix; revert it.
- Never trade correctness for speed silently: a cache must have a lifetime and an invalidation story, written in the summary.

## Reporting without a fix

When the fix is too large or needs a decision (a new service, a schema change, a product choice), change nothing and describe the cause, the evidence (numbers, the call path with file and line) and two options with their cost.
