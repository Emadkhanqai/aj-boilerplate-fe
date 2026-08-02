# Spec: <Feature name>

**File:** `docs/specs/YYYY-MM-DD-<slug>.md`
**Status:** Draft | Approved | Implemented | Superseded
**Author:** <name>
**Reviewer:** <name — a human, always>
**Related:** ADR-XXXX · issue #XXX

> Written and approved **before** implementation starts. Stage 1 of
> [the workflow](../workflow.md). If the spec changes mid-implementation, update this file in
> the same pull request — a spec that no longer matches the code is worse than no spec.
>
> Delete the guidance blockquotes when you fill this in. Keep every heading; write "None" where
> a section genuinely does not apply, so a reader can tell the difference between *considered
> and empty* and *forgotten*.

---

## 1. Problem statement

> What is wrong or missing today, for whom, and what does it cost them? Describe the problem,
> not the solution. Two or three paragraphs at most. If you cannot state the problem without
> naming your intended implementation, you do not understand it yet.

**Today:**

**Who is affected:**

**Why it matters now:**

**Success looks like:** <one sentence, observable from outside the system>

---

## 2. Acceptance criteria

> Every criterion is Given/When/Then, independently testable, and observable through the UI —
> not through internal state, and not through a signal's value. These become the tests. A
> criterion nobody can write a test for is not a criterion; rewrite it.

| # | Criterion |
|---|---|
| AC-1 | **Given** <starting state> **When** <action> **Then** <observable outcome> |
| AC-2 | **Given** … **When** … **Then** … |
| AC-3 | **Given** <an invalid input> **When** the user submits **Then** the field shows the error and nothing is sent |
| AC-4 | **Given** the API returns `409` **When** the user saves **Then** the conflict message appears and the change is not re-sent |
| AC-5 | **Given** a user without the capability **When** they open the route **Then** they see <the access-denied page / the read-only view> |

Each acceptance criterion must be traceable to at least one test in §6, and the pull request
must show that test passing.

---

## 3. API contract — what the upstream API must expose

> This app consumes an API it does not own. Agree the contract with the API team **here**, before
> any code: it lands in the API's published OpenAPI document first, and only then is it
> regenerated into `libs/data-access/api-types` with `npm run generate:api`. Never hand-write a
> client DTO. See [docs/api/README.md](../api/README.md) and
> [ADR-0002](../adr/0002-openapi-generated-frontend-types.md).
>
> If this feature needs nothing new from the API, write "None — uses the existing
> `GET /api/v1/<resource>`" and move on. That is a valid and common answer.

### Endpoints this feature calls

| Method | Route | Auth | Success | Notes |
|---|---|---|---|---|
| `GET` | `/api/v1/<resource>` | `<policy>` | `200` `PagedResponse<XSummary>` | paged, filterable by … |
| `GET` | `/api/v1/<resource>/{id}` | `<policy>` | `200` `ApiResponse<X>` | |
| `POST` | `/api/v1/<resource>` | `<policy>` | `201` + `Location` | |
| `PUT` | `/api/v1/<resource>/{id}` | `<policy>` | `200` | optimistic concurrency via `rowVersion` |
| `DELETE` | `/api/v1/<resource>/{id}` | `<policy>` | `204` | |

New or changed endpoints must be **versioned** (`/api/v1/...`) and must return the
`ApiResponse<T>` envelope like everything else — see
[ADR-0003](../adr/0003-apiresponse-envelope-and-status-code-contract.md).

### Shapes this feature needs

> Describe the fields the UI needs and why, in TypeScript terms — this is a request to the API
> team, not a declaration. State which fields are required, their formats, their maximum lengths,
> and anything that must never be sent to a client. The generated types are the outcome of this
> conversation, not the input to it.

```ts
// The shape this screen needs. Once agreed and published, `npm run generate:api`
// produces the real thing in libs/data-access/api-types — never hand-written.
interface X {
  id: string;
  name: string;          // required, ≤ 200 chars
  status: 'Draft' | 'Active' | 'Archived';
  rowVersion: string;    // required for any editable record
}
```

### Error codes this UI handles

| HTTP | `code` | When | What the user sees |
|---|---|---|---|
| `400` | `VALIDATION_ERROR` | request failed validation; `errors[]` lists the field failures | inline field errors |
| `403` | `FORBIDDEN` | caller lacks the capability | access-denied route |
| `404` | `NOT_FOUND` | resource missing or hidden from this caller | not-found state |
| `409` | `CONFLICT` | `rowVersion` did not match | "someone else changed this" + reload; never a silent retry |
| `422` | `<DOMAIN_RULE>` | a domain invariant rejected the request | banner or field error |

New codes are `SCREAMING_SNAKE_CASE`, stable forever, agreed with the API team, and listed here
before they are used.

### Breaking-change check

- [ ] No field this app already reads is removed, renamed, or narrowed in type
- [ ] No status code or existing `code` value this app branches on is changed
- [ ] If any box above is unchecked, this needs a new API version, an ADR, and a coordinated
      release with the API team

---

## 4. Client state and caching

> Server state is TanStack Query; local UI state is signals. Decide both here rather than
> discovering them during implementation.

| Concern | Decision |
|---|---|
| **Query keys** | `['<resource>', { page, pageSize, search }]` — every parameter that changes the result is in the key |
| **Invalidation** | which mutations invalidate which keys, and why |
| **Stale time / refetch** | default, or the reason for deviating |
| **Optimistic updates** | none by default — say so explicitly if this feature needs them, and how a rollback looks |
| **Local UI state** | which signals, and what is `computed` rather than stored |

### Anything persisted in the browser

Does this store anything in `localStorage`, `sessionStorage`, a cookie, or the URL? List it, say
why the URL is not enough, and say when it is cleared.

**Never** persist a token, a credential, or personal data client-side beyond what the session
genuinely requires. If in doubt, do not store it.

---

## 5. UI states

> Every screen ships all four states. A missing empty state or error state is an incomplete
> feature, not a follow-up ticket. PrimeNG components only —
> [ADR-0001](../adr/0001-primeng-as-sole-component-library.md).

| State | Behaviour |
|---|---|
| **Loading** | skeleton (not a spinner) for the list; controls disabled; no layout shift on resolve |
| **Empty** | explains *why* it is empty and offers the primary action |
| **Error** | human-readable message derived from the response `code`, a retry affordance, and the `traceId` visible for support |
| **Success** | the populated view; confirm destructive actions; toast on write |

Also specify: validation behaviour and when it fires, keyboard and screen-reader behaviour,
responsive behaviour, and what a user without permission sees (hidden vs. disabled — and
remember that hiding is never the security boundary).

**Route(s):** `/…`
**Nx library:** `libs/feature-<name>`
**New shared components:** any addition to `libs/shared/ui`, and why it belongs there rather than
in the feature

---

## 6. Test plan

| Level | What it covers | Where |
|---|---|---|
| **Unit** | pure logic — formatters, mappers, `*-support.ts` helpers, guards | `libs/shared/util`, `libs/auth` (Vitest) |
| **Component** | states, signals, form validation, error rendering, capability-driven UI | `libs/feature-<name>` (Vitest + Testing Library) |
| **API client** | request shape, envelope unwrapping, `ApiError` mapping, `409` handling | `libs/data-access/api-client` (Vitest + `HttpTestingController`) |
| **Mocks** | the MSW handler matches the real contract, envelope and all | `apps/web/src/mocks` |
| **E2E** | the one critical journey a user must never lose | `apps/web-e2e` (Playwright) |
| **Accessibility** | axe on every route this feature adds or changes | `apps/web-e2e` (axe-core) |

**Traceability**

| AC | Test |
|---|---|
| AC-1 | `<spec file>` › `<test name>` |
| AC-2 | `<spec file>` › `<test name>` |

**Coverage:** ≥80% on new code (enforced by the quality gate).

**Not covered, deliberately:** <list, with the reason>

---

## 7. Out of scope

> Explicit. This is the section that prevents scope creep during implementation and argument
> during review.

- <thing that a reader might reasonably assume is included, and is not>
- <thing deferred to a later spec — link it if it exists>

---

## 8. Risks and open questions

| # | Risk / question | Owner | Resolution |
|---|---|---|---|
| 1 | | | |

Anything waiting on the API team belongs here, with a name against it. Every open question must
be closed before this spec moves to **Approved**.

---

## 9. Rollout

- **Feature flag:** name, default, removal criteria — or "none"
- **Release order:** does the API change ship before this, with it, or after? What does this app
  do in the window where the API does not yet support it?
- **Rollback:** how do we undo this in production?
- **Observability:** what tells us it is working — and what does a user report look like if it is
  not? (`traceId` is on every error state for exactly that conversation.)
