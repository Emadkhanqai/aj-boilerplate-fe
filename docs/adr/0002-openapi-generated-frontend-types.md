# ADR-0002: This app's API types are generated from OpenAPI, never hand-written

**Status:** Accepted
**Date:** 2026-08-02
**Deciders:** Boilerplate maintainers

---

## Context

When a TypeScript interface is written by hand to mirror a shape the API returns, the two are
correct on the day they are written and drift from that day forward. The drift is silent:
TypeScript happily compiles against a shape the API stopped sending months ago, and the failure
surfaces at runtime, in a browser, usually in production, usually as `undefined`.

The failure modes are boringly consistent — a field renamed upstream, a nullable field the client
treats as required, an enum gaining a member the client's union does not have, a number that
became a string. None of these are caught by any test that does not talk to the real API.

The API team publishes an OpenAPI document for the service this app consumes. That document is
generated from the API's own code, so it describes what the service actually serialises rather
than what someone remembered to write down. This app does not own that document and cannot change
it — the only question here is whether the client trusts it or re-types it by hand.

## Decision

We will generate this app's API types from the upstream API's OpenAPI document, and hand-writing
a type that mirrors an API contract is a defect.

- `libs/data-access/api-types` is **generated output**. It is committed (so builds are
  reproducible and diffs are reviewable) and never hand-edited.
- Regeneration is `npm run generate:api`, which runs `openapi-typescript` against the API's
  OpenAPI document and rewrites `libs/data-access/api-types/src/lib/types.ts` wholesale. The
  `/sync` command does this and then checks for duplicated DTOs and unversioned endpoint usage.
- `libs/data-access/api-client` is hand-written and thin: it wires HTTP calls, unwraps the
  `ApiResponse<T>` envelope from
  [ADR-0003](0003-apiresponse-envelope-and-status-code-contract.md) in `envelopeInterceptor`, and
  exposes typed methods. It imports its types from `api-types` and defines none of its own.
- **Contract first.** A contract change is agreed with the API team, lands in the published
  OpenAPI document, and is then regenerated here. The sequence is never "write the client type,
  then ask the API to match".
- View models are welcome — a type shaped for a specific screen is fine. What is banned is a
  hand-written *duplicate* of an API contract type.
- If the generated output is wrong, the fix is upstream in the OpenAPI document. Never patch the
  generated file; the next regeneration destroys the patch anyway.

## Consequences

### Positive

- A breaking upstream change breaks this build, which is the earliest and cheapest place to find
  it. This single property is the entire justification.
- Nullability, enums, and formats come across accurately, because they come from the same
  metadata the API serialises with.
- Reviewing a contract change is reviewing a diff of the generated file — the blast radius is
  visible before anyone runs the app.
- Agents cannot invent a plausible-looking DTO, because inventing one is a rule violation with an
  obvious tell: a `type` or `interface` outside `api-types` that names an API resource.

### Negative

- Generation needs the OpenAPI document to be reachable — a running API, a published URL, or a
  saved copy of it. That is real friction for a developer working offline, which is part of why
  `npx nx serve web --configuration=demo` exists and runs against MSW rather than the API.
- Generated types follow the generator's conventions, not the team's. They are sometimes ugly.
- A large contract change produces a large mechanical diff that reviewers are tempted to skim.
- Forgetting to regenerate is a real and common mistake; it degrades to the hand-written
  situation until someone notices.
- The client's type safety is only as good as the upstream document. A sloppily annotated
  endpoint produces sloppy client types, and this repo cannot fix that itself — it can only
  report it upstream.

### Neutral

- The generated file is committed, so it appears in pull requests and in line counts.
- The MSW handlers in `apps/web/src/mocks` must stay envelope-shaped and type-checked against the
  generated types, or `demo` mode stops being a faithful stand-in for the API.

### Follow-on work

- A CI check that regenerates and fails on a non-empty diff would close the "forgot to
  regenerate" gap. Worth adding once the API publishes a stable document URL per environment.

## Alternatives considered

### Hand-written TypeScript interfaces

Full control, no tooling, no OpenAPI document required. Rejected — this is precisely the drift
problem described above, and no amount of discipline has ever solved it on a team of more than
one.

### A shared schema language (Protobuf, JSON Schema) as the source of truth

Genuinely good, and language-neutral. Rejected as disproportionate and, more importantly, not
this repository's decision to make: it would require the API to adopt it too, and it duplicates
information the OpenAPI document already carries.

### Generating at build time instead of committing the output

No stale file, no forgetting. Rejected because it makes every build depend on a reachable API,
and it hides contract changes from code review — the diff is where the value is.

### Runtime validation only (parse responses against a schema)

Catches drift, but at runtime and in the user's browser. Complementary at best, not a replacement
for compile-time typing.

## Verification

`libs/data-access/api-types` has no hand-authored commits. Any `interface` or `type` in feature
code that mirrors an API contract is a review rejection. `/sync` reports duplicated DTOs, and
`npx nx run-many -t lint --all` plus `npx nx build web --configuration=production` catch the call
sites a regeneration breaks.

## References

- [docs/api/README.md](../api/README.md) — the contract this app consumes, and how to regenerate
- [ADR-0003](0003-apiresponse-envelope-and-status-code-contract.md) — the envelope the client unwraps
- [`.claude/workflows/api-change.md`](../../.claude/workflows/api-change.md) — the procedure when the contract moves
