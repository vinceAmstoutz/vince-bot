---
name: finding-security-issues
description: Find exploitable security weaknesses in a web application, with Symfony-specific checks, and verify each before reporting. Use during the weekly audit, when triaging the security auditor's report, and when reviewing a change that touches authentication, input handling or configuration.
---

# Finding security issues

Load the `working-in-a-repository` skill first. Report only what you can show to be exploitable or clearly unsafe, with the path from attacker input to impact. Never disclose a vulnerability publicly: findings go into the repository's own issues only when it is private; for a public repository, write them in `summary.md` for the owner and draft no public issue.

## Checks

1. **Access control**: every route that reads or changes data enforces who may do it (`#[IsGranted]`, voters, `access_control`, firewalls). Look for IDs taken from the request without an ownership check (IDOR), admin or debug routes reachable in production, and `security.yaml` rules ordered so a broad rule shadows a strict one.
2. **Injection**: SQL built by concatenation (DQL included), shell commands, LDAP, file paths built from input (path traversal), `unserialize()` on untrusted data, template injection (user input passed to `createTemplate()`), header injection.
3. **Cross-site scripting**: `|raw` and `{% autoescape false %}` on user-controlled data, HTML built in PHP or JavaScript with `innerHTML`, Markdown rendered without sanitising, missing or weak Content Security Policy.
4. **Request forgery**: state-changing forms or endpoints without CSRF protection, state changes on GET, open redirects (`redirect($request->get('url'))`), SSRF in features that fetch a user-supplied URL.
5. **Secrets and configuration**: secrets committed or logged, `APP_DEBUG`/the profiler enabled in production, permissive CORS, missing security headers (HSTS, `X-Content-Type-Options`, `Referrer-Policy`, `frame-ancestors`), cookies without `Secure`, `HttpOnly` and `SameSite`.
6. **Abuse**: forms and endpoints without rate limiting (contact, login, password reset, search), mail relays, unbounded uploads or request bodies, regular expressions open to catastrophic backtracking.
7. **Dependencies**: run the ecosystem's audit (`composer audit`, `npm audit --omit=dev`) and check whether the vulnerable code path is actually used.
8. **CI and supply chain**: workflows using `pull_request_target` or `issue_comment` with untrusted code or text, actions not pinned, tokens with more permissions than needed, untrusted input interpolated into `run:` scripts.

## Verify

For each candidate, trace the data from the entry point to the sink, file by file, and confirm no validation, escaping or authorization stops it. Write a failing test or a request that demonstrates it when the repository allows it. Rate the severity by impact and exploitability (CVSS-like reasoning: who can trigger it, what they get).

## Report

Per finding: the entry point and sink with file and line links, the attack in one or two sentences, the impact, the fix, and how to verify the fix. Drop anything you could not trace end to end.
