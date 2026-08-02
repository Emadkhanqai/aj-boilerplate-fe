# ADR-0004: Publish as three repositories, of which this is the frontend one

**Status:** Accepted
**Date:** 2026-08-02
**Deciders:** Boilerplate maintainers

---

## Context

Not every project needs both halves of a web product. A team building a service with no web UI
should not clone an Angular workspace, run `npm ci`, and then delete it. A team building a
frontend against an existing API — the situation this repository is for — should not inherit a
server solution, a migration workflow, and database infrastructure it will never run. Extra
directories are not free: they slow CI, appear in searches, confuse newcomers about what is in
scope, and get half-maintained.

At the same time, the shared parts — the `.claude/` harness, the process documentation, the
ignore rules — must not fork. If this repository's hooks drift from the full-stack repository's
hooks, the boilerplate has stopped being one thing.

## Decision

The boilerplate is published as three repositories, and **this is the frontend one**:

| Repository | Contents |
|---|---|
| `aj-boilerplate-fs` | The source of truth — API and web app together, plus infrastructure, docs, and harness |
| `aj-boilerplate-be` | The API only, at the repository root; backend CI only |
| `aj-boilerplate-fe` | **This repository** — <https://github.com/Emadkhanqai/aj-boilerplate-fe> — the Angular/Nx workspace at the root; frontend CI only |

**Where the backend is.** This repository contains no server code, by design. The API this app
talks to lives in `aj-boilerplate-be`; the combined tree, where a change can span both sides in
one commit, is `aj-boilerplate-fs`. If you need to change an endpoint rather than consume one,
that work happens there, not here — see
[docs/api/README.md](../api/README.md) for what that means in practice.

Derivation rules:

- **Shared verbatim** across all three: `.claude/`, `.mcp.json`, `.gitignore`, `.editorconfig`,
  and the stack-neutral pages of `docs/`.
- **This repository** ships the Nx workspace promoted to the repository root — `package.json`,
  `nx.json`, `apps/`, and `libs/` are top-level, with no nesting to navigate — plus
  `frontend-ci.yml` as the only CI workflow. It carries no server projects, no migration
  tooling, and no infrastructure definitions.
- The API contract arrives here as an OpenAPI document, not as source. Types are generated from
  it under [ADR-0002](0002-openapi-generated-frontend-types.md), and `--configuration=demo` runs
  the whole app against MSW mocks so a frontend developer is never blocked on the API being up.
- **Documentation is written stack-scoped**, one page per stack rather than one page covering
  both, precisely so derivation is a matter of deleting whole files rather than editing
  paragraphs. This constraint shapes how `docs/` is organised.
- Changes are made in `aj-boilerplate-fs` first and propagated outward. The single-stack repos
  are outputs, not places to originate boilerplate work — though a project that *clones* this one
  obviously owns its copy outright.
- No shared git history. Each repository starts fresh; history in the source project is not
  carried over.

## Consequences

### Positive

- This repository is exactly as large as a frontend project needs, and its CI runs only the gates
  that apply to a frontend: lint, typecheck, unit tests, production build, `npm audit`,
  Playwright with axe, secret scanning, and code scanning.
- A frontend team never sees a backend failure, and vice versa. Signal stays high.
- Cloning is trivial and the first command is `npm ci`, with nothing to skip past.
- Stack-scoped documentation is better documentation anyway — a page that hedges "on the
  backend… meanwhile on the frontend…" is harder to read even in the full-stack repo.

### Negative

- Three repositories must be kept in sync, and there is no mechanism enforcing it. Drift is the
  standing risk of this decision and it will happen if propagation is not deliberate.
- A change to a shared file is three pull requests, or one scripted propagation that someone has
  to write and maintain.
- A change that spans the contract cannot be made or reviewed in one place from here. It is two
  pull requests in two repositories, in the right order, or one in `aj-boilerplate-fs`.
- Consumers who start frontend-only and later need an API face a merge rather than an addition.
- Issues and discussions fragment across three trackers.

### Neutral

- Losing git history is a real loss of context, accepted because the source tree's history
  contains business content that cannot be published — the same reason this boilerplate exists as
  an extraction rather than a fork.
- Derivation must be re-run on every release, so it should be scripted rather than manual.

### Follow-on work

- A derivation script (delete paths, promote a subtree, merge the nested `CLAUDE.md`) run as part
  of releasing a new version, so propagation is mechanical.
- A drift check comparing the shared files across the three repositories.

## Alternatives considered

### One full-stack repository only

Zero drift, one place to change anything. Rejected because it forces every consumer to carry a
stack they may not want, and "just delete the folder you don't need" leaves dangling CI, dead
documentation links, and ignore rules for paths that no longer exist.

### Git submodules or a subtree for the shared parts

Real sharing with real history. Rejected: submodules are a well-known source of confusion for
newcomers, and a boilerplate's whole value proposition is that cloning it is trivial.

### Template repository with generation-time options

The most flexible option, and the right one at a larger scale. Rejected as disproportionate — it
requires building and maintaining a generator, which is a bigger project than the boilerplate it
would generate.

### One repository with three branches

Rejected. Long-lived divergent branches are the worst of both worlds: they drift like separate
repositories while looking like one.

## Verification

Cross-contamination check before each release: no server path in `aj-boilerplate-fe`, no frontend
path in `aj-boilerplate-be`, and the shared files byte-identical across all three. Every internal
documentation link in this repository resolves within this repository — a link that only works in
the full-stack tree is a derivation bug.

## References

- [README.md](../../README.md) — what this repository is and how to run it
- [ADR-0002](0002-openapi-generated-frontend-types.md) — how the contract reaches this repository without the API's source
- [docs/api/README.md](../api/README.md) — the API this app consumes
