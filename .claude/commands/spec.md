---
description: Draft a spec from the template into docs/specs/ — the required first step before any implementation.
---

# /spec `<short-feature-name>`

Produce a written, reviewable spec **before** any code is written. Implementation without an
approved spec is how scope and correctness both drift.

## Do this

1. **Understand the request first.** Ask the questions that would change the design — the
   actor, the trigger, the data, the rules, what happens when it fails, and what is explicitly
   out of scope. Do not start drafting while a load-bearing question is unanswered.
2. Copy `docs/specs/TEMPLATE.md` to `docs/specs/<YYYY-MM-DD>-<short-feature-name>.md`.
3. Fill in every section:

   | Section | What goes in it |
   |---|---|
   | **Problem** | What is wrong or missing today, in the user's terms |
   | **Goals** | What must be true when this is done |
   | **Non-goals** | What is deliberately excluded — the most useful section |
   | **Domain model** | The entities this feature renders and edits, and the **invariants** the UI must enforce or surface |
   | **API surface** | Which upstream endpoints this feature calls, the request/response shapes it expects (from the OpenAPI document), status codes and `code` values it must handle |
   | **Authorization** | Which roles/capabilities see or act on what; which fields are restricted from whom in the UI |
   | **UI** | Screens, states (loading/error/empty/success), and the journeys |
   | **Data & concurrency** | Whether records carry `rowVersion`, how a 409 conflict is surfaced, any new query keys or cache-invalidation rules |
   | **Observability** | What is logged client-side and what `traceId` handling changes |
   | **Risks / open questions** | Named, with an owner — never left implicit |
   | **Acceptance criteria** | Testable statements; each becomes a test |

4. **Record every architectural decision as an ADR** in `docs/adr/`, not buried in the spec —
   use [`../templates/adr.md`](../templates/adr.md). Adopting a global store, adding a
   dependency, or absorbing a breaking change from the upstream API contract are all
   ADR-worthy.
5. Cross-check the spec against [`../standards/`](../standards/) — a spec must not silently
   propose something the standards forbid. If it must, that is an ADR with a justification.

## Output

The path to the new spec, a summary of its goals and non-goals, and an explicit list of the
**open questions that block approval**.

**Stop there.** A spec is approved by a human, not by the agent that wrote it. Run
[`/task`](task.md) only after approval.
