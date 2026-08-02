---
description: Review the current diff against architecture, standards, spec correctness, OWASP, and API contracts. Reports findings; does not push.
---

# /review

Review the working changes before proposing a push.

## Do this

1. `git diff` and `git diff --staged` to see the whole change. Review the diff, not your memory
   of what you intended to write.
2. Check it against the spec in `docs/specs/` — does it implement what was agreed, and only
   that?
3. Walk the checklist in [`../workflows/code-review.md`](../workflows/code-review.md) (the
   agent form is [`../agents/code-reviewer.md`](../agents/code-reviewer.md)).
4. Cross-check the relevant [`../standards/`](../standards/) files, specifically:
   - **Access control / OWASP** — deny by default, object ownership checked after load,
     restricted fields removed by DTO projection rather than hidden
     ([`../standards/owasp-security.md`](../standards/owasp-security.md),
     [`../standards/security.md`](../standards/security.md)).
   - **API contract** — versioned endpoint (`/api/v1/...`), the `ApiResponse<T>` envelope
     unwrapped centrally with `traceId` surfaced on error, correct handling of the status code
     per the table (including 401 session-expiry, 403 access-denied, and the 409 stale-
     `rowVersion` conflict), generated types current with the upstream OpenAPI document, no
     silent contract drift
     ([`../standards/api-response-format.md`](../standards/api-response-format.md),
     [`../standards/api-versioning.md`](../standards/api-versioning.md)).
   - **Error handling** — no internal detail leaking to the UI; every error state renders a
     plain message, not a stack trace or raw payload
     ([`../standards/error-handling.md`](../standards/error-handling.md)).
   - **Frontend** — standalone + OnPush + signals + `inject()`, PrimeNG only, typed reactive
     forms, generated API types only, no `any`, all four data states handled, axe-core clean
     ([`../standards/angular.md`](../standards/angular.md),
     [`../standards/typescript.md`](../standards/typescript.md)).
   - **Tests** — every new behaviour, error path, and authorization rule covered
     ([`../standards/testing.md`](../standards/testing.md)).

## Output

Prioritised findings, most severe first, each with `file:line` and marked **blocker** or
**nit**. Do not approve a push while any correctness, security, or architecture blocker is
open. The final Blocker/Critical/Major decision still defers to the SonarQube gate
([`quality-gate.md`](quality-gate.md)).
