# Standard: API Response Format (client contract)

The API wraps every response — success or failure — in a shared envelope. This document
describes that contract **from the client's side**: the shape the app receives, and how it is
unwrapped so feature code never touches the envelope directly. How the server produces it is
the backend's concern, not this repository's.

## The envelope, as the client sees it

```ts
// libs/data-access/api-types/src/lib/types.ts (generated — never hand-edited)

export interface ApiResponse<T> {
  success: boolean;
  data?: T | null;
  message: string | null;
  errors: string[] | null;
  /** Stable, machine-readable error code. Never repurposed once published. */
  code: string | null;
  timestamp: string;
  /** Correlation id for this request. Surface it in support-facing error detail. */
  traceId: string | null;
}

export interface PagedResponse<T> {
  items: T[];
  total: number;
  page: number;
  pageSize: number;
}
```

`PagedResponse<T>` arrives as the `data` of an `ApiResponse<PagedResponse<T>>` — a paged list
endpoint is unwrapped exactly like any other endpoint.

## Unwrapping — one place, never per-caller

`envelopeInterceptor` (`libs/data-access/api-client/src/lib/envelope-interceptor.ts`) is the
**only** place that reads `.success` / `.data`. It runs on every HTTP response:

- **`success: true`** → the response body is replaced with `data`; every feature service and
  component only ever sees the plain DTO.
- **`success: false`** → thrown as an `ApiError` (`status`, `message`, `code`, `traceId`,
  `body`), whether the envelope arrived on a 2xx or a non-2xx HTTP status — the API can report a
  logical failure with `200 OK`, and the client must not assume `success` follows the HTTP
  status.
- A `Blob` response body (file downloads, `responseType: 'blob'`) is passed through unchanged —
  it is never a JSON envelope.

**No feature code reads `response.data` itself, and no feature code re-implements this unwrap.**
If a new HTTP call bypasses `data-access/api-client`, it bypasses this contract too — which is
exactly why hand-written HTTP clients are prohibited (see [`angular.md`](angular.md)).

## Rules

- **Every response the client receives from a versioned endpoint (`/api/v1/...`) is assumed to
  be `ApiResponse<T>`-shaped.** A handler, mock, or contract test that returns a bare DTO is
  wrong — it would break the app in a way the real API never would (see
  [`testing.md`](testing.md) on MSW handlers).
- **`code` is the value to switch on, never `message`.** `message` is prose for a toast or an
  error banner; it is not stable across releases or locales and must never drive branching
  logic.
- **`traceId` is surfaced in user-facing error detail** wherever the failure isn't obviously
  actionable by the user, so a support conversation can correlate the request (see
  [`observability-tracing.md`](observability-tracing.md)).
- **Never invent a bespoke error shape client-side.** `ApiError` is the one error type feature
  code catches from an API call.

## HTTP status codes the client switches on

| Status | Meaning to the client | Envelope `code` (example) | Client handling |
|---|---|---|---|
| **200 / 201 / 202** | Success | — | Unwrap `data`, render it |
| **204 No Content** | Success, no body (e.g. delete) | — | Treat as success; no `data` to read |
| **400 Bad Request** | Failed validation | `VALIDATION_ERROR` | Map `errors[]` onto form controls |
| **401 Unauthorized** | Session is invalid — missing, expired, or revoked | `UNAUTHENTICATED` | `authInterceptor` attempts one silent refresh; if that fails, session-expired flow (see [`error-handling.md`](error-handling.md#401-session-expiry)) |
| **403 Forbidden** | Authenticated, not permitted | `FORBIDDEN` | Route to the access-denied page; never retried |
| **404 Not Found** | Resource does not exist, or is hidden from this caller | `NOT_FOUND` | Render a not-found state |
| **409 Conflict** | Optimistic-concurrency mismatch (stale `rowVersion`), or another state conflict | `CONFLICT` | Show the reload-and-retry banner — never silently overwrite (see [`error-handling.md`](error-handling.md#409-conflict-optimistic-concurrency)) |
| **410 Gone** | Resource permanently withdrawn | `RESOURCE_GONE` | Render a "no longer available" state, distinct from 404 |
| **422 Unprocessable Entity** | Semantically invalid request the API understood but rejected | `VALIDATION_ERROR` (or a domain-specific code) | Same as 400 — map to the relevant field/banner |
| **429 Too Many Requests** | Rate limited | `RATE_LIMITED` | Back off; surface a "try again shortly" message |
| **500 Internal Server Error** | Unexpected server fault | `INTERNAL_ERROR` | Generic error toast with `traceId`; never retried automatically |
| **503 Service Unavailable** | Dependency down / maintenance | `SERVICE_UNAVAILABLE` | Generic message; TanStack Query's default retry policy backs off (see [`angular.md`](angular.md#state--signals-first)) |

The full mapping from status/`code` to on-screen behaviour — including the four view states and
the toast wiring — lives in [`error-handling.md`](error-handling.md).

## Related

[`error-handling.md`](error-handling.md) · [`observability-tracing.md`](observability-tracing.md) ·
[`api-versioning.md`](api-versioning.md) · [`angular.md`](angular.md)
