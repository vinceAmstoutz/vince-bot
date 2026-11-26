# Symfony checks

Read with the checklist of [SKILL.md](../SKILL.md). Each section covers one surface: apply it when the map found that surface. A default named here still has to hold in the installed version: check it in `vendor/` before you rely on it.

## Entry points outside the route list

These answer requests, yet no controller and no `access_control` rule shows them unless a path pattern happens to cover them.

- **API Platform**: every operation (`Get`, `GetCollection`, `Post`, `Put`, `Patch`, `Delete`, or the resource's default) needs `security`. On a write, `security` runs before the payload is applied, against the old object: an ownership check on writable data needs `securityPostDenormalize`. A `GetCollection` returns every row unless an extension or a provider scopes it to the user. A `SearchFilter` on `email`, a token or a foreign key leaks data even when items are denied. `paginationEnabled: false` or client-controlled pagination returns everything. A custom state provider or processor skips the checks the equivalent controller would make.
- **Live Components**: each `#[LiveAction]` is a POST anyone can send. The access check of the page that renders the component does not cover it: it needs its own `#[IsGranted]` or `denyAccessUnlessGranted()`. The browser sets every `#[LiveProp(writable: true)]`: flag one that holds an id, a price, a quantity or a role. A `hydrateWith` that builds objects from client data is deserialization.
- **Twig extensions**: every template can call a function or a filter. Flag one that reads files, runs a process or loads an entity without an access check, one marked `is_safe: ['html']` that returns input it did not sanitise, and globals that hand secrets or the whole user object to every template.
- **Messenger handlers and scheduled tasks**: no user stands behind a message. Flag a privileged action that trusts the user id the message carries, a handler with side effects (payment, email, balance) that does not deduplicate, a task that runs a shell command or fetches a URL read from the database, and a task that can overlap with itself without a lock.
- **Webhook consumers** (`RequestParserInterface`, `#[AsRemoteEventConsumer]`): the signature must be checked with `hash_equals()` against a secret from the environment, a timestamp or an event id must stop replay, and the user id or amount of the payload must be checked against the application's own records.
- **EasyAdmin and Sonata Admin**: access is checked per dashboard or per admin class, not per field, action or row. Flag a field that exposes `roles`, `password` or `isAdmin` without `setPermission()`, a delete or batch action without a role of its own, and a multi-tenant admin with no row filter (`createIndexQueryBuilder()` in EasyAdmin, a voter in Sonata).

## Configuration

Read `config/packages/`, its `prod/` folder and `when@prod` blocks, and every committed `.env` file.

- **`security.yaml`**: `access_control` rules are tried from top to bottom and the first match wins, so a broad pattern above a strict one disables it, and a `path` not anchored with `^` matches anywhere in the URL. Flag `security: false` on a firewall over protected paths, `access_decision_manager.allow_if_all_abstain: true`, a password hasher other than `auto`, bcrypt or Argon2, and `session_fixation_strategy: none`.
- **`framework.yaml`**: `trusted_proxies` set to `0.0.0.0/0` or `::/0` lets any client spoof `X-Forwarded-For`, which IP allow-lists and rate limiters trust. Without `trusted_hosts`, the `Host` header is the attacker's: every absolute URL built from the request, by hand or by the router with `ABSOLUTE_URL`, can point a reset or verification link at the attacker's site. Also flag a session cookie with `cookie_secure: false` or `cookie_samesite: none`, an HTTP client with `verify_peer: false`, an `html_sanitizer` that allows `script` or `on*` attributes, and a Messenger transport without `serializer`: the default is PHP's native serializer.
- **`.env`**: `APP_DEBUG=1` with no production override, `MERCURE_JWT_SECRET` left at the recipe's placeholder, a Mercure `publish` or `subscribe` claim of `*`, a real secret instead of a `%env()%` reference or a vault entry.
- **Routes**: `_profiler` and `_wdt` loaded outside `when@dev`.
- **NelmioCorsBundle and NelmioSecurityBundle**: `allow_origin: ['*']` with `allow_credentials: true`, `origin_regex: true` with a pattern not anchored by `^…$`, a CSP with `unsafe-inline` or `unsafe-eval`, forced SSL turned off.

## Authentication

- An authenticator whose `supports()` returns `null`, which means yes, or `true` for every request; a `SelfValidatingPassport` on a flow that carries a password; form login without a `CsrfTokenBadge`; a `RememberMeBadge` added although the user did not ask for it.
- `onAuthenticationSuccess()` redirecting to `_target_path` or the referer without checking the host.
- An access token handler that does not verify the token's signature, issuer, audience and expiry; an OAuth callback without `state`.
- A user loader that matches the identifier loosely (wildcards, case), so one account can log in as another.
- `Ldap::bind()` reachable with an empty password: most directories treat it as an anonymous bind, which succeeds.

## Voters and controllers

- A voter whose `voteOnAttribute()` ends with `return true`, or grants on a branch it never checked; one that reads `getRoles()` where the resource needs an ownership check; an ownership check that compares ids with `==` or never checks that the user is logged in.
- `#[MapEntity]`, a route `{id}` or `#[MapRequestPayload]` that loads an object with no ownership check after it.
- `getHost()`, `getHttpHost()` or `getSchemeAndHttpHost()` in a link sent to someone else, or in a cache key.

## Forms, serializer and entities

- `csrf_protection: false` on a form that changes state, unless the endpoint is a stateless API with its own authentication.
- `allow_extra_fields: true`, or `submit($request->request->all())` on a form bound to an entity: unmapped keys reach the setters.
- An `EntityType` whose `query_builder` is not scoped to the user: any row can be picked by its id.
- `#[Groups]` that puts `roles`, `isAdmin`, a password or a token in a write group, or a password hash or a token in a read group.
- A `#[MapRequestPayload]` or `#[MapQueryString]` class that is the entity itself, or a DTO with a privileged field.
- A denormalizer with `allow_extra_attributes`, or whose `supportsDenormalization()` accepts any object.
- A Doctrine custom type or lifecycle callback that unserializes, runs a process or calls a URL.

## Doctrine

- DQL or SQL built with concatenation or `sprintf()`. `setParameter()` covers values only: `ORDER BY`, `LIMIT`, column and table names taken from input need an allow-list.
- `executeQuery()`, `executeStatement()` or a native query with an interpolated value.
- A repository method fed with criteria from the request (`findBy($request->query->all())`).

## Templates

- `|raw` or `{% autoescape false %}` on data a user controls, including the props of a Twig component.
- A value inside `<script>` or an `on*` attribute without `|e('js')`; an `href` or `src` built from input without a scheme check.
- `include()` or `createTemplate()` with a name or a source taken from input: server-side template injection.

## File uploads

- The type checked from `getClientMimeType()`, `getClientOriginalExtension()` or the name instead of the content (`guessExtension()`, a `File` constraint with `mimeTypes`); no `maxSize`.
- The stored name built from `getClientOriginalName()` (path traversal, overwrite) or from a guessable counter, or a VichUploader mapping without a random namer.
- Files stored under `public/` where the server would run an uploaded `.php` file.
- A download route that serves a file by name or id without checking that the requester may see the record that owns it.

## Sinks to grep

Start a trace from each hit and walk back to the input.

| Sink           | Pattern                                                                                                                      |
| -------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| Input          | `$request->`, `$_GET`, `$_POST`, `$_REQUEST`, `$_COOKIE`, `#[MapRequestPayload`, `#[MapQueryString`                          |
| Deserializing  | `unserialize(`, `igbinary_unserialize(`                                                                                      |
| Shell          | `exec(`, `shell_exec(`, `system(`, `passthru(`, `proc_open(`, `popen(`, `fromShellCommandline(`, `new Process(`              |
| Code           | `eval(`, `include` or `require` with a variable, `->evaluate(`, `->createTemplate(`                                          |
| SQL            | `->createQuery(`, `->executeQuery(`, `->executeStatement(`, `->where(`, `->orderBy(` with a variable                         |
| Files          | `file_get_contents(`, `file_put_contents(`, `fopen(`, `readfile(`, `unlink(`, `->move(`, `getClientOriginalName(`            |
| XML            | `simplexml_load_string(`, `simplexml_load_file(`, `->loadXML(`                                                               |
| Outgoing HTTP  | `->request(` on an HTTP client                                                                                               |
| Redirects      | `new RedirectResponse(`, `->redirect(`                                                                                       |
| Host header    | `getHost(`, `getHttpHost(`, `getSchemeAndHttpHost(`, `ABSOLUTE_URL`                                                          |
| Weak crypto    | `md5(`, `sha1(`, `rand(`, `mt_rand(`, `uniqid(`, `==` or `===` beside a signature, hash or token                             |
| Access control | `return true;` in a voter, `->getRoles(`, `security: false`, `allow_if_all_abstain`, `csrf_protection`, `allow_extra_fields` |

## Guards that stop an attack

Drop a candidate when one of these covers its path, and name it with its file and line:

- `setParameter()` for every value a user controls in DQL or the query builder.
- The CSRF token a Symfony form has by default: only an explicit `csrf_protection: false` removes it.
- A class-level `#[IsGranted]`, a check in a parent controller, or an `access_control` rule whose path provably matches the route.
- Twig's `{{ value }}` in HTML, which is escaped automatically. Only `|raw`, `autoescape false` or the wrong context (JavaScript, a URL) leave it open.
- `|raw` on the output of `HtmlSanitizerInterface::sanitize()`, unless that sanitizer allows scripts or `on*` attributes.
- `new Process([...])` with an array of arguments: no shell runs.
- `md5()` or `sha1()` on a cache key, an ETag or a file fingerprint.
- `_profiler` and `_wdt` loaded under `when@dev` only.
- A form field with `mapped: false` and constraints: it never reaches the entity.
- A `#[MapRequestPayload]` DTO with `#[Assert\…]` constraints and no privileged field.
- `hash_equals()` against a secret from the environment.
- Symfony Mailer's `Address` and headers, which reject line breaks: `from()`, `subject()` or `addBcc()` with user input is not header injection.
- `RateLimiterFactory::create()` keyed by the user or the IP, and `LockFactory::createLock()` around the critical section.
- A `%env()%` reference or a secrets-vault entry, which is not a committed secret.
