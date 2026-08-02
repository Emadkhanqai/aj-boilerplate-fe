# The API this app consumes

This application is a client. It renders and edits data that lives behind an HTTP API it does not
own, and **the API's OpenAPI document is the contract** — the single source of truth for every
request shape, response shape, status code, and error code that crosses that boundary. If
something is not in the OpenAPI document, this app cannot rely on it.

See [ADR-0002](../adr/0002-openapi-generated-frontend-types.md) for why the types are generated
rather than written, and [ADR-0003](../adr/0003-apiresponse-envelope-and-status-code-contract.md)
for the envelope every response arrives in.

---

## Where the document comes from

The API team publishes it. It is generated from the API's own code, so it describes what the
service actually serialises rather than what someone remembered to write down — and it is not
editable from this repository.

`npm run generate:api` reads it from the URL configured in `package.json`, which points at a
locally running API by default:

```jsonc
// package.json
"generate:api": "openapi-typescript http://localhost:5080/swagger/v1/swagger.json -o libs/data-access/api-types/src/lib/types.ts"
```

Point that at whichever document is authoritative for your project: a running instance, a
published per-environment URL, or a file on disk. `openapi-typescript` accepts a path as happily
as a URL, so if the API is not reachable from your machine, save a copy of the **upstream**
document — for example `docs/api/openapi.json` — and point the script at that. Treat such a copy
as a snapshot of the contract this app's types were last generated against, not as something this
repository owns or may edit. A stale snapshot is worse than none, because it looks authoritative.

You are not blocked on the API to work here: `npx nx serve web --configuration=demo` runs the
whole app against the MSW handlers in `apps/web/src/mocks`, which are written to be
envelope-faithful for exactly this reason.

---

## How this app consumes it

```bash
npm run generate:api
```

That rewrites `libs/data-access/api-types/src/lib/types.ts` in full. That library is **generated
output**:

- It is committed, so builds are reproducible and contract changes show up in code review.
- It is **never hand-edited**. If the output is wrong, the fix is upstream in the API's OpenAPI
  document; a local patch is destroyed by the next regeneration.
- Nothing else in the workspace declares a type that mirrors an API contract.

`libs/data-access/api-client` is the hand-written layer on top, and it is thin by design: it makes
the HTTP call, unwraps the `ApiResponse<T>` envelope in `envelopeInterceptor`, turns a failure
into a typed `ApiError`, and returns plain typed data. It imports every type from `api-types` and
declares none of its own. It is also the **only** place in the workspace that talks HTTP.

Screen-specific view models are fine and expected. A hand-written *duplicate* of an API contract
type is not.

The [`/sync`](../../.claude/commands/sync.md) command runs the regeneration and then checks for
duplicated DTOs and for endpoints being called without a version prefix.

---

## The envelope

Every response — success or failure — arrives wrapped:

```ts
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

A paged list arrives as `ApiResponse<PagedResponse<T>>` and is unwrapped exactly like any other
response; `total` is the count across *all* pages, so a pager can be rendered from one call.

`envelopeInterceptor` (`libs/data-access/api-client/src/lib/envelope-interceptor.ts`) is the only
code that reads `.success` or `.data`:

- **`success: true`** → the body is replaced with `data`, and feature code only ever sees the
  plain DTO.
- **`success: false`** → thrown as an `ApiError` carrying `status`, `message`, `code`, `traceId`,
  and the raw `body` — whether it arrived on a 2xx or a non-2xx status.
- A `Blob` body (file download) passes through untouched. It is never a JSON envelope.

Full detail is in
[`.claude/standards/api-response-format.md`](../../.claude/standards/api-response-format.md).

---

## Status codes the UI switches on

| Status | Meaning to this app | `code` | What the UI does |
|---|---|---|---|
| `200` / `201` / `202` | Success | — | Unwrap `data` and render it |
| `204` | Success, no body (delete) | — | Treat as success; there is no `data` to read |
| `400` | Failed validation | `VALIDATION_ERROR` | Map `errors[]` onto the form controls |
| `401` | Session missing, expired, or revoked | `UNAUTHENTICATED` | `authInterceptor` attempts one silent token refresh and retries the request once; if that fails, the session-expired flow clears the session and sends the user back to sign in |
| `403` | Authenticated but not permitted | `FORBIDDEN` | Route to the access-denied page. Never retried |
| `404` | Missing, or hidden from this caller | `NOT_FOUND` | Render the not-found state |
| `409` | **Stale `rowVersion`** or another state conflict | `CONFLICT` | "Someone else changed this" — offer a reload. **Never** silently re-send the write |
| `410` | Permanently withdrawn | `RESOURCE_GONE` | A "no longer available" state, distinct from 404 |
| `422` | Understood but rejected by a domain rule | `VALIDATION_ERROR` or a domain code | As 400 — map to the field or to a banner |
| `429` | Rate limited | `RATE_LIMITED` | Back off; "try again shortly" |
| `500` | Unexpected server fault | `INTERNAL_ERROR` | Generic error toast with the `traceId`. Never retried automatically |
| `503` | Dependency down or maintenance | `SERVICE_UNAVAILABLE` | Generic message; TanStack Query's retry policy backs off |

`409` deserves its own paragraph because it is a shipped feature rather than a theoretical case.
Every editable record carries a `rowVersion`. Read it with the record, send it back on update,
and when the API answers `409` it means someone else wrote the row after you loaded it. The only
correct recovery is to tell the user plainly and let them look at the current values;
`apiErrorMessage()` in `libs/data-access/api-client` produces that copy once for the whole app,
and `libs/feature-items` is the worked example. A silent retry is how one user's change erases
another's.

---

## Error handling on the client

Branch on `code`. Never on `message`.

```ts
// code is stable and part of the contract; message is prose and may be reworded or localised.
if (error.code === 'CONFLICT') { /* offer to reload */ }
```

Every error state in the UI surfaces the response's `traceId`, because that is the value a user
can read out to support and support can find in the logs.

---

## Versioning and breaking changes

Every call goes to a versioned route: `/api/v1/items`. Calling an unversioned path is a defect —
`/sync` checks for it.

A change is **breaking** if it removes or renames a field, narrows a type, makes an optional field
required, changes a status code, changes an existing `code` value, or removes an enum member.
A change is **additive** — and safe within a version — if it adds an optional field, adds a new
endpoint, adds a new `code` value, or adds an enum member this app can treat as unknown.

Additive changes reach this app the next time someone regenerates. Breaking changes do not
silently arrive: they break the build here, which is the point of
[ADR-0002](../adr/0002-openapi-generated-frontend-types.md).

---

## When the contract changes

The contract moves upstream first, always in this order:

1. **Agree it.** Endpoints, DTOs, status codes, and error codes are settled with the API team and
   recorded in [the spec](../specs/TEMPLATE.md) §3, before any code here. New `code` values are
   declared there.
2. **It lands in the API** and appears in the published OpenAPI document.
3. **Regenerate.** `npm run generate:api`, or [`/sync`](../../.claude/commands/sync.md), which
   also checks for duplicated DTOs and unversioned calls.
4. **Consume it.** Update `api-client` and the feature code against the new types. A type error
   after regeneration is the tool working; fix the call site rather than casting it away.
5. **Update the mocks.** The MSW handlers in `apps/web/src/mocks` must match the new shape, or
   `demo` mode and the Playwright journeys quietly test a contract that no longer exists.
6. **Review.** The generated diff is part of the pull request and is read, not skimmed.

Never run this backwards. Writing the client type first and asking the API to match it is how a
contract stops describing the system. The full procedure, including who to tell, is
[`.claude/workflows/api-change.md`](../../.claude/workflows/api-change.md).

---

## Related

[ADR-0002](../adr/0002-openapi-generated-frontend-types.md) ·
[ADR-0003](../adr/0003-apiresponse-envelope-and-status-code-contract.md) ·
[`.claude/standards/api-response-format.md`](../../.claude/standards/api-response-format.md) ·
[`.claude/standards/api-versioning.md`](../../.claude/standards/api-versioning.md) ·
[`.claude/standards/error-handling.md`](../../.claude/standards/error-handling.md)
