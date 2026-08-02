# Standard: Security (frontend baseline)

The frontend security baseline every project built on this boilerplate inherits. **Access
control is enforced by the API, on every request, independently of anything the client does or
shows.** This document covers what the client itself is responsible for: how it holds tokens,
what it never ships, and how it avoids becoming the attack surface.

## Authentication (client side)

- **OIDC Authorization Code + PKCE**, implemented in
  `libs/auth/src/lib/providers/oidc-provider.ts` against any OIDC-compliant authority — no OIDC
  client library is a dependency; the flow is native `fetch` + `crypto.subtle` against the
  authority's discovery document.
- **The identity provider authenticates only.** Authorization (roles/capabilities) is resolved
  server-side (`GET /api/v1/me`) so the browser never decides what the signed-in user may do —
  see `libs/auth/README.md` and [`owasp-security.md`](owasp-security.md).
- **Tokens are held by the `auth` lib**, attached by `authInterceptor`
  (`libs/data-access/api-client/src/lib/auth-interceptor.ts`). No component reads a token
  directly.
- **A 401 on a token-bearing request triggers exactly one silent refresh attempt, then session
  expiry — never a silent retry loop.** Concurrent 401s share a single in-flight refresh
  (`refreshInFlight` in `oidc-provider.ts`) so a burst of requests never replays the same
  refresh token multiple times, which some providers treat as a reuse/replay and revoke the
  whole session for.
- **`state`/`nonce` are checked on the OIDC callback** to close CSRF and replay vectors on the
  authorization-code exchange; a mismatch aborts sign-in rather than proceeding.
- **Post-login redirect targets are validated same-origin** before use
  (`libs/auth/src/lib/sanitize-return-path.ts`) — see
  [`input-validation-sanitization.md`](input-validation-sanitization.md#urls-from-untrusted-input).
- **Dev-mode auth** (a role picker with no real identity provider) is explicitly a
  non-production path, gated by `window.__APP_AUTH_MODE__`, and must never be reachable in a
  build that talks to a real API.

## Authorization — UX only, never enforcement

- **Roles are enforced server-side, every time.** `libs/auth/src/lib/roles.ts` and
  `capabilityGuard` exist to make the UI pleasant for a legitimate user, not to keep out an
  illegitimate one — see [`owasp-security.md`](owasp-security.md).
- **A disallowed action is only ever hidden or disabled — never trusted to be unreachable.**
  The API rejects it independently if it is reached anyway (typed URL, replayed request,
  tampered client state).

## Secrets & configuration

- **No secrets in the repo, ever.** `apps/web/src/environments/*` hold build-time placeholders
  (base URLs, feature flags) — never a real client secret, API key, or credential; there is no
  such thing as a frontend secret that stays secret, since anything shipped to the browser is
  visible to the browser.
- **Real per-environment values arrive at container start, not at build time.**
  `apps/web/public/env.js` is rewritten by `docker/40-env.sh` from environment variables when
  the container starts, and is served with `Cache-Control: no-cache` (`nginx.conf`) so a stale
  cached copy never serves a previous deployment's config. `docker/40-env.sh` also strips
  quote/backslash/newline characters from every value before interpolating it into the
  generated script — an env var is untrusted input to a script that runs before the app
  bootstraps, and must not be able to break out of its string literal.
- **The `secret-scan` hook is blocking.** A committed secret is treated as compromised: rotate
  it first, then remove it from history.
- Encrypt in transit everywhere — HTTPS only, no mixed content.

## API & transport (client side)

- **HTTPS only.** No API call to a plaintext origin.
- **Errors never leak stack traces or internal detail to the console in a way a user could
  screenshot and share** — see [`error-handling.md`](error-handling.md) and
  [`observability-tracing.md`](observability-tracing.md).
- **Content Security Policy and standard security headers** are set at the serving layer
  (`nginx.conf` / the platform serving the built app) — no inline `<script>`, no
  `unsafe-eval`, and no relaxing CSP to make a library work without a documented reason.
- The app calls the API same-origin via a reverse proxy (`nginx.conf` proxies `/api/` to the
  backend) rather than cross-origin, which avoids most CORS/credential-leak footguns by
  construction — see [`api-versioning.md`](api-versioning.md).

## Supply chain

- Pin dependencies; review transitive additions before they land in `package-lock.json`.
- **`npm audit` runs in CI and blocks on high severity.**
- No unvetted package enters the build because an agent or a quick fix suggested it.

## Quality gate

Security hotspots and vulnerabilities reported by SonarQube at Blocker/Critical/Major severity
**block the push** (see [`sonarqube.md`](sonarqube.md)).

## Related

[`owasp-security.md`](owasp-security.md) · [`input-validation-sanitization.md`](input-validation-sanitization.md) ·
[`error-handling.md`](error-handling.md) · [`sonarqube.md`](sonarqube.md)
