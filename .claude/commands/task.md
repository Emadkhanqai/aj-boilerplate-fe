---
description: Decompose an approved spec into small, independently-mergeable tasks in dependency order.
---

# /task `<path-to-approved-spec>`

Turn an **approved** spec into a task list that can actually be executed and reviewed. Refuse
to run against a spec that has not been approved — say so and point at [`/spec`](spec.md).

## The two rules

1. **Each task is at most half a day of work.** If it is bigger, it is not a task, it is a
   milestone — split it. Oversized tasks produce oversized diffs, and oversized diffs are not
   reviewed, they are skimmed.
2. **Each task is independently mergeable.** It builds, its tests pass, and merging it alone
   leaves `main` working. A task that only makes sense alongside the next one is really one
   task.

## Ordering

Emit tasks in this dependency order — it is the order that keeps the tree green at every step:

1. **Contract** — confirm the upstream API's OpenAPI document already covers what the feature
   needs; if it does not, that is a blocking dependency on the API team, not a task here.
2. **Data-access** — regenerate types (`/sync`), then the typed service in
   `libs/data-access/api-client`.
3. **Shared building blocks** — anything that belongs in `shared/ui` or `shared/util` because
   more than one feature needs it.
4. **UI** — components, states (loading/error/empty/success), forms, accessibility.
5. **E2E** — the Playwright journeys that prove the whole path.

Anything that cannot be placed in that order is a signal the spec is incomplete — say so
rather than inventing a position for it.

## For each task, write

- **Title** — imperative, specific (`Add Item concurrency token and 409 mapping`).
- **Scope** — the files and layers it touches.
- **Depends on** — the task numbers that must land first.
- **Acceptance criteria** — testable statements lifted from the spec.
- **Verification command** — the exact command that proves it (e.g. `npx nx test
  feature-items`, `npx nx e2e web-e2e --grep "..."`).
- **Estimated size** — must be ≤ half a day.

## Output

The ordered task list, the dependency graph (which tasks can run in parallel), and an explicit
call-out of any task you could not size under half a day and why.

Then stop. Execute with [`/implement`](implement.md), one task at a time.
