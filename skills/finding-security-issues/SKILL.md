---
name: finding-security-issues
description: "Finds exploitable security weaknesses in a web application across the OWASP Top 10, with Symfony-specific checks, and traces each one from the attacker's input to its impact. ALWAYS load when auditing a repository for security, when triaging the security auditor's report, and when a pull request under review touches authentication, access control, input handling, output escaping, secrets, configuration, dependencies or CI workflows. DO NOT report a weakness without this skill: an untraced finding is dropped, and a finding posted in public discloses the vulnerability. SKIP for a bug no attacker can use (use `finding-bugs`)."
---

# Finding security issues

Report only what you can show to be exploitable or clearly unsafe, with the path from the attacker's input to the impact. In a checkout, load the `working-in-a-repository` skill first. In a Symfony application, also read [symfony.md](references/symfony.md): the entry points, sinks and guards the framework adds.

## Never disclose in public

- **Private repository**: a finding can go into the repository's own issues.
- **Public repository**: write the finding in `summary.md` for the owner. Draft no public issue, no public comment, no pull request title or commit message that names the weakness.

## Map the attack surface

Before the checklist, list in your notes:

- **Entry points**: the routes, and those that no route list and no `access_control` rule shows: operations declared by attributes (API Platform), actions the browser calls on a component (Live Components), message handlers, webhook consumers, console commands and scheduled tasks, template functions and filters, admin panels.
- **Who reaches each one**: an anonymous visitor, a logged-in user, an administrator, another system. Name the firewall, rule, attribute or voter that decides it.
- **Sinks**: grep for queries, shell commands, file paths, deserialization, redirects, outgoing HTTP and raw output. [symfony.md](references/symfony.md#sinks-to-grep) lists the patterns.

Then audit one feature at a time: a controller with its entity, repository, form, voter and templates. A check missing in one file is often made in another.

In a pull request review, map only the entry points the diff adds or reaches.

## Checklist

Work through every check, in this order: one per category of the OWASP Top 10:2025. Note `none found` for a check with no result. Never skip one. In a Symfony application, also apply each section of [symfony.md](references/symfony.md) that matches a surface of the map.

1. **A01:2025 Broken access control**: every entry point that reads or changes data enforces who may do it (`#[IsGranted]`, voters, `access_control`, firewalls). Look for an id taken from the request with no ownership check (IDOR), a list or search not scoped to the user, an admin or debug route reachable in production, a broad rule in `security.yaml` that shadows a strict one below it, a voter that grants by default or checks a role where the resource needs an ownership check, a sensitive field (password hash, token, internal id) serialized to someone who should not see it, a state-changing form or endpoint without CSRF protection, a state change on GET, an open redirect (`redirect($request->get('url'))`), and SSRF in a feature that fetches a user-supplied URL, including the redirects it follows.
2. **A02:2025 Security misconfiguration**: `APP_DEBUG` or the profiler enabled in production, permissive CORS (any origin with credentials, an origin regex not anchored), missing security headers (HSTS, `X-Content-Type-Options`, `Referrer-Policy`, `frame-ancestors`), a Content Security Policy that is missing or allows `unsafe-inline` or `unsafe-eval`, cookies without `Secure`, `HttpOnly` and `SameSite` (the remember-me cookie too), trusted proxies set to any address, no trusted hosts while absolute URLs are built from the request, an XML parser that loads external entities (XXE), a firewall with `security: false` over a protected path.
3. **A03:2025 Software supply chain failures**: run the ecosystem's audit (`composer audit`, `npm audit --omit=dev`), then check that the application really calls the vulnerable code. Flag a dependency installed from a fork or a VCS branch, and an application with no committed lock file. In CI: a workflow on `pull_request_target`, `issue_comment` or `workflow_run` that runs untrusted code or text, an action not pinned to a commit SHA, a token with more permissions than its steps need, untrusted input written into a `run:` script.
4. **A04:2025 Cryptographic failures**: a secret, key or password committed; passwords hashed with anything but the framework's `auto` hasher (bcrypt, Argon2id); MD5 or SHA-1 used for a password, signature or token; a token, reset code or file name made with `rand()`, `mt_rand()` or `uniqid()` instead of `random_bytes()` or `random_int()`; a signature or token compared with `==` or `===` instead of `hash_equals()`; a hard-coded key or IV; TLS verification turned off (`verify_peer: false`, `verify_host: false`); sensitive data sent over plain HTTP.
5. **A05:2025 Injection**: SQL or DQL built by concatenation, including `ORDER BY`, `LIMIT` and column names, which query parameters never cover; shell commands (`Process::fromShellCommandline()`, `exec()`); LDAP filters and DNs without `ldap_escape()`; a file path built from input (path traversal) and `include` of a variable path; input compiled as a template (`createTemplate()`, a dynamic `include`) or as an expression (`ExpressionLanguage`); header injection. Cross-site scripting: `|raw` and `{% autoescape false %}` on user-controlled data, a value written into a `<script>` block or an `on*` attribute without `|e('js')`, a URL attribute that accepts `javascript:`, a Twig function or filter marked `is_safe` that returns input unescaped, HTML built in PHP or with `innerHTML`, Markdown rendered without sanitising, an HTML sanitizer that allows scripts or `on*` attributes.
6. **A06:2025 Insecure design**: a price, quantity, discount or role the server takes from the client; a workflow step skipped by setting a status directly; a race on a balance, a stock, a coupon or a single-use token with no lock and no database constraint. Abuse: a form or endpoint without rate limiting (contact, login, password reset, search), a limiter keyed by a constant instead of the user or the IP, a mail relay, unbounded uploads, request bodies or result pages, a regular expression open to catastrophic backtracking.
7. **A07:2025 Authentication failures**: an authenticator that skips the credential check or accepts more requests than it should; a login, password reset or registration whose answer or timing tells whether an account exists; a reset or verification token that is predictable, never expires or can be reused, or that is sent in a link built from the request's `Host` header; a JWT or access token accepted without checking its signature, issuer, audience and expiry; an OAuth or OIDC callback without `state` (and PKCE for a public client); a session id kept across login; an LDAP bind that accepts an empty password; no limit on login attempts.
8. **A08:2025 Software or data integrity failures**: `unserialize()` on data a user or another system can write (cookies, cache, queue messages, hidden fields); a queue others can write to, read with PHP's native serializer; a webhook or callback accepted without verifying its signature, or without a timestamp, nonce or idempotency key against replay; mass assignment, where a form, a serializer group, a request DTO or a component property lets the client set `roles`, an owner, a price or a flag; a file, update or plugin downloaded and run without checking its signature or hash.
9. **A09:2025 Logging and alerting failures**: passwords, tokens, session ids or personal data written to logs or sent to an error tracker; user input written raw into a log line that a person or a parser reads (log forging); logs, dumps or backups reachable over HTTP. A log or an alert that is only missing has no attack behind it: at most a `⚪ nit` in a review.
10. **A10:2025 Mishandling of exceptional conditions**: code that fails open, such as a `catch` in a voter, an authenticator, a payment or a signature check that grants access or carries on; an error page, API error or exception listener that returns stack traces, SQL, file paths or `$e->getMessage()` to the client; a change in several steps (payment, transfer, stock) with no transaction, left half done when a step throws; a message handler or job that swallows a failure or retries it forever.

## Proof

Trace each candidate from the entry point to the sink, file by file. Name every guard on the way and say why it does not stop the attack:

- firewall and `access_control` rules, voters and `#[IsGranted]`;
- validation constraints and type casts;
- escaping, in Twig and in the query builder;
- framework defaults. Prove a default from the docs of the installed version or from the code in `vendor/`, never from memory.

The guards that most often stop an attack are listed in [symfony.md](references/symfony.md#guards-that-stop-an-attack). Drop a candidate when one of them covers its path, and name it.

Write a failing test or a request that shows the attack when the repository allows it. A finding you could not trace end to end is dropped, not softened.

A comment that says the code is safe does not count. A test the same change adds does not count either: it records what the author believes.

## Severity

Rate by impact and by who can trigger it: an anonymous visitor, a logged-in user, an administrator.

| Severity | For example                                                                                                                       |
| -------- | --------------------------------------------------------------------------------------------------------------------------------- |
| critical | Code execution, an authentication bypass or a mass data leak open to an anonymous visitor; a production secret committed.         |
| high     | Code execution or SQL injection a logged-in user can reach, access to another user's or tenant's data, privilege escalation.      |
| medium   | Stored XSS, CSRF on a state change, SSRF that reaches an internal service, a race on money or stock.                              |
| low      | Reflected XSS with little impact, disclosure of metadata that is not sensitive, weak cryptography on data that is already public. |

In a pull request review, an exploitable path is `🟠 major` and a missing hardening with no attack is `⚪ nit`.

## Report

For each finding: its OWASP category, the entry point and the sink with file and line, the attack in one or two sentences, who can trigger it, the impact and the severity, the fix, and how to verify the fix.

## What to skip

- A weakness that needs an account already able to do the same damage, such as an administrator.
- A best practice with no attack behind it.
- A fake secret in a test fixture or in an example file.
- A vulnerable package whose vulnerable code the application never calls. Say so in `summary.md` instead.
