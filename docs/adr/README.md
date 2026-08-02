# Architecture Decision Records

An ADR records **why** a decision was made, at the time it was made. It is not documentation of
how the system works today — that is what `CLAUDE.md` and the standards are for. An ADR stays
true even after the decision is reversed, because it describes a moment.

## Index

| # | Decision | Status |
|---|---|---|
| [0001](0001-primeng-as-sole-component-library.md) | PrimeNG is the only component library, and native form controls are banned | Accepted |
| [0002](0002-openapi-generated-frontend-types.md) | This app's API types are generated from OpenAPI, never hand-written | Accepted |
| [0003](0003-apiresponse-envelope-and-status-code-contract.md) | We depend on a uniform `ApiResponse<T>` envelope and a strict status-code contract | Accepted |
| [0004](0004-three-repository-split.md) | Publish as three repositories, of which this is the frontend one | Accepted |

These four record the decisions taken when this boilerplate was built. Keep them as history and
start your own series at `0005`, or delete them and start again at `0001` — but pick one and be
consistent.

## Writing one

1. Copy [TEMPLATE.md](TEMPLATE.md) to `NNNN-short-slug.md`, using the next free number.
2. Fill in context, decision, consequences (including the negative ones), and the alternatives
   you actually considered.
3. Open it as its own pull request, or alongside the change it governs.
4. Set the status to `Accepted` when it merges.

**Never edit an accepted ADR to reflect a new decision.** Write a new one, mark it as superseding
the old, and set the old one's status to `Superseded by ADR-NNNN`.

## When to write one

Write an ADR when the decision is expensive to reverse, crosses team or library boundaries,
constrains future work, or will provoke "why is it like this?" from someone who was not there.

Do not write one for a choice a single pull request can undo.

Reading all four is part of [Day-1 onboarding](../onboarding.md), and
[`.claude/templates/adr.md`](../../.claude/templates/adr.md) is the same shape in the form the
agents use.
