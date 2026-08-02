# Standard: Error Handling (frontend)

Every API failure is caught in one place, turned into one error type, and always leaves the
user looking at a screen that explains what happened — never a blank panel or an infinite
spinner.

## The pipeline

1. **`envelopeInterceptor`** (`libs/data-access/api-client/src/lib/envelope-interceptor.ts`)
   turns any `success: false` envelope — or any non-2xx response — into a thrown `ApiError`.
   See [`api-response-format.md`](api-response-format.md).
2. **`authInterceptor`** runs *before* the envelope interceptor in the provider order
   (`apps/web/src/app/app.config.ts`) and owns the 401 recovery flow (below).
3. **TanStack Query** (`injectQuery` / `injectMutation`) is where every feature actually
   observes success/error/loading — see [`angular.md`](angular.md).
4. **`QUERY_CLIENT`**'s `QueryCache` / `MutationCache` `onError` hooks
   (`libs/shared/ui/src/lib/query-error-toasts/query-error-toasts.ts`) are the app-wide safety
   net: any error not already handled locally becomes a toast, so nothing fails silently.

## `ApiError`

```ts
// libs/data-access/api-client/src/lib/api-error.ts
export class ApiError extends Error {
  constructor(
    public readonly status: number,
    message: string,
    public readonly body: unknown,
    public readonly code?: string | null,
    public readonly traceId?: string | null,
  ) { /* ... */ }
}
```

- `isConflictError(err)` — true for a 409 `ApiError` (stale `rowVersion`).
- `conflictData<T>(err)` — extracts a typed conflict payload when the API returns one.
- `apiErrorMessage(err, fallback)` — the one place that turns an error into user-facing copy:
  a 409 always gets the same actionable "someone else changed this record" text regardless of
  `fallback`; any other `ApiError` appends its status to `fallback`; anything else returns
  `fallback` as-is.

**Every `catch` of an API call in feature code either uses these helpers or has a specific,
reviewed reason not to.** Re-deriving error copy per component is how the app ends up with five
different phrasings of the same failure.

## The four view states

Every screen that reads from the API renders all four, explicitly:

| State | When | What the user sees |
|---|---|---|
| **Loading** | Query is in flight, no cached data yet | A skeleton or spinner — never a blank panel |
| **Empty** | Query succeeded, `data` has zero items | A deliberate empty state with a next action, not a bare "no results" |
| **Error** | Query failed | An inline `role="alert"` message via `apiErrorMessage()`, or a retry action where retrying is meaningful |
| **Success** | Query succeeded with data | The real content |

An unhandled empty state, or a component that only renders success and lets everything else
fall through to nothing, is an incomplete feature — not a follow-up.

## Toasts vs inline errors

- A query/mutation with **no local error UI** gets the global toast automatically
  (`reportQueryError`) — that is the safety net, not the primary UX.
- A query/mutation that **does** render its own inline error (a form's error banner, a page's
  "could not load" block) tags its `meta` with `GLOBAL_ERROR_TOAST_SUPPRESSED` so the user does
  not see the same failure reported twice.
- Never suppress the toast without providing an equivalent local error state — silence is not a
  substitute for either.

## 401 session expiry

`authInterceptor` (`libs/data-access/api-client/src/lib/auth-interceptor.ts`) treats a 401 **on
a request that carried a bearer token** as "the session is no longer valid server-side," not
as an ordinary failure:

1. Attempt exactly one token refresh via `TOKEN_REFRESHER`.
2. If refresh succeeds, retry the original request once with the new token.
3. If there is no refresher, refresh fails, or the retried request still 401s, fire
   `SESSION_EXPIRED_NOTIFIER` (clears the session, drives the "please sign in again" UX) and
   propagate the error.

A 401 on a request that carried **no** token (an anonymous endpoint) is an ordinary failure and
is *not* treated as session expiry. `isSessionExpiredError(err)` lets the global toast handler
skip a redundant notification for an error already surfaced this way.

## 403 access denied

A 403 routes the user to a visible access-denied page/state
(`apps/web/src/app/pages/access-denied-page`) rather than a silent redirect or a blank screen —
the user should learn the page exists and that their role is why they cannot see it. This is
UX only: the API is the real enforcement point (see [`owasp-security.md`](owasp-security.md)).

## 409 conflict (optimistic concurrency)

A 409 on a write means the `rowVersion` sent no longer matches the server's — someone else
changed the record first. The **only** correct client behaviour:

- Flag the conflict distinctly from a validation failure (`isConflictError`).
- Offer to reload the current server state, discarding the local edit.
- **Never** retry the write with the same stale `rowVersion`, and never silently merge.

`libs/feature-items/src/lib/item-form-page/item-form-page.ts` is the reference implementation:
`conflict` signal set on 409, `reloadFromServer()` as the only recovery path.

## Status/`code` quick reference

| Status | `code` | Client behaviour |
|---|---|---|
| 400 | `VALIDATION_ERROR` | Map `errors[]` onto form controls |
| 401 | `UNAUTHENTICATED` | Silent refresh, else session-expired flow |
| 403 | `FORBIDDEN` | Access-denied page |
| 404 | `NOT_FOUND` | Not-found state |
| 409 | `CONFLICT` | Reload-and-retry banner, never silent overwrite |
| 410 | `RESOURCE_GONE` | "No longer available" state, distinct from 404 |
| 422 | `VALIDATION_ERROR` (or domain-specific) | Same as 400 |
| 429 | `RATE_LIMITED` | Back off, "try again shortly" |
| 500 | `INTERNAL_ERROR` | Generic toast with `traceId` |
| 503 | `SERVICE_UNAVAILABLE` | Generic message; let the retry policy back off |

The full status/`code` table and how the server produces each one is
[`api-response-format.md`](api-response-format.md#http-status-codes-the-client-switches-on).

## Rules

- No `catch` that swallows an error silently — at minimum it reaches the global toast.
- Never branch on `err.message` — branch on `err.code` or `err.status` (`ApiError`).
- Never log a token, an `Authorization` header, or full PII to the browser console — see
  [`observability-tracing.md`](observability-tracing.md).
- A cancelled request (navigating away mid-fetch) is not an error state — do not render an
  error banner for it.

## Related

[`api-response-format.md`](api-response-format.md) · [`observability-tracing.md`](observability-tracing.md) ·
[`security.md`](security.md) · [`angular.md`](angular.md)
