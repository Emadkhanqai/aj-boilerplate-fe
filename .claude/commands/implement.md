---
description: Implement one task from an approved plan, following the standards and TDD. Builds and tests; never pushes.
---

# /implement `<task>`

Implement a scoped piece of work — one task from [`/task`](task.md), or one clearly bounded
change.

## Before writing code

1. **Read the spec** in `docs/specs/` for this feature, and the ADRs in `docs/adr/` that
   constrain it. If the spec is silent on a behaviour you need, **ask** — do not invent a
   business rule.
2. Read the applicable files in [`../standards/`](../standards/), and the workflow that matches
   the change: [`new-feature.md`](../workflows/new-feature.md) or
   [`api-change.md`](../workflows/api-change.md).
3. If there is a task list, follow it **one task at a time**. Do not start task 3 because task
   2 "was easy".

## While implementing

- **Work on a branch, never `main`.** TDD where it fits: failing test → minimal code → green →
  refactor → commit.
- Respect the Nx module boundaries: `feature-*` → `data-access` / `shared` / `auth`;
  `shared/util` imports nothing; no feature imports another feature.
- **Standalone components, OnPush, signals, `inject()`, typed reactive forms, PrimeNG only,
  generated API types only.** Read `../DESIGN.md` before building UI.
- **All HTTP through `libs/data-access/api-client`**, unwrapping the `ApiResponse<T>` envelope
  centrally; a **409** stale-`rowVersion` response is surfaced as a plain conflict message, not
  retried silently.
- Start from the template rather than from scratch:
  [`angular-component.md`](../templates/angular-component.md).
- Keep the diff to the task. An unrelated "while I was in here" fix belongs in its own commit.

## Finish

- `npx nx run-many -t lint test build && npm run typecheck`.
- If the upstream API surface changed: run [`/sync`](sync.md) to regenerate types.
- Run [`/qa`](qa.md), then [`/review`](review.md).
- **Do not push.** Summarise what you did, what you verified (with the actual command output),
  and what is still open. Then wait for explicit approval.
