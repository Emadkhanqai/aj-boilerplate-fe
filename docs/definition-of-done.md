# Definition of Done

A change is **done** when all six conditions below are true. Not five. There is no partial
credit, and there is no "done except for".

"Done" here means: merged, deployed to staging, verified there, and safe to leave alone.

---

## 1. The spec's acceptance criteria are demonstrably met, with test evidence in the pull request

Every acceptance criterion in the spec maps to at least one test, and that test's passing output
is in the pull request. Not a claim that it passes — the output.

A criterion with no test is not met. A test that has never been observed failing has not been
shown to test anything.

## 2. The gate is green, locally and in CI

Every command below passes, and the SonarQube quality gate has passed:

```bash
npx nx run-many -t lint --all         # includes the module-boundary rules
npm run typecheck
npx nx run-many -t test --all
npx nx build web --configuration=production
npx nx e2e web-e2e                    # when a route, journey, or user-visible behaviour changed
npm audit --audit-level=high
```

**The production build must complete with no warnings.** A warning is a defect that has not been
triaged yet.

The quality gate specifically: **zero new Blocker, Critical, or Major findings** and **≥80%
coverage on new code**. Minor and Info findings may be triaged, with the triage recorded.

A red gate is not "nearly done" and is never merged with a follow-up ticket attached.

## 3. The frontend rules hold — states, accessibility, types, contract

This is the part a passing test suite does not prove on its own. Every item is checked by a
human, on the change in front of them:

- **All four view states** — loading, empty, error, success — are handled on every data view. A
  skeleton, not a spinner. An empty state that explains *why* and offers the primary action. An
  error state carrying the `traceId`. A missing state is an incomplete feature, not a follow-up
  ticket.
- **Keyboard-navigable, and the axe suite is green.** Every interactive element is reachable and
  operable by keyboard, focus is visible and never trapped, and `npx nx e2e web-e2e` passes
  including its accessibility checks.
- **PrimeNG only.** No native `<input>`, `<select>`, `<textarea>`, `<button>`, or hand-rolled
  `<table>` in a feature template — see
  [ADR-0001](adr/0001-primeng-as-sole-component-library.md). Dropdowns filterable and A–Z sorted.
- **No `any`.** Not in source, not in tests, not "temporarily". `unknown`, narrowed.
- **No hand-written DTOs.** Nothing outside `libs/data-access/api-types` mirrors an API contract
  type, and `api-types` itself has not been hand-edited — see
  [ADR-0002](adr/0002-openapi-generated-frontend-types.md).
- **Generated types are current.** If the contract moved, `npm run generate:api` has been run and
  the diff is committed in this pull request.
- **Every call is versioned** (`/api/v1/...`) and goes through `libs/data-access/api-client`. No
  component or feature service constructs its own HTTP call, and none of them touch `.data`.
- **A `409` is never silently retried.** A write rejected for a stale `rowVersion` tells the user
  and offers a reload.
- **No secrets.** No token, key, or credential in the repository, in `src/environments/*`, in
  `public/env.js`, or in any context file. Placeholders only; real values arrive at runtime.

## 4. AI review and human review are both approved

`/review` has run and its findings are resolved. Then a human has read every line and approved.

Both. In that order. **Human review is mandatory and is never waived because an agent wrote the
code** — agent-written code is fluent and confident, which makes a wrong approach look like a
right one, so it warrants more scrutiny rather than less. The developer who prompted it owns it
and must be able to explain any line of it.

## 5. Documentation is updated if conventions or contracts changed

- A convention changed → [`CLAUDE.md`](../CLAUDE.md) changes in the same pull request.
- A visual rule changed → [`DESIGN.md`](../DESIGN.md) changes with it.
- A decision was made that is expensive to reverse → an [ADR](adr/README.md) lands with the
  change.
- The API contract moved → the generated types are regenerated and committed, and
  [`docs/api/README.md`](api/README.md) still describes reality.
- A new error `code` is being handled → it is documented where the UI branches on it.

If nothing changed, nothing to do. Stale documentation is worse than none, because people believe
it.

## 6. Deployed to staging, smoke-tested, and no open critical or major findings

Merged is not deployed, and deployed is not working. The change is on staging, and someone has
actually exercised the changed path there in a real browser — the real journey, against the real
API, not a health check and not the `demo` build. Note what was smoke-tested and what the result
was.

And nothing critical or major is outstanding from any source: the quality gate, the AI review,
the human review, dependency or secret scanning, or the staging smoke test. An open critical
finding with a follow-up ticket is an open critical finding.

---

## Checklist

Copy this into the pull request description.

```markdown
## Definition of Done

- [ ] 1. Every acceptance criterion met, with test output pasted below
- [ ] 2. Lint, typecheck, unit tests, production build (no warnings), e2e, and npm audit green;
         quality gate passed (0 new Blocker/Critical/Major, ≥80% new-code coverage)
- [ ] 3. Four view states · keyboard + axe green · PrimeNG only · no `any` · no hand-written DTOs
         · generated types current · versioned calls · 409 handled · no secrets
- [ ] 4. `/review` findings resolved AND a human has approved
- [ ] 5. CLAUDE.md / DESIGN.md / ADR / generated types updated, or confirmed unchanged
- [ ] 6. Deployed to staging and smoke-tested — what was tested: ________ ; no open critical or
         major findings

Spec: docs/specs/____
Evidence:
```

---

## What this is not

It is not a suggestion, a stretch goal, or a target to hit on average. It is the bar for merging
a single change.

It is also not a substitute for judgement. Meeting all six conditions does not make a bad design
good. Review still has to ask whether this was the right thing to build.
