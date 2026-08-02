# Workflow: New Feature

> **Model routing (do first):** classify the task and recommend a model — see
> [`../model-routing.md`](../model-routing.md). New-capability *design* → frontier tier; the
> *build and tests* that follow → workhorse tier. Say so if the current model is mismatched.

End-to-end flow for a new capability in this Angular + Nx + PrimeNG application.

## 1. Understand & plan

- **Read the spec** in `docs/specs/`. If there is no approved spec, run
  [`/spec`](../commands/spec.md) first — building without one is how scope drifts.
- Read the ADRs in `docs/adr/` that constrain the area, and the applicable
  [`../standards/`](../standards/).
- Confirm the **upstream API** already exposes what the feature needs (check the OpenAPI
  document / `docs/api/`). If it does not, that is a blocking dependency on the API, not
  something to work around client-side.
- List the **invariants** the feature must hold. Each one becomes a test.
- Break the work down with [`/task`](../commands/task.md) if it is more than half a day.

## 2. Branch

`git switch -c feature/<short-desc>`. Never work on `main` directly.

## 3. Sync the contract

If the OpenAPI document changed or has not yet been generated against, run
[`/sync`](../commands/sync.md) to regenerate `libs/data-access/api-types` before writing the
feature. See [`api-change.md`](api-change.md).

## 4. Build the feature

1. **Read `../DESIGN.md` before writing any component.**
2. Feature library under `libs/feature-<name>`; all HTTP through `libs/data-access/api-client`
   using **generated** types; **versioned** endpoints only (`/api/v1/...`).
3. Standalone components, `OnPush`, signals, `inject()`, **typed reactive forms**, PrimeNG
   only. Handle **loading / error / empty / success**; surface `traceId` on errors, and treat a
   **409** stale-`rowVersion` response as a plain conflict message, never a silent retry.
4. **Role-aware UI is UX, never security** — the API enforces every permission
   independently. No `innerHTML`/`bypassSecurityTrust*` with user content.
5. Vitest for logic, a Playwright journey for the new route, axe-core clean.

## 5. Verify locally

```bash
npx nx run-many -t lint test build && npm run typecheck
```

## 6. Review & gate

Run [`/qa`](../commands/qa.md), then [`/review`](../commands/review.md), then
[`pre-push-quality-gate.md`](pre-push-quality-gate.md). Fix every Blocker/Critical/Major.
**Do not push without explicit approval.**
