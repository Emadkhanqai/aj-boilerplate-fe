# Standard: Observability & Tracing (frontend)

The frontend's job in observability is small and specific: carry correlation ids through, put
`traceId` in front of the user when it helps, and never leak sensitive data into the browser
console. Server-side tracing, spans, and the audit log are the API's concern, not this
repository's.

## Correlation

- **Every `ApiError` carries the `traceId`** the API returned with the failing response (see
  [`api-response-format.md`](api-response-format.md)). Surface it in error UI that a user might
  need to quote to support — e.g. "Something went wrong. Reference: `<traceId>`" — rather than
  making them dig through devtools for it.
- **Propagate W3C Trace Context (`traceparent`) on outbound calls** where the API expects it.
  If a project's backend correlates via that header, it is attached in the same interceptor
  chain that attaches the bearer token (`authInterceptor` /
  `libs/data-access/api-client/src/lib/auth-interceptor.ts`), not scattered per call site.
- A correlation id belongs to a single user-initiated action end to end: one `traceId` per
  request/response pair, read once and either displayed or discarded — never generated
  client-side to replace what the server returned.

## What never reaches the console or a client-side log

- **Never `console.log` a bearer token, an `Authorization` header, a refresh token, or a raw
  session object.** `libs/data-access/api-client` and `libs/auth` both hold tokens; neither
  logs them, including in error paths — an error handler that dumps the failed request for
  debugging must strip the `Authorization` header first.
- **Never log full PII** (email, name, free-text business content) to the console in
  production code. A `console.error` left in from development is a real information leak once
  it ships — treat one found in review as a defect, not a nit.
- Prefer structured, minimal error logging (`console.error('items:save failed', { status,
  code, traceId })`) over dumping the whole error object or response body.

## Golden signals, from the front end

Where the project has an application-performance/RUM tool wired in, the metrics that matter
from the browser side:

- **Error rate** — API failures surfaced per route/feature (drives the toast/inline-error
  volume described in [`error-handling.md`](error-handling.md)).
- **Latency** — perceived load time per route; the loading state in
  [`error-handling.md`](error-handling.md#the-four-view-states) exists precisely so a slow
  request doesn't read as a frozen page.
- **Core Web Vitals** (LCP, INP, CLS) as the user-facing proxy for "does this feel fast."

None of this requires a specific vendor — the point is that these signals are visible
somewhere, not that a particular tool is mandatory.

## Related

[`error-handling.md`](error-handling.md) · [`api-response-format.md`](api-response-format.md) ·
[`security.md`](security.md)
