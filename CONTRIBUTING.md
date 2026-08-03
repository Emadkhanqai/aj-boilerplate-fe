# Contributing

This repository ships its own guardrails, so contributing to it is mostly a matter of
letting them run. Read [docs/workflow.md](docs/workflow.md) for how a change moves through
the five stages, and [docs/definition-of-done.md](docs/definition-of-done.md) for what
"done" means here. This page is the mechanics: how to set up, what to run, what will block
you, and why.

A note on scope before anything else. This is a **domain-free boilerplate**. The most
common rejected contribution is a good feature that belongs in a product rather than here.
If a change only makes sense once you know what the application does, it belongs in your
clone.

---

## Setting up

**Prerequisites:** Node.js 22+, npm, and git. Docker only if you are changing the
container setup. That is the whole list.

```bash
git clone https://github.com/<your-org>/aj-boilerplate-fe.git
cd aj-boilerplate-fe

npm ci                                    # from the committed lockfile
npx nx serve web --configuration=demo     # http://localhost:4200
```

The `demo` configuration runs the whole app against MSW handlers with a built-in role
picker, so there is no API to stand up and no identity provider to configure. Drop the
`--configuration=demo` to point it at a real API instead; `README.md` covers the proxy and
the runtime configuration that needs.

`.env.example` documents every environment variable the repository reads and what each is
for — the runtime container settings and the local tooling ones. Copy it to `.env` if you
need any of them; nothing in the default development loop does.

### Install the git hooks

Two of the hooks in `.claude/hooks/` also work as git hooks and are not installed
automatically — a repository that installs hooks on clone is a repository that runs code
you have not read.

```bash
ln -s ../../.claude/hooks/secret-scan.sh .git/hooks/pre-commit
ln -s ../../.claude/hooks/commit-msg.sh  .git/hooks/commit-msg
```

The first blocks a commit containing something that looks like a credential. The second
enforces the commit convention below. Both are also wired as Claude Code hooks in
`.claude/settings.json`, so an agent-made commit is checked with or without the symlinks;
these two lines are what covers a commit you make by hand.

---

## Branch and pull-request flow

`main` is protected and always releasable. Everything else is a short-lived branch off it.

```bash
git switch -c feat/short-description        # or fix/…, docs/…, chore/…
```

Branch names are not enforced by anything. The prefix matching the Conventional Commits
type is a convention because it makes `git branch --list` readable, not because a hook
cares.

1. **Spec first for anything non-trivial.** `docs/specs/TEMPLATE.md`, approved by a human
   before implementation starts. A bug fix does not need one; a feature does.
2. **Failing test first.** A test that has never been observed failing has not been shown
   to test anything — that sentence is in the Definition of Done and it is meant literally.
3. **Keep the diff small.** A pull request that changes the harness and the application in
   one commit is one that cannot be cherry-picked by a consumer later, which matters more
   in a boilerplate than in a product. See [docs/upgrading.md](docs/upgrading.md).
4. **Open the pull request.** The template fills in automatically and embeds the Definition
   of Done checklist. It is not decoration: a reviewer will ask for the evidence it asks
   for.
5. **Green gate, then human review.** In that order, and both. An agent-written change gets
   more scrutiny, not less — it is fluent and confident, which makes a wrong approach look
   like a right one. Whoever prompted it owns every line and must be able to explain it.
6. **Squash on merge.** One commit per pull request on `main`, with a Conventional Commit
   subject, because the changelog is assembled from that history.

---

## The quality gate

Everything below must pass before a pull request can merge. None of it is advisory.

| Gate | What runs |
|---|---|
| Build | `nx build web --configuration=production` — the AOT compile is the real typecheck |
| Format | Prettier |
| Lint | ESLint, including the Nx tag rules |
| Library boundaries | `@nx/enforce-module-boundaries` — `app → feature → shell/auth → data-access → shared/util`, enforced as lint, not as review |
| Unit tests | `nx affected -t test --coverage` (Vitest + Testing Library) |
| End to end | Playwright, plus the `@axe-core/playwright` accessibility gate on critical routes |
| Static analysis | SonarQube, CodeQL |
| Dependencies | `npm audit --audit-level=high` |
| Secrets | Gitleaks |
| Image | Trivy + SBOM (`.github/workflows/supply-chain.yml`) |

The SonarQube conditions specifically: **zero new Blocker, Critical, or Major findings**
and **at least 80% coverage on new code**. Minor and Info may be triaged, with the triage
recorded.

Run it locally before you push:

```bash
npx nx affected -t lint,test,build
npx nx e2e web-e2e
```

Or `/pre-push`, which runs the lot and reports readiness without pushing.

### Two things about SonarQube that will otherwise confuse you

This targets **SonarQube Community Build**, which analyses exactly one branch: the
default one. Consequently the scanner runs only on pushes to `main`, and **there is no
pull-request decoration** — Sonar findings never appear as PR comments. Branch analysis
and PR decoration start at Developer Edition and this boilerplate deliberately does not
depend on them.

What covers the gap is `.claude/hooks/sonar-pre-push.sh`, which blocks a push while any
Blocker, Critical, or Major is open on the project. It **fails closed**: with SonarQube
unreachable or unconfigured, the gate has not passed, so the push is blocked. Configure
`SONAR_HOST_URL` and `SONAR_TOKEN` (see `.env.example`), or use `SONAR_GATE_SKIP=1` — which
is a tech-lead decision and must be recorded in the pull request, not a way around a
Tuesday afternoon.

Analysis settings live in `sonar-project.properties`, and both the hook and CI read that
same file. That is what makes a local scan and a CI scan agree.

---

## Commit convention

**[Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/)**, enforced
by `.claude/hooks/commit-msg.sh`. It blocks rather than warns, because the commit history
is an input to the release process — the changelog is assembled from it and the version
bump is derived from the types present. A history that is 90% conventional is worse than
none: it looks parseable, so somebody writes a parser, and the parser is wrong about the
rest.

```
<type>[optional scope][!]: <subject>

[optional body]

[optional footer(s)]
```

| Type | Use it for | Release effect |
|---|---|---|
| `feat` | A new capability | minor |
| `fix` | A defect corrected | patch |
| `docs` | Documentation only | none |
| `style` | Formatting with no behaviour change | none |
| `refactor` | Neither fixes a bug nor adds a feature | none |
| `perf` | A performance improvement | patch |
| `test` | Tests only | none |
| `build` | Build system or dependencies | none |
| `ci` | CI configuration and workflows | none |
| `chore` | Everything else with no source effect | none |
| `revert` | Reverts a previous commit | context-dependent |

**Scope** is optional and free-form; use the part of the workspace that changed — `web`,
`ui`, `shell`, `auth`, `data-access`, `harness`, `deps`.

**Breaking changes** are marked with `!` after the type or scope, or with a
`BREAKING CHANGE:` footer, and drive a major version bump. In a boilerplate a breaking
change is anything a consumer who cloned last month would have to react to: a renamed
library, a changed public export from `libs/*`, a changed Nx tag or boundary rule, a
removed hook, a moved configuration file.

**Rules the hook checks:** a known type, a colon and exactly one space, a non-empty
subject, no trailing full stop, a header of 100 characters or fewer, and a blank line
before any body. It also rejects subjects that say nothing (`fix: bug`, `chore: stuff`).
Merge, revert, and fixup messages that git generates are left alone.

```
feat(ui): show the stale-rowVersion conflict as a recoverable banner
fix(web): stop the items grid refetching on every keystroke
refactor(auth)!: rename SessionService.current to SessionService.user
docs: record the three-repository sync mechanism in ADR-0007
ci: scan the container image and publish an SBOM
```

Genuinely stuck with a message you do not control — an automated merge, a tooling-generated
revert? `COMMIT_MSG_SKIP=1 git commit …`. It is not for "I will tidy it up later"; in
practice the history is append-only and you will not.

---

## How the `.claude/` harness fits in

`.claude/` ships **committed, not gitignored**, so every developer and every CI run gets
identical guardrails. The `.gitignore` says so at the top, in capitals, with the single
exception of `.claude/settings.local.json`. Do not add anything under `.claude/` to
`.gitignore`.

The distinction that matters is between prose and enforcement:

- **`.claude/standards/`, `commands/`, `agents/`, `templates/` are prose.** An agent reads
  them, usually follows them, and occasionally does not.
- **`.claude/hooks/` and `.claude/settings.json` are deterministic.** They fire every time,
  identically, and a `PreToolUse` hook can refuse a tool call before it happens.

Which is why a rule worth enforcing goes in a hook, not only in a document.

| Hook | Fires on | What it does |
|---|---|---|
| `model-routing.sh` | prompt submit | Classifies the task and recommends a model tier |
| `block-dangerous.sh` | before Bash | Refuses destructive commands outright |
| `commit-msg.sh` | before Bash, and as a git hook | Enforces Conventional Commits |
| `sonar-pre-push.sh` | before Bash | Blocks a push while the quality gate is failing |
| `protect-files.sh` | before Edit/Write | Refuses edits to protected paths |
| `auto-format.sh` | after Edit/Write | Formats what was just written |
| `secret-scan.sh` | after Edit/Write, and as a pre-commit hook | Blocks credentials reaching a file |
| `run-affected-tests.sh` | after Edit/Write | Runs the tests the change touched |

### Contributing to the harness

Changes to `.claude/` are the highest-leverage and highest-risk contributions here: they
change how every future change is made, in three repositories.

- **A new hook must fail safe and be testable from the command line.** Every existing hook
  reads its input from stdin or from `$1` and can be exercised without an agent. Copy that
  idiom — `secret-scan.sh` and `commit-msg.sh` are the two dual-mode examples.
- **Exit 2 blocks; exit 0 allows.** Anything else is a bug in the hook.
- **Every hook that blocks needs a documented opt-out** with a name matching the existing
  ones (`SONAR_GATE_SKIP`, `COMMIT_MSG_SKIP`), and the opt-out must be loud when used. A
  gate with no escape hatch gets disabled wholesale the first time it is wrong.
- **Document it in `.env.example` section 10 and in the table above** in the same pull
  request.
- **Never edit `.claude/settings.json`'s `extraKnownMarketplaces` or `enabledPlugins`**
  as a side effect of another change.

---

## Architecture decisions

Write an ADR when a decision is expensive to reverse, crosses team or layer boundaries,
constrains future work, or will provoke "why on earth is it like this?" from someone who
was not there. Do not write one for a choice a single pull request can undo.

Copy `docs/adr/TEMPLATE.md` to `docs/adr/NNNN-short-slug.md` using the next free number,
and update the index in [docs/adr/README.md](docs/adr/README.md) in the same pull request.
Never edit an accepted ADR to reflect a new decision — write a new one that supersedes it.

An ADR with no negative consequences has not been thought about.

---

## Incidents

If something broke in a deployed environment, write it up:
[docs/incidents/README.md](docs/incidents/README.md) says when, and
`docs/incidents/TEMPLATE.md` says how. It is blameless and it is a search index for future
pain, not a compliance artefact.

---

## Releasing, and the three repositories

Read this before you open a pull request against this repository, because it changes where
your change should go.

The boilerplate is published as three repositories — `aj-boilerplate-fs` (the source of
truth, both stacks in one tree), `aj-boilerplate-be`, and `aj-boilerplate-fe` (this one).
**All work originates in `aj-boilerplate-fs`.** The single-stack repositories are outputs,
regenerated wholesale by a derivation script that lives there; a change made directly here
is overwritten by the next derivation, silently and without a merge conflict to warn you.

So: fix it in `aj-boilerplate-fs`, and it arrives here on the next release. What is worth
opening here is an issue — a defect that is only visible in the derived shape (a path that
did not survive promotion to the root, a reference to a file that was dropped) is exactly
the kind of bug the derivation is prone to and the kind nobody sees in the full-stack tree.

The release and tagging convention is in [CHANGELOG.md](CHANGELOG.md). **The three
repositories share a version number** — a tag here is the same content as that tag in the
other two. The background is
[ADR-0004](docs/adr/0004-three-repository-split.md) and
[ADR-0007](docs/adr/0007-scripted-one-way-derivation-for-the-three-repositories.md).

---

## Reporting problems

- **A bug or a feature idea** — open an issue; the forms ask for what a maintainer will
  need anyway.
- **A security vulnerability** — do not open an issue. [SECURITY.md](SECURITY.md) explains
  the private reporting path.
- **Behaviour in the community** — [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md). Note that its
  enforcement contact is an unfilled placeholder until the repository owner sets one.

## Licensing of contributions

There is no licence on this repository yet — see [LICENSE](LICENSE), which records that
the position is all-rights-reserved and that the choice is pending a decision that is not
an engineer's to make. **Until that is resolved, outside contributions cannot be accepted**,
because there are no terms to accept them under. This is not a judgement about the
contribution; it is that nobody here is in a position to grant or receive rights. If you
have something to contribute, open an issue describing it and it can be revisited once the
licence is settled.
