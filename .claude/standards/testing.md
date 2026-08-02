# Standard: Testing

Testing is required, not optional. **Verification precedes any claim of "done"** and any push.
"It should work" is not a result; a command's output is.

## The layers

| Layer | Tool | Scope |
|---|---|---|
| Unit / component | **Vitest** | Services, signals, pipes, and component logic in isolation. Fast, no network. |
| Component rendering | **Testing Library for Angular** | Render a component and assert on what a user would see/do — queries by role/label/text, not by internal structure. |
| API mocking | **MSW** (`apps/web/src/mocks/handlers.ts`) | Deterministic, offline HTTP responses for the `demo` build and for tests — every handler returns the real `ApiResponse<T>` envelope shape (see [`api-response-format.md`](api-response-format.md)), so a handler bug and a real backend bug fail the same way. |
| End-to-end journeys | **Playwright** (`apps/web-e2e`) | Full user journeys against a running build. Every new route gets at least one journey. |
| Accessibility | **axe-core** (`@axe-core/playwright`) | Automated accessibility assertions on every new or changed screen (`apps/web-e2e/src/accessibility`). |
| Types | `tsc --noEmit` / `npx nx run-many -t typecheck` | Part of the test surface, not a separate concern — see [`typescript.md`](typescript.md). |

## What must be covered

- **Every view state** in [`error-handling.md`](error-handling.md#the-four-view-states) —
  loading, empty, error, success — for a screen that reads from the API.
- **Every client-side validation rule** that blocks a submit, and the corresponding
  server-error-mapping path (a `400`/`422` with `errors[]` lands on the right control) — see
  [`input-validation-sanitization.md`](input-validation-sanitization.md).
- **Every distinct API failure the UI branches on**: 401 (session expiry), 403 (access denied),
  404, and 409 (stale `rowVersion` conflict) each get a test proving the UI reaches the right
  state — not just that *an* error occurred. `libs/feature-items/src/lib/item-form-page/*.spec.ts`
  is the reference for the 409 case.
- **Route guards**: a test proving `capabilityGuard` blocks navigation for a role lacking the
  capability, and allows it for a role that has it. Remember this is UX coverage, not a
  security test — see [`owasp-security.md`](owasp-security.md).
- **Auth edge cases**: the OIDC `state`/`nonce` mismatch paths, the single-flight refresh
  behaviour under concurrent 401s, and `sanitizeReturnPath` rejecting an off-origin or
  protocol-relative redirect target (`libs/auth/src/lib/sanitize-return-path.spec.ts` is the
  reference).
- **Every new or changed screen passes an axe scan** with zero violations at the default rule
  set, or a documented, reviewed exception.

## How to write them

- **Test behaviour and invariants, not implementation details.** A test that breaks when you
  rename a private method or a signal is a maintenance tax, not a safety net. Testing Library's
  query-by-role/label style enforces this by construction.
- Follow test-driven development where it fits: failing test → minimal code → green →
  refactor.
- One reason to fail per test. Arrange/Act/Assert, named for the behaviour under test.
- No test depends on another test's leftovers, on wall-clock time, or on execution order.
- MSW handlers are the shared fixture for both the `demo` build and tests — extend
  `apps/web/src/mocks/handlers.ts` rather than hand-rolling a parallel mock per test file.
- Coverage target: **≥80% on new code**, enforced by the quality gate (see
  [`sonarqube.md`](sonarqube.md)). Coverage is a floor for spotting untested paths, never the
  goal itself.

## Commands

```bash
npx nx run-many -t test                           # all unit/component tests (Vitest)
npx nx run-many -t test typecheck                 # + type checking
npx nx affected -t test --base=origin/main        # what the pre-push hook runs
npx nx e2e web-e2e                                # Playwright journeys, incl. axe-core
npx playwright install --with-deps chromium       # one-time browser install for E2E
```

## Gate

Tests must pass **before** the SonarQube scan and **before** a push is proposed. See
[`sonarqube.md`](sonarqube.md) and [`../commands/pre-push.md`](../commands/pre-push.md).

## Related

[`angular.md`](angular.md) · [`typescript.md`](typescript.md) · [`error-handling.md`](error-handling.md) ·
[`sonarqube.md`](sonarqube.md)
