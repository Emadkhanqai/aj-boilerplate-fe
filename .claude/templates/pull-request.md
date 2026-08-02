# PR: <concise title>

## Summary

What changed and why. Link the spec in `docs/specs/` and any ADR in `docs/adr/`.

## Changes

- **Libraries/routes touched:** <feature libs, shared, data-access>
- **API types regenerated?** <yes/no — if yes, what changed upstream>
- **Docs:** <OpenAPI snapshot, ADRs>

## Quality gate (green before requesting merge)

- [ ] `npx nx run-many -t lint test build && npm run typecheck` clean
- [ ] Playwright journeys green; axe-core clean on new or changed screens
- [ ] SonarQube — **0** Blocker / Critical / Major, coverage on new code ≥80%
- [ ] Gitleaks clean
- [ ] `npm audit --audit-level=high` clean

## Architecture & standards

- [ ] Nx module boundaries respected
- [ ] Standalone + OnPush + signals + `inject()`; typed reactive forms; PrimeNG only
- [ ] No hand-written HTTP client, no hand-duplicated DTO
- [ ] No `any`

## API contract

- [ ] Versioned endpoint (`/api/v1/...`); `ApiResponse<T>` envelope unwrapped centrally with
      `traceId` surfaced on error
- [ ] Correct handling per status code, including 401 / 403 / 404 and the 409 stale-`rowVersion`
      conflict
- [ ] `docs/api/` snapshot refreshed if the upstream document changed; frontend types
      regenerated and current

## Security

- [ ] Role-aware UI backed by a real server-side check, never the only gate
- [ ] No restricted field rendered or logged client-side
- [ ] No secrets, real hostnames, or credentials

## Notes / risks

<remaining risks, follow-ups, anything a reviewer should look at hardest>

> Push requires explicit approval, every time. The SonarQube gate must pass first.
