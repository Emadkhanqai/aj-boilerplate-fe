# Standard: OWASP Security (frontend)

Align to the **OWASP Top 10 (2025)** and the **OWASP API Security Top 10 (2023)** for the parts
a frontend can actually act on. **Broken Access Control is the highest risk for the system
overall — and it is enforced server-side, every time.** The frontend's contribution is to never
undermine that with a false sense of client-side security.

## Highest risk — Broken Access Control / BOLA / IDOR

- **The API enforces every permission on every request. The frontend never relies on its own
  role check as a security boundary.** `libs/auth/src/lib/roles.ts` states this in its own
  header comment: role → capability mapping is "a UX convenience only... hiding a nav item here
  does not protect the underlying API, and a user who types the URL directly still gets a 403
  from the server."
- **Role-aware UI hides doors the user cannot open; it does not lock them.** Hiding a button,
  disabling a nav link, or route-guarding with `capabilityGuard` all improve the experience for
  a legitimate user — none of them are a substitute for the API's own authorization check, and
  none of them should be described as one in a PR or a design doc.
- **Never render a field the current user is not entitled to see "but just styled away" (e.g.
  `display: none`, greyed out).** If the API sent it, a user with devtools sees it. The correct
  fix is a different response shape for that permission level — the API's job (see
  [`security.md`](security.md)) — not client-side hiding.

## Mapped controls — what the frontend actually does

| OWASP Top 10 (2025) risk | Frontend's role |
|---|---|
| Broken Access Control | UX-only role gating (`capabilityGuard`, `roles.ts`); real enforcement is server-side |
| Security Misconfiguration | No secrets/real config baked into the bundle (see [`security.md`](security.md)); CSP/headers where the app is served |
| Software Supply Chain Failures | `npm audit`, pinned versions in `package-lock.json`, no unvetted package added because an agent suggested it |
| Cryptographic Failures | HTTPS-only calls; tokens held in memory/short-lived storage, never logged (see [`observability-tracing.md`](observability-tracing.md)) |
| Injection (XSS) | Angular's default escaping; `[innerHTML]`/`bypassSecurityTrust*` gated behind review (see [`input-validation-sanitization.md`](input-validation-sanitization.md)) |
| Insecure Design | Threat-model any client-side redirect, deep link, or exported data view during design |
| Authentication Failures | OIDC Authorization Code + PKCE only, no locally-implemented password flow (see [`security.md`](security.md)) |
| Software/Data Integrity Failures | Generated API types only (`libs/data-access/api-types`), never hand-copied DTOs — see [`angular.md`](angular.md) |
| Security Logging & Alerting Failures | *(enforced by the API — the frontend has no server-side audit log to fail)* |
| Mishandling Exceptional Conditions | Central interceptor + `ApiError`, four view states, no unhandled promise dead-ends (see [`error-handling.md`](error-handling.md)) |

## Mapped controls — OWASP API Security Top 10 (2023)

| # | Risk | Frontend's role |
|---|---|---|
| 1 | BOLA | *Enforced by the API.* The client never assumes an id it can construct is one it is entitled to read. |
| 2 | Broken authentication | OIDC Authorization Code + PKCE (`libs/auth/src/lib/providers/oidc-provider.ts`); no locally stored password; single-flight refresh to avoid a reused-refresh-token revocation storm |
| 3 | Broken object property level auth | *Enforced by the API via per-permission DTOs.* The client renders whatever fields the response contains and hides nothing that arrived — because a hidden-but-present field is not actually protected. |
| 4 | Unrestricted resource consumption | Client-side pagination and a sane default page size on every list view; the client never requests unbounded result sets |
| 5 | Broken function level auth | *Enforced by the API.* `capabilityGuard` on state-changing routes is UX, not the boundary. |
| 6 | Unrestricted access to sensitive business flows | One-time action buttons disabled during the in-flight mutation (no double-submit) |
| 7 | SSRF | N/A from the browser directly — outbound URL validation is a server concern |
| 8 | Security misconfiguration | No secrets or environment-specific real values committed; runtime config only (see [`security.md`](security.md)) |
| 9 | Improper inventory management | Client calls versioned endpoints only (see [`api-versioning.md`](api-versioning.md)) |
| 10 | Unsafe consumption of APIs | Every API response is validated by the generated type + the envelope contract before use; an unexpected shape fails loudly rather than being trusted |

## Operational rules

- **Never implement an authorization decision purely in the frontend** and call it done. If a
  feature needs a new restriction, the API change is the fix; the frontend change (hiding a
  button, guarding a route) is the UX complement.
- **Sanitize before rendering, per
  [`input-validation-sanitization.md`](input-validation-sanitization.md).**
- **No secrets in the repo.** Runtime configuration only — see
  [`security.md`](security.md#secrets--configuration).
- **`npm audit` clean at high severity** before a push is proposed (see
  [`sonarqube.md`](sonarqube.md) and [`git-approval-policy.md`](git-approval-policy.md)).
- **Review this list during code review** ([`../commands/review.md`](../commands/review.md))
  and fix every SonarQube Blocker/Critical/Major before push
  ([`sonarqube.md`](sonarqube.md)).

## Related

[`security.md`](security.md) · [`input-validation-sanitization.md`](input-validation-sanitization.md) ·
[`error-handling.md`](error-handling.md) · [`angular.md`](angular.md)
