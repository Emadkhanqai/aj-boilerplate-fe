---
description: Sync the frontend API layer to the upstream API's OpenAPI document — regenerate types, remove duplicated DTOs, and confirm versioned-endpoint usage. Does not push.
---

# /sync

Keep this app's contract in lockstep with the **upstream API's** OpenAPI document. Run this
after **any** change to that document — the wider procedure is
[`../workflows/api-change.md`](../workflows/api-change.md).

## Do this

1. Confirm the upstream API's OpenAPI document is current and reachable (or refresh the
   committed snapshot in `docs/api/` from it) so the contract change is visible in the diff.
2. Regenerate the frontend types into `libs/data-access/api-types`:
   ```bash
   npm run generate:api        # openapi-typescript against the upstream OpenAPI document
   ```
3. **Remove any hand-written type or client that the generated output now covers.** Hand-written
   HTTP clients are prohibited; a hand-copied DTO is a contract drift waiting to happen.
4. Confirm every call site uses a **versioned** endpoint (`/api/v1/...`) and unwraps the
   `ApiResponse<T>` envelope **centrally**, surfacing `traceId` on errors.
5. Prove it compiles:
   ```bash
   npx nx run-many -t typecheck lint build
   ```

## Rules

- Generated files are source-controlled but **never hand-edited** — an edit is destroyed on the
  next regeneration.
- If a breaking change forced a new API version, update the callers to the new version
  **deliberately**. Do not silently follow a moved contract.
- A type error after regeneration is the point of this exercise. Fix the call site; do not cast
  it away.

## Output

List the regenerated files, any hand-written types or clients removed as now-duplicated, and
every call site updated. **Do not push** — leave the result for review and approval.
