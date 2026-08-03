# CLAUDE.md — Agentic Angular Boilerplate

Project context for Claude Code. Read this first, then [`DESIGN.md`](DESIGN.md) **before writing
any UI**.

> **HARD RULE — secrets.** Never put a secret, password, API key, token, connection string,
> certificate, or any credential in this file, in a prompt, in a commit message, in an ADR, in a
> spec, or in any other context file. Ever. Values that *look* like secrets are supplied at
> runtime — `apps/web/src/environments/*` and `apps/web/public/env.js` hold **placeholders
> only**, and `docker/40-env.sh` injects the real ones at container start. If you find a
> credential committed, treat it as an incident: rotate it, then remove it.

---

## What this is

A runnable starting point for a new web front end: an Angular 21 + Nx + PrimeNG workspace, an
API client whose TypeScript types are *generated* from the API's OpenAPI document, an offline
MSW demo mode, a quality gate, and a committed `.claude/` harness.

It contains **no business domain**. Two things are shipped built, and they are shipped for
different reasons:

- `libs/feature-items` — the **sample** vertical slice. It proves the whole path end to end
  (list, form, optimistic concurrency, guards, tests, e2e) and is designed to be **deleted** once
  you have copied its shape.
- The **"What's new" feature spotlight** — a real, domain-free module you are meant to **keep**.
  A modal that shows each user a newly-shipped feature once, wired at the shell rather than per
  page. It spans four libraries: the component in `shared/ui`, the gateway in
  `data-access/api-client`, the `en`/`ar` seam in `shared/util`, and the wiring in `shell`. See
  [docs/whats-new.md](docs/whats-new.md).

It talks to an API it does not own. The reference implementation of that API lives in the
sibling repository `aj-boilerplate-be`; the combined tree is `aj-boilerplate-fs`.

## Making it yours (do this first)

1. **Nx identity** — rename the `@aj-boilerplate` scope in `tsconfig.base.json` `paths`, in
   every library `package.json` / `project.json`, and in every import statement. Rename the
   `web` app (and `web-e2e`) if you want a different name; the names appear in
   `apps/*/project.json`, `nx.json`, and the CI workflow.
2. **Design** — fill in [`DESIGN.md`](DESIGN.md), then update
   `apps/web/src/design/tokens.css` and `apps/web/src/styles/app-preset.ts` to match. Replace
   the brand block in `libs/shell/src/lib/sidebar/sidebar.ts` and the hero copy in
   `apps/web/src/app/pages/login-page/login-page.ts`.
3. **Permissions** — replace `ROLES` and `Capabilities` in `libs/auth/src/lib/roles.ts` with
   your model, and the nav entries in `libs/shell/src/lib/nav-config.ts`.
4. **API** — point `generate:api` in `package.json` at your API's OpenAPI document and
   regenerate `libs/data-access/api-types`.
5. **Sample feature** — build your first real feature by copying the shape of
   `libs/feature-items`, then delete it (its README lists every step: the tag, the ESLint
   constraint entry, the path alias, the route, the nav entry).
6. **Announcements** — the "What's new" module needs nothing renamed, but it does need the API
   to serve `GET /api/v1/features/unack` and `POST /api/v1/features/ack`. Until it does, the MSW
   handler in `apps/web/src/mocks/handlers.ts` carries one sample announcement so `demo` mode
   still shows the modal. [docs/whats-new.md](docs/whats-new.md) has the contract.
7. **Docs** — replace `README.md`, and start your own ADR series (keep ours as `0001`–`0005`
   history or delete them).

## Stack

| Concern | Technology |
|---|---|
| Framework | Angular 21 — standalone components, signals, `OnPush`, `inject()` |
| Workspace | Nx 23 monorepo, libraries with enforced import boundaries |
| UI | PrimeNG 21 + PrimeIcons, themed through `@primeuix/themes` |
| Server state | TanStack Query (`@tanstack/angular-query-experimental`) |
| API types | `openapi-typescript` — **generated**, never hand-written |
| Language | TypeScript 5.9, strict, no `any` |
| Unit tests | Vitest + Testing Library for Angular |
| E2E | Playwright + `@axe-core/playwright` |
| Mocks | MSW — the `demo` configuration runs with no API at all |
| Quality | SonarQube Community Build, Gitleaks, CodeQL, ESLint, Prettier |

## Workspace layout

```
apps/
  web/          the application: bootstrap, routes, design CSS, MSW mocks, public auth pages
  web-e2e/      Playwright journeys + the axe-core accessibility gate
libs/
  auth/                    session, guards, role -> capability map
  data-access/api-types/   GENERATED from OpenAPI. Never hand-edited.
  data-access/api-client/  the only place that talks HTTP
  shared/ui/               presentational components, no feature knowledge.
                           Includes `whats-new-modal/` — the "What's new" spotlight.
  shared/util/             formatters and helpers, no UI, no HTTP.
                           Includes `language.service.ts` — the `en`/`ar` `pick()` seam.
  shell/                   sidebar, top bar, layout, nav config. `app-layout.ts` also mounts
                           the "What's new" modal and runs its per-navigation check.
  feature-items/           SAMPLE FEATURE — read it, copy it, delete it
```

Deleting `libs/feature-items` is expected. Deleting the "What's new" module is not — it is a
working module with no domain in it, and `docs/whats-new.md` is its guide.

### The import direction is enforced, not advisory

`app → feature → shell/auth → data-access → shared/util`. Every project carries a `scope:*` tag
in its `project.json`, and `@nx/enforce-module-boundaries` in `eslint.config.mjs` declares what
each scope may import:

| Scope | May depend on |
|---|---|
| `scope:app` | `data-access`, `shared-ui`, `shared-util`, `auth`, `shell`, `feature-*` |
| `scope:feature-items` | `data-access`, `shared-ui`, `shared-util`, `auth` |
| `scope:shell` | `data-access`, `shared-ui`, `shared-util`, `auth` |
| `scope:auth` | `data-access`, `shared-util` |
| `scope:data-access` | `data-access`, `shared-util` |
| `scope:shared-ui` | `data-access`, `shared-util` |
| `scope:shared-util` | `shared-util` |

`shared/*` never imports a feature; features never import each other. Lint fails if you break
it. If two features need the same thing, it moves to `shared/*` — it does not get imported
sideways.

Adding a feature library:

```sh
npx nx g @nx/angular:library --directory=libs/feature-<name> --standalone --prefix=app
```

Then tag it `scope:feature-<name>` in its `project.json`, add that tag to `eslint.config.mjs`
in **two** places (`scope:app`'s allow-list and its own entry), add the path alias to
`tsconfig.base.json`, add a lazy route in `apps/web/src/app/app.routes.ts`, and add a nav entry
in `libs/shell/src/lib/nav-config.ts`. `libs/feature-items` is the worked example of all five.

## Commands

```sh
npm ci                                # reproducible install from the lockfile

npx nx serve web                      # dev server against a real API
npx nx serve web --configuration=demo # offline: MSW-mocked API, no API needed
npx nx build web                      # build (production is the default configuration)
npx nx run-many -t lint --all         # lint everything, incl. module boundaries
npx nx run-many -t test --all         # all unit tests
npx nx run-many -t test --all --coverage
npx nx affected -t lint,test,build    # only what your change touched
npx nx e2e web-e2e                    # Playwright journeys + axe (boots the demo build)
npm run typecheck                     # tsc --noEmit over the app
npm run generate:api                  # regenerate api-types from the API's OpenAPI document
npm audit --audit-level=high
```

`/qa` runs the full local gate; `/pre-push` runs it and reports readiness. Neither pushes.

## Conventions

**Components.** Standalone, signals first, `inject()` over constructor injection, `OnPush`
everywhere. No NgModules. No `ChangeDetectionStrategy.Default`.

**TypeScript.** Strict. **No `any`, ever** — not in tests, not "temporarily". Use `unknown` and
narrow it.

**PrimeNG only.** No bare `<button>`, `<input>`, `<select>`, `<textarea>`, or hand-rolled
`<table>` in a template. Dropdowns are filterable and A–Z sorted (`sortByLabel`) by default.
*One documented exception:* `libs/shared/ui/src/lib/whats-new-modal` — a bespoke "What's new"
spotlight with its own markup, literal colours, and keyframe animations. It is a one-off
announcement surface that must not look like the rest of the app and has no PrimeNG equivalent;
the exception is scoped to that component, is explained in its class comment and in
[`DESIGN.md`](DESIGN.md), and does not extend to accessibility (it carries its own
`role="dialog"`/`aria-*` wiring). Do not cite it as precedent for anything else.

**Shipping a "What's new" announcement is content, not code.** The body is a light markdown the
modal parses at render time: a line starting `- ` becomes a tinted benefit card, its leading emoji
becomes the card icon, and a spaced em-dash (` — `) splits the card title from its description;
every other non-blank line becomes a centred paragraph. Announcing a feature therefore never
touches `whats-new-modal.*`. If you find yourself editing the component to say something new, you
are doing it wrong — read [docs/whats-new.md](docs/whats-new.md) first.

**Generated API types.** `npm run generate:api` writes
`libs/data-access/api-types/src/lib/types.ts`. **Never hand-edit it** — the `protect-files` hook
blocks the attempt — and never re-declare an API type anywhere else. If you need a shape the API
does not expose, the contract changes first. `/sync` does the regeneration and the fallout.

**Versioned endpoints only** — `/api/v1/...`.

**The `ApiResponse<T>` envelope is unwrapped centrally** by `envelopeInterceptor` in
`libs/data-access/api-client`. Feature code never touches `.data`. A `success: false` body
becomes a thrown `ApiError` whatever the HTTP status.

**Every data view handles loading, error, empty, and success.** All four. See
`libs/feature-items/src/lib/item-list-page/item-list-page.html`.

**Optimistic concurrency.** Any editable record carries a `rowVersion`. Read it with the record,
send it back on update, and when the API answers **409**, tell the user plainly that *someone
else changed this* and offer a reload. Never retry a rejected write silently — that is how one
user's change erases another's. `apiErrorMessage()` produces the right copy; `item-form-page.ts`
shows the whole pattern.

**State.** Server state → TanStack Query; query keys include every parameter that changes the
result (page, page size, search), and you invalidate after mutations rather than hand-patching
the cache. Local UI state → signals (`signal`, `computed`, `effect` sparingly — an `effect` that
writes signals usually wants to be a `computed`). No global mutable stores.

**Role-aware UI is never a security boundary.** Capability checks (`auth.capabilities()`) hide
things for clarity; the API authorizes every request independently. Never implement a permission
by hiding a button.

**No `innerHTML` with user content.** Angular escapes interpolation by default — keep it that
way. `[innerHTML]` and `bypassSecurityTrust*` need an explicit review comment justifying them.

**Components ≤ 300 lines.** Past that, split: a container that fetches and a presentational
child, or extract pure logic into a `*-support.ts` file that can be unit-tested directly.

**Read `DESIGN.md` before any UI work.** It is the visual contract; tokens live in
`apps/web/src/design/tokens.css` and the PrimeNG preset in `apps/web/src/styles/app-preset.ts`.

**Tests.** Failing test first, then the code. Vitest for logic and components, Playwright for
critical journeys, axe on every new or changed screen.

## Non-negotiable rules

1. **No secrets in context.** See the rule at the top of this file.
2. **Never `git push` without explicit human approval**, on any branch, to any remote, every
   time. Committing is fine; pushing is a human decision.
3. **The quality gate runs before any push is proposed.** Zero new Blocker, Critical, or Major
   SonarQube findings; ≥80% coverage on new code. Minor and Info may be triaged. The gate
   targets **SonarQube Community Build** (free, self-hosted): one project, one branch, no branch
   analysis and no pull-request decoration — never pass `sonar.branch.name`,
   `sonar.pullrequest.*`, or a `branch`/`pullRequest` MCP argument. See
   [`.claude/standards/sonarqube.md`](.claude/standards/sonarqube.md).
4. **The build is clean.** `npx nx build web` with no warnings; a lint error is a failure.
5. **Respect the module-boundary rule.** If a change needs to break it, the design is wrong.
6. **PrimeNG only**; **generated types only** for API contracts.
7. **All four view states, keyboard-navigable, axe green.**
8. **One task per session, fresh context per task.** No unattended multi-hour runs.
9. **Human review is mandatory** and is never waived because an agent wrote the code. The
   developer who prompted it owns it. Keep pull requests to roughly 400 changed lines.
10. **Update the docs with the change.** If a convention changed, this file changes in the same
    PR. If a decision was made, an ADR lands with it. If the API contract changed, the generated
    types change with it.
11. **Classify the task and state the model tier before the first tool call.** Frontier tier for
    architecture, security review, complex debugging, high-risk refactors, and the final
    pre-push review; workhorse tier for everything else. Say the recommendation out loud in the
    first reply — and if this session is on a costlier model than the work needs, **stop and say
    so** rather than spending it. The `model-routing` hook injects this on every prompt; the
    policy is [`.claude/model-routing.md`](.claude/model-routing.md).

## Definition of done

- `npx nx build web` succeeds with **no warnings**.
- `npx nx run-many -t lint --all` and `-t test --all` pass.
- Generated API types match the current OpenAPI document (regenerate, commit the diff).
- All four view states handled; keyboard-navigable; axe suite green.
- No `any`, no hand-written API DTOs, no secrets.
- **Nothing is pushed without explicit approval.**

## Where to look next

| Topic | Path |
|---|---|
| Deeper standards (one file per topic) | [`.claude/standards/`](.claude/standards/) |
| Angular and component rules | [`.claude/standards/angular.md`](.claude/standards/angular.md) |
| The API contract this app consumes | [`.claude/standards/api-response-format.md`](.claude/standards/api-response-format.md) · [docs/api/README.md](docs/api/README.md) |
| Slash commands | [`.claude/commands/`](.claude/commands/) |
| Hooks and their triggers | [`.claude/hooks/`](.claude/hooks/) · [`.claude/README.md`](.claude/README.md) |
| Model routing (enforced every prompt) | [`.claude/model-routing.md`](.claude/model-routing.md) |
| The SonarQube gate, Community Build setup | [`.claude/standards/sonarqube.md`](.claude/standards/sonarqube.md) |
| Every library and why each boundary exists | [docs/architecture.md](docs/architecture.md) |
| The "What's new" spotlight: wiring, authoring, preview | [docs/whats-new.md](docs/whats-new.md) |
| Five-stage workflow and guardrails | [docs/workflow.md](docs/workflow.md) |
| Definition of Done | [docs/definition-of-done.md](docs/definition-of-done.md) |
| Day-1 checklist | [docs/onboarding.md](docs/onboarding.md) |
| Spec template | [docs/specs/TEMPLATE.md](docs/specs/TEMPLATE.md) |
| Architecture decisions | [docs/adr/](docs/adr/) |
| Session handoffs | [docs/handoff/](docs/handoff/) |
