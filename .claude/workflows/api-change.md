# Workflow: API Change

> **Model routing (do first):** see [`../model-routing.md`](../model-routing.md). Reacting to a
> routine additive change → workhorse tier; absorbing a breaking contract change → frontier
> tier.

The **upstream API's** OpenAPI document changed. This workflow is how this frontend-only repo
absorbs that change safely, rather than drifting from the contract it depends on.

## 1. Classify the change

- **Additive / backward-compatible** (new endpoint, new *optional* field, new enum member) →
  regenerate and consume; no version bump needed on this side.
- **Breaking** (a field removed or renamed, a type narrowed, an optional field made required, a
  status-code meaning changed, a `code` value changed) → this app must move its callers to the
  new API version deliberately. Record the decision as an ADR in `docs/adr/` — never follow a
  moved contract silently
  ([`../standards/api-versioning.md`](../standards/api-versioning.md)).

## 2. Regenerate the contract

Run [`/sync`](../commands/sync.md):

```bash
npm run generate:api        # openapi-typescript against the upstream OpenAPI document
```

Refresh the committed OpenAPI snapshot in `docs/api/` so the contract change is visible in the
diff.

## 3. Fix the fallout

- **Remove any hand-written type or client that the generated output now covers.**
  Hand-written HTTP clients and hand-copied DTOs are prohibited; they are contract drift
  waiting to happen.
- A type error after regeneration is the point of the exercise — fix the call site in
  `libs/data-access/api-client` and the feature code, never cast it away.
- Confirm every call site still uses a **versioned** endpoint (`/api/v1/...`) and unwraps the
  **`ApiResponse<T>`** envelope centrally
  ([`../standards/api-response-format.md`](../standards/api-response-format.md)) — including
  handling for 401 (session expiry), 403 (access-denied), 404, and the **409 stale-`rowVersion`
  conflict** wherever the changed shape carries one.

## 4. Test

Update the affected unit and component tests for the new shape, and add a case for any new
error `code` the endpoint can now return. Add or update the Playwright journey if the change
affects a route's behaviour.

## 5. Review & gate

[`/review`](../commands/review.md), then
[`pre-push-quality-gate.md`](pre-push-quality-gate.md). Confirm there is no leftover
hand-written duplicate of the regenerated types. **No push without approval.**
