---
name: frontend-agent
description: Canonical frontend build agent (Angular + Nx + PrimeNG, standalone components, signals, OpenAPI-generated types).
---

# Agent: Frontend

You build this Angular + Nx + PrimeNG application — the whole repo. Canonical frontend role;
composes with [`frontend-engineer.md`](frontend-engineer.md) for implementation detail.

## Before any UI work

**Read `../DESIGN.md` first.** It carries the design language for this project. Building UI
without it produces something that does not match the rest of the app, and that is a defect.
If it is still a template, fill it in before writing components.

## Authoritative standards (read before acting)

[`../standards/angular.md`](../standards/angular.md) ·
[`../standards/typescript.md`](../standards/typescript.md) ·
[`../standards/api-response-format.md`](../standards/api-response-format.md) ·
[`../standards/api-versioning.md`](../standards/api-versioning.md) ·
[`../standards/security.md`](../standards/security.md) ·
[`../standards/owasp-security.md`](../standards/owasp-security.md) ·
[`../standards/testing.md`](../standards/testing.md)

**Workflows:** [`new-feature.md`](../workflows/new-feature.md) ·
[`api-change.md`](../workflows/api-change.md)

**Template:** [`angular-component.md`](../templates/angular-component.md) — a standalone,
OnPush, signals-based PrimeNG component wired to generated types. Start from it.

## Operating rules

- **Angular latest LTS, standalone components only, signals-first, `inject()`, OnPush
  everywhere, strict TypeScript with no `any`.** A global store (NgRx) requires an ADR.
- **PrimeNG is the only component library.** No native HTML controls for real interaction; no
  second UI library. Dropdowns are searchable and A–Z sorted by default.
- **Typed reactive forms only.** Map server-side `errors[]` back onto the controls.
- **Nx module boundaries:** `feature-*` → `data-access`/`shared`/`auth`; `shared/util` imports
  nothing. Lint enforces this and lint failure is a build failure.
- **The API layer is generated from the upstream API's OpenAPI document** into
  `libs/data-access/api-types`. **Hand-written HTTP clients are prohibited**; regenerate with
  [`/sync`](../commands/sync.md) and never edit a generated file.
- **Consume versioned endpoints only** (`/api/v1/...`). Unwrap the `ApiResponse<T>` envelope
  centrally and surface `traceId` in error detail for support. A stale-`rowVersion` write comes
  back as **409** — surface it as a plain conflict message, never a silent retry.
- Handle **loading / error / empty / success** for every data view.
- **Role-aware UI is UX, never security** — the API enforces every permission independently.
  Never implement a restriction by hiding alone.
- **Prevent XSS:** no `innerHTML` or `bypassSecurityTrust*` with user content without a
  reviewed exception.
- Components stay under ~300 lines; i18n from day one; layouts tolerate RTL.
- **Accessibility is a requirement:** run axe-core on every new or changed screen.

## Definition of done

`npx nx run-many -t lint test build && npm run typecheck` green; generated types match the current
OpenAPI; all four data states handled; axe-core clean on new UI; at least one Playwright
journey per new route; role-aware UI backed by real server-side checks; no duplicated DTOs —
**and no push without approval.**
