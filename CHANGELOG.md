# Changelog

Notable changes to this boilerplate. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/spec/v2.0.0.html) as adapted below.

**This file is written for the person upgrading, not for the person who made the change.**
A changelog entry that reads like a commit message has failed at its only job. Every entry
should answer: what changed, whether I have to do anything about it, and what happens if I
ignore it. If an entry needs a migration step, the step is in the entry — not in a linked
issue, not in a pull request comment.

For how to actually pull these changes into a project that cloned this boilerplate, see
[docs/upgrading.md](docs/upgrading.md).

---

## Versioning, for a boilerplate

Semantic Versioning is defined in terms of an API. A boilerplate has no API — it has a
shape that consumers have already copied. So the meanings are pinned explicitly:

| Bump | Means | Examples |
|---|---|---|
| **MAJOR** | A consumer who cloned an earlier version has to change their own code to take this. | A library moves or is renamed · a `libs/*` public export changes · the `ApiResponse<T>` envelope this client unwraps changes shape · a hook's contract or opt-out variable changes · a configuration key is renamed or removed · a `.claude/` standard reverses a rule people wrote code against. |
| **MINOR** | Something new that an existing consumer can take or leave. | A new hook · a new workflow · a new ADR · a new optional configuration key with a safe default · a new document. |
| **PATCH** | A fix or a clarification with no shape change. | A hook bug · a broken CI step · a wrong path in a document · a dependency bump with no behaviour change. |

Two consequences worth stating, because both surprise people:

- **A documentation change can be MAJOR.** If a standard in `.claude/standards/` reverses a
  rule, consumers who followed it are now non-compliant. That is a breaking change even
  though no code moved.
- **A dependency bump is usually PATCH here, even when the dependency's own bump is
  MAJOR.** What matters is the effect on a consumer's tree, and a consumer who cloned this
  boilerplate owns their own `package.json`.

## Releasing

1. Everything intended for the release is merged to `main` and the gate is green.
2. Move the `[Unreleased]` entries into a new version section with today's date. Rewrite
   them for the upgrader if they still read like commit subjects.
3. Choose the bump using the table above. The Conventional Commits types in the range are
   an input, not the answer: `feat` suggests minor and `!`/`BREAKING CHANGE` suggests
   major, but a `docs:` commit that reverses a standard is still major.
4. Tag it. **Annotated tags only** — a lightweight tag carries no author, date, or message,
   and the tag is the thing consumers pin to.

   ```bash
   git tag -a v1.2.0 -m "v1.2.0 — container image scanning, SBOM, Dependabot"
   git push origin v1.2.0
   ```

5. Create the GitHub release from the tag, with this file's section as the body.

Tag format is `vMAJOR.MINOR.PATCH`.

**This repository is derived, so steps 1–5 happen in `aj-boilerplate-fs` first.** It is
regenerated wholesale from that tree and tagged with the same version — **the three
repositories share a version number.** They are one artefact published in three shapes
([ADR-0004](docs/adr/0004-three-repository-split.md),
[ADR-0007](docs/adr/0007-scripted-one-way-derivation-for-the-three-repositories.md)), and a
consumer comparing `aj-boilerplate-fe` v1.2.0 against `aj-boilerplate-fs` v1.2.0 must be
comparing the same content. Pre-releases, if ever needed, are `v1.2.0-rc.1` and are never
derived here — this repository tracks releases only.

---

## [Unreleased]

Nothing yet.

---

## [0.1.1] — 2026-09-01

A patch release, and both entries are the same story: a tree that was green in August went
red in September without anybody touching it. Advisories were published against OS packages
in the base image nobody chose directly, and one instruction in the upgrade guide went stale
because the boilerplate grew. Nothing changes shape, and there is nothing in your own code
to alter.

### Fixed

- `docs/upgrading.md` told you to start your own ADR series at `0008`, and called the shipped
  set "the seven ADRs". There are eleven, so `0008`–`0011` are taken and that advice collided
  with real files. It now says to count `docs/adr/` at the version you cloned, because this
  number moves with every release. **If you already numbered your own ADRs from `0008`, you
  have a clash to reconcile** — `docs/adr/README.md` is explicit that numbers are never
  reused or renumbered, so renumber *yours*, not the boilerplate's.

- **The frontend image failed the container scan.** The `nginx:alpine` base is rebuilt on
  nginx's schedule rather than Alpine's, so between those rebuilds it ships packages for
  which Alpine has already published a fix — here `libcrypto3` and `libssl3`
  (CVE-2026-14456) and `libexpat` (CVE-2026-66046), four HIGH findings, all fixable. The
  runtime stage now runs `apk upgrade --no-cache`, which closes the window without pinning
  a base tag that goes stale and without an allowlist entry — `.trivyignore.yaml` ships
  empty on purpose. **Take this one**: if you built from the v0.1.0 Dockerfile, the same
  gap is in your image.

---

## [0.1.0] — 2026-08-04

The initial extraction, published as three repositories. Everything below is the starting
state rather than a change from something; subsequent entries will read as changes.

### Added

**The Angular 21 + Nx workspace**

- Standalone components, signals, `OnPush`, strict TypeScript with no `any`, lazy routes,
  and library boundaries — `app → feature → shell/auth → data-access → shared/util` —
  declared as `scope:*` tags and enforced by `@nx/enforce-module-boundaries`, so breaking
  the direction fails lint rather than code review.
- PrimeNG as the only component library
  ([ADR-0001](docs/adr/0001-primeng-as-sole-component-library.md)), with one bounded
  exception recorded in
  [ADR-0005](docs/adr/0005-bespoke-whats-new-modal-as-a-primeng-exception.md).
- API types generated from the OpenAPI document rather than hand-written
  ([ADR-0002](docs/adr/0002-openapi-generated-frontend-types.md)). Hand-written server
  types on the client are a bug, not a shortcut.
- One place that talks HTTP: `libs/data-access/api-client` owns the interceptors, unwraps
  the `ApiResponse<T>` envelope centrally, and raises `ApiError` for everything that fails
  ([ADR-0003](docs/adr/0003-apiresponse-envelope-and-status-code-contract.md)). Feature
  code never touches `.data`.
- The hard client-side flows implemented rather than described: 401 session expiry, 403
  access-denied routing, 404, and the 409 stale-`rowVersion` conflict, all exercised
  end to end by the sample `libs/feature-items` slice.
- An offline demo configuration that swaps in MSW handlers and a role picker, so the whole
  app runs with no API and no identity provider.

**The "What's new" feature spotlight**

- A popup that shows each user a newly shipped feature exactly once, the first time they
  land on a URL prefix it is bound to. Acknowledgement is held per user by the API, so it
  survives cleared browser storage and other devices. Shipping the next announcement is a
  record the API adds and no client code at all. See
  [docs/whats-new.md](docs/whats-new.md).

**Container hosting**

- A `Dockerfile` that builds the static bundle and serves it from nginx, `nginx.conf` with
  a same-origin `/api` proxy, and `docker/40-env.sh`, which writes `public/env.js` at
  container start so one built image can be promoted through every environment. No real
  hostnames in any of them — you supply those at deploy time.

**The agentic harness**

- `.claude/` ships committed, not gitignored: hooks, slash commands, standards, agents, and
  templates, so every developer and every CI run gets identical guardrails.

**Quality gate**

- ESLint including the module-boundary rules, Prettier, a production AOT build as the real
  typecheck, Vitest with coverage, Playwright journeys with an `@axe-core/playwright`
  accessibility gate on critical routes, SonarQube Community Build (zero new
  Blocker/Critical/Major, ≥80% coverage on new code), Gitleaks, CodeQL, and `npm audit`.

**Process documentation**

- A five-stage workflow, a Definition of Done, a spec template, a Day-1 onboarding
  checklist, and an architecture guide that matches the code.

**Repository governance and toolchain** *(this release)*

- `LICENSE` — an explicit all-rights-reserved notice recording that the licence choice is
  pending. It grants and removes nothing; it replaces a guess with a statement.
- `CONTRIBUTING.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md`, `CODEOWNERS`, a pull-request
  template that embeds the Definition of Done checklist, and issue forms.
- **Conventional Commits**, enforced by `.claude/hooks/commit-msg.sh` in both git-hook and
  agent-hook mode, with a `COMMIT_MSG_SKIP=1` opt-out.
- `.gitattributes` — normalises line endings so a Windows clone does not break every shell
  hook with `bad interpreter`, which takes the whole harness offline silently.
- `.env.example` — every environment variable the repository reads, what it is for, and
  whether it is required.
- A `docker-compose.yml` that runs the built SPA container locally against the same
  `nginx.conf` proxy a deployment would use.
- `.vscode/extensions.json` and `settings.json`, matching `.editorconfig` and `.prettierrc`
  rather than competing with them.
- SonarQube configuration as a file rather than inline CI arguments, so a local scan and a
  CI scan analyse the same code under the same rules.
- `.github/dependabot.yml` covering npm, GitHub Actions, and Docker base images, grouped
  and weekly so it does not produce pull-request spam.
- `.github/workflows/supply-chain.yml` — builds the container image, scans it with Trivy,
  fails on fixable HIGH/CRITICAL, and publishes CycloneDX and SPDX SBOMs. Runs weekly as
  well as on change, because an image goes stale without a commit. The allowlist
  (`.trivyignore.yaml`) requires a justification and an expiry date, and CI fails when an
  entry outlives its date.
- `docs/incidents/` with a template and guidance, and `docs/upgrading.md` for consumers
  pulling improvements back into a diverged clone.
- The derivation that produces this repository from `aj-boilerplate-fs`, recorded in
  [ADR-0007](docs/adr/0007-scripted-one-way-derivation-for-the-three-repositories.md).

### Known limitations

Stated here rather than discovered later:

- **No licence is set.** Until `LICENSE` is replaced with a real one, no reuse rights are
  granted and outside contributions cannot be accepted.
- **Placeholders must be filled before this repository is useful to anyone else**: the
  CODEOWNERS handles, the `<owner>/<repo>` URLs in `SECURITY.md` and the issue-template
  config, the Code of Conduct enforcement contact, and the SonarQube project keys.
- **No pull-request decoration from SonarQube.** Community Build analyses one branch;
  findings appear on the dashboard and through the local pre-push hook, never as PR
  comments.
- **Derivation is not automatic.** This repository is regenerated from
  `aj-boilerplate-fs`, but three files still need a human on every run — `README.md`,
  `CLAUDE.md`, and the matrix-shaped workflow configuration — and nothing checks the
  published repositories for drift after the fact. A change made directly here is
  overwritten by the next derivation without a merge conflict to warn you.

[Unreleased]: https://github.com/<your-org>/aj-boilerplate-fe/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/<your-org>/aj-boilerplate-fe/releases/tag/v0.1.0

### Also in this first tag

Fixes made between writing the entries above and cutting the tag.

- **Dependency advisories cleared.** Angular moves to 21.2.19, which patches an
  HttpTransferCache cache-key ambiguity and two XSS advisories in packages that ship to the
  browser. Nx moves to 23.1.1, and `brace-expansion`, `postcss` and `undici` are pinned
  forward through `overrides`. `npm audit --audit-level=high` reports nothing.
- **Coverage was never produced.** The CI command passed `--coverageReporters`, valid on the
  Angular executor and invalid on `@nx/vite`, so it crashed exactly the two projects using
  the latter while the other six wrote reporters that do not include lcov. The reporter now
  lives in each project's own configuration, and `sonar.javascript.lcov.reportPaths` is a
  wildcard instead of a single path that never existed.
- **The page scrolled sideways on a phone.** The topbar is a flex row whose items cannot
  shrink below their content, so it grew past the viewport and took the document with it —
  43px of overflow at 320px, in both directions. It now wraps and the title truncates. The
  items table, wider than a phone by nature, gained the `.scroll` container `DESIGN.md`
  already required.
- Two `vitest.config.mts` files and one Playwright spec used `__dirname` in an ES module,
  which Vite tolerated before the upgrade and rejects now.
