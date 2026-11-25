---
name: finding-security-issues
description: "Finds exploitable security weaknesses in a web application, with Symfony-specific checks, and traces each one from the attacker's input to its impact. ALWAYS load when auditing a repository for security, when triaging the security auditor's report, and when a pull request under review touches authentication, access control, input handling, output escaping, secrets, configuration or CI workflows. DO NOT report a weakness without this skill: an untraced finding is dropped, and a finding posted in public discloses the vulnerability. SKIP for a bug no attacker can use (use `finding-bugs`)."
---

# Finding security issues

Report only what you can show to be exploitable or clearly unsafe, with the path from the attacker's input to the impact. In a checkout, load the `working-in-a-repository` skill first.

## Never disclose in public

- **Private repository**: a finding can go into the repository's own issues.
- **Public repository**: write the finding in `summary.md` for the owner. Draft no public issue, no public comment, no pull request title or commit message that names the weakness.

## Checklist

Work through every check, in this order. Note `none found` for a check with no result. Never skip one.

1. **Access control**: every route that reads or changes data enforces who may do it (`#[IsGranted]`, voters, `access_control`, firewalls). Look for an id taken from the request with no ownership check (IDOR), an admin or debug route reachable in production, and a broad rule in `security.yaml` that shadows a strict one below it.
2. **Injection**: SQL or DQL built by concatenation, shell commands, LDAP, a file path built from input (path traversal), `unserialize()` on untrusted data, user input passed to `createTemplate()`, header injection.
3. **Cross-site scripting**: `|raw` and `{% autoescape false %}` on user-controlled data, HTML built in PHP or with `innerHTML`, Markdown rendered without sanitising, a missing or weak Content Security Policy.
4. **Request forgery**: a state-changing form or endpoint without CSRF protection, a state change on GET, an open redirect (`redirect($request->get('url'))`), SSRF in a feature that fetches a user-supplied URL.
5. **Secrets and configuration**: a secret committed or logged, `APP_DEBUG` or the profiler enabled in production, permissive CORS, missing security headers (HSTS, `X-Content-Type-Options`, `Referrer-Policy`, `frame-ancestors`), cookies without `Secure`, `HttpOnly` and `SameSite`.
6. **Abuse**: a form or endpoint without rate limiting (contact, login, password reset, search), a mail relay, unbounded uploads or request bodies, a regular expression open to catastrophic backtracking.
7. **Dependencies**: run the ecosystem's audit (`composer audit`, `npm audit --omit=dev`). Then check that the application really calls the vulnerable code.
8. **CI and supply chain**: a workflow on `pull_request_target`, `issue_comment` or `workflow_run` that runs untrusted code or text, an action that is not pinned, a token with more permissions than its steps need, untrusted input written into a `run:` script.

## Proof

Trace each candidate from the entry point to the sink, file by file. Name every guard on the way and say why it does not stop the attack:

- firewall and `access_control` rules, voters and `#[IsGranted]`;
- validation constraints and type casts;
- escaping, in Twig and in the query builder;
- framework defaults. Prove a default from the docs of the installed version or from the code in `vendor/`, never from memory.

Write a failing test or a request that shows the attack when the repository allows it. A finding you could not trace end to end is dropped, not softened.

A comment that says the code is safe does not count. A test the same change adds does not count either: it records what the author believes.

## Severity

Rate by impact and by who can trigger it: an anonymous visitor, a logged-in user, an administrator. In a pull request review, an exploitable path is `🟠 major` and a missing hardening with no attack is `⚪ nit`.

## Report

For each finding: the entry point and the sink with file and line, the attack in one or two sentences, the impact, the fix, and how to verify the fix.

## What to skip

- A weakness that needs an account already able to do the same damage, such as an administrator.
- A best practice with no attack behind it.
- A fake secret in a test fixture or in an example file.
- A vulnerable package whose vulnerable code the application never calls. Say so in `summary.md` instead.
