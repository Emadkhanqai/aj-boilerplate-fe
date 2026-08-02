# ADR-0003: We depend on a uniform `ApiResponse<T>` envelope and a strict status-code contract

**Status:** Accepted
**Date:** 2026-08-02
**Deciders:** Boilerplate maintainers

---

## Context

Client error handling is only as good as the API's consistency. If one endpoint returns a bare
object, another returns `{ data: ... }`, a third returns `200` with `{ success: false }`, and a
fourth returns a raw exception string, then every call site in this app needs its own handling
and none of them are quite right. Correlating a user's report with a server log needs a shared
identifier that the user can actually see and read out.

There is a genuine tension here. RFC 9457 (`application/problem+json`) is the standardised way to
describe HTTP errors and is widely supported. An envelope, meanwhile, is often criticised as
re-inventing HTTP semantics inside the response body — and that criticism is fair when the
envelope *replaces* status codes.

The API this app consumes takes the useful part of both: HTTP status codes stay fully meaningful,
and a small, uniform body shape sits on top of them. The decision recorded here is this
repository's side of that arrangement — that we depend on the envelope being uniform, unwrap it
in exactly one place, and branch on `code` rather than on prose.

## Decision

We treat every response from a versioned endpoint as `ApiResponse<T>`:

```json
{
  "success": true,
  "data": { },
  "message": null,
  "errors": null,
  "code": null,
  "timestamp": "2026-08-02T00:00:00Z",
  "traceId": "00-…"
}
```

Collections arrive as `ApiResponse<PagedResponse<T>>`, where `PagedResponse<T>` carries `items`,
`total`, `page`, and `pageSize` — `total` is the count across *all* pages, so the client can
render a pager.

**Rules:**

1. **The HTTP status code is authoritative.** `success` mirrors it. The client nevertheless
   handles `200` with `success: false`, because a client that assumes the two always agree fails
   in the least debuggable way possible — `envelopeInterceptor` throws an `ApiError` on
   `success: false` whatever the status was.
2. **The status-code contract we code against:** `200` read, `201` created with a `Location`
   header, `204` delete, `400` validation, `401` unauthenticated, `403` unauthorised, `404`
   missing, `409` conflict or optimistic-concurrency failure, `410` gone, `422` domain-rule
   violation, `429` rate-limited, `500` unhandled, `503` dependency unavailable.
3. **`code` is stable, `message` is not.** `code` is `SCREAMING_SNAKE_CASE` — `VALIDATION_ERROR`,
   `UNAUTHENTICATED`, `FORBIDDEN`, `NOT_FOUND`, `CONFLICT`, `RESOURCE_GONE`, `RATE_LIMITED`,
   `INTERNAL_ERROR`, `SERVICE_UNAVAILABLE` — part of the contract, and the only thing this app
   may branch on. `message` is for humans and may be reworded or localised at any time.
4. **`traceId` is always present** and matches the correlation identifier in the API's logs and
   distributed trace. It is surfaced in the UI's error state so a user can quote it to support.
5. **The unwrap happens in exactly one place.** `envelopeInterceptor`
   (`libs/data-access/api-client/src/lib/envelope-interceptor.ts`) replaces the body with `data`
   on success and throws a typed `ApiError` (`status`, `message`, `code`, `traceId`, `body`) on
   failure. No feature service or component ever reads `.success` or `.data`. `Blob` bodies —
   file downloads — pass through untouched.
6. **`409` is a shipped feature, not an edge case.** Editable records carry a `rowVersion`; the
   client sends back the one it read, and a `409` means someone else wrote the row first.
   `apiErrorMessage()` produces one piece of copy for that case across the whole app, and
   `libs/feature-items` is the worked example. A rejected write is **never** retried silently —
   that is how one user's change erases another's.
7. **New `code` values are agreed with the API team and land in the OpenAPI document before use**,
   so they reach this app through [ADR-0002](0002-openapi-generated-frontend-types.md).

## Consequences

### Positive

- One unwrapping path in `api-client`, one error-handling path in the UI, one place to add
  cross-cutting response behaviour.
- `traceId` on every response makes support tractable: the identifier the user reads out is the
  identifier in the logs.
- Stable `code` values let the UI react meaningfully — a `CONFLICT` offers a reload, a
  `VALIDATION_ERROR` maps `errors[]` onto form controls — without parsing prose or matching on
  English.
- Adding a field to the envelope is backward compatible for this client.

### Negative

- It is not RFC 9457. Tooling and middleware that expect `problem+json` need adapting, and
  reviewers who know the RFC will (reasonably) ask why. Rule 1 is the answer: HTTP semantics stay
  intact and the envelope adds to them rather than replacing them.
- Every payload carries envelope overhead. Negligible per response, non-zero over a large list.
- The client depends on the API honouring the contract uniformly. One endpoint returning a bare
  DTO breaks the unwrap, and the failure surfaces as a confusing `null` rather than as an obvious
  contract violation — which is exactly why MSW handlers must be envelope-shaped too, or `demo`
  mode would hide the problem.
- Paged data sits one level deeper (`items` inside `data`), which the generated types make
  verbose to reference.

### Neutral

- `ApiError` becomes the single error type feature code catches from an API call, and the toast
  and banner wiring is written once against it.
- `PagedResponse<T>` fixes the paging vocabulary early, which is a constraint as much as a
  convenience.

### Follow-on work

- If a future API version emits `problem+json` for `5xx`, `envelopeInterceptor` gains one branch
  and nothing else in the app changes. That containment is the point of rule 5.

## Alternatives considered

### RFC 9457 `application/problem+json` for errors, bare payloads for success

The standards-compliant choice, and a defensible one. Rejected because success and failure then
have different shapes, so the client needs two code paths and cannot carry a `traceId`, a
correlation field, or paging metadata uniformly on success responses.

### Bare payloads with everything in headers

Cleanest bodies. Rejected: headers are awkward to reach in browser code, invisible in most logs
and API clients, and easily dropped by intermediaries.

### GraphQL-style `200` for everything with errors in the body

Rejected explicitly. It breaks caching, monitoring, load-balancer health signals, and every tool
that reasons about HTTP status codes.

### Unwrapping per call site instead of in an interceptor

Rejected. It is the same unwrap written slightly differently in a dozen services, and it makes
any future contract change a dozen edits instead of one.

### No convention — per-endpoint judgement

Rejected. This is the status quo the decision exists to prevent.

## Verification

`envelope-interceptor.spec.ts` and `api-error.spec.ts` assert the unwrap, the thrown `ApiError`,
and the `409` copy. Any feature code reading `response.data`, or branching on `message`, is a
review rejection. An MSW handler returning a bare DTO is a bug in the mock, not a relaxation of
the contract.

## References

- [`.claude/standards/api-response-format.md`](../../.claude/standards/api-response-format.md) — the client-side contract in full
- [`.claude/standards/error-handling.md`](../../.claude/standards/error-handling.md) — status/`code` to on-screen behaviour
- [docs/api/README.md](../api/README.md) — the API this app consumes
- [docs/specs/TEMPLATE.md](../specs/TEMPLATE.md) — §3 requires new `code` values up front
