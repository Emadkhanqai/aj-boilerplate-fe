# Workflow: Code Review

> **Model routing (do first):** see [`../model-routing.md`](../model-routing.md). Final
> pre-push / architecture review → frontier tier.

Run before proposing a push, after the build and test gate, alongside SonarQube. The
slash-command form is [`/review`](../commands/review.md); the agent form is
[`../agents/code-reviewer.md`](../agents/code-reviewer.md).

## Checklist

**Architecture**
- [ ] Nx module boundaries respected: `feature-*` → `data-access` / `shared` / `auth`;
      `shared/util` imports nothing; no feature imports another feature.

**Standards**
- [ ] Matches the relevant files in [`../standards/`](../standards/).
- [ ] No `any`; strict TypeScript respected.
- [ ] Components under ~300 lines; standalone + OnPush + signals + `inject()`.

**Correctness**
- [ ] Implements what the spec in `docs/specs/` actually says — and only that.
- [ ] Every invariant the spec states is enforced *and* tested.
- [ ] State transitions guarded; illegal transitions rejected.

**Security**
- [ ] Role-aware UI backed by a real server-side check — never the only gate on an action.
- [ ] No restricted field rendered or logged client-side.
- [ ] No secrets, no real hostnames, or credentials.
- [ ] Errors render a plain message; no internal detail, stack trace, or raw payload leaks to
      the UI.

**API contract**
- [ ] Versioned endpoint (`/api/v1/...`); `ApiResponse<T>` envelope unwrapped centrally with
      `traceId` surfaced on error.
- [ ] Correct handling per status code, including 401 (session expiry), 403 (access-denied),
      404, and the **409 stale-`rowVersion` conflict**.
- [ ] Generated types (`libs/data-access/api-types`) current with the upstream OpenAPI
      document; the `docs/api/` snapshot updated if it changed.

**Forbidden patterns**
- [ ] No hand-written HTTP client, no hand-duplicated DTO.
- [ ] No native HTML control where PrimeNG is required.
- [ ] No `bypassSecurityTrust*` / `innerHTML` on user content.

**Tests**
- [ ] New and changed behaviour covered.
- [ ] A negative role/capability test exists.
- [ ] Playwright journey and axe-core run for any new route.

## Output

Prioritised findings, most severe first, each with `file:line` and marked **blocker** or
**nit**. No push approval while a correctness, security, or architecture blocker is open.
