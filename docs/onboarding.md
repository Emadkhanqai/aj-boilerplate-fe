# Day-1 onboarding

Welcome. This is one day's work, in order. Do not skip ahead — step 4 is a checkpoint, not a
formality, and the point of step 5 is to have shipped something small before you are asked to
ship something large.

By the end of the day you will have a green gate on your machine and one merged change.

This repository is the **frontend**: an Angular 21 + Nx + PrimeNG workspace at the repository
root. There is no server code here. The API it talks to is a separate service, and you will not
need it running today — [ADR-0004](adr/0004-three-repository-split.md) explains that split.

---

## 1. Install and authenticate Claude Code

```bash
npm install -g @anthropic-ai/claude-code
claude          # follow the prompts to authenticate
claude --version
```

This repository is designed to be driven with Claude Code. Everything here works without it — the
commands are ordinary `npm` and `nx` commands — but the guardrails in
[`.claude/`](../.claude/README.md) only apply when you are using it.

### Plugins

The harness depends on a set of published plugins. `.claude/settings.json` declares them, so an
interactive session in this repository will offer to install them on first run. Accept.

If you would rather do it explicitly, or the prompt did not appear:

```bash
# inside an interactive `claude` session, in the repository root
/plugin marketplace add obra/superpowers
/plugin marketplace add anthropics/skills
/plugin marketplace add wshobson/agents
/plugin marketplace add multica-ai/andrej-karpathy-skills
/plugin marketplace add mattpocock/skills

/plugin              # browse and install from the marketplaces you just added
```

Verify with `/plugin` — the installed plugins should be listed and enabled. If a marketplace fails
to add, check that `git` can reach GitHub from your machine before debugging anything else.

---

## 2. Clone, install, and run it offline

**Prerequisites:** Node.js 22+ and npm. That is the whole list — no database, no API, no
container runtime.

```bash
git clone https://github.com/<your-org>/<this-repo>.git
cd <this-repo>

npm ci                                    # the committed lockfile, exactly
npx nx serve web --configuration=demo     # offline: MSW-mocked API, no backend needed
```

Open <http://localhost:4200>.

The `demo` configuration serves the whole app against the MSW handlers in `apps/web/src/mocks`,
and ships a role picker instead of a real identity provider — pick any of the sample users. You
can build, test, and review real features in this mode indefinitely.

When you do have an API to point at, `npx nx serve web` (no `--configuration`) sends requests to
relative `/api/v1/...` paths instead; proxy those to your API. See
[docs/api/README.md](api/README.md) for the contract and for regenerating the types.

---

## 3. Exercise the sample slice

`libs/feature-items` is a complete worked example — list, form, optimistic concurrency,
all four view states — and it is meant to be read, copied, and then deleted. In the browser:

1. **List.** Page through the items, search, and sort. Note the loading skeleton and what happens
   when a search returns nothing: an empty state that says *why* and offers the primary action.
2. **Create.** Add an item. Leave the name blank first and watch the client-side validation fire
   on the right control — and note that the mock API rejects the same thing with `400` /
   `VALIDATION_ERROR`, because the client's validation is a convenience and the API's is the
   actual rule.
3. **Edit and conflict.** Open the same item in two browser tabs, save in one, then save in the
   other. The second save carries a stale `rowVersion` and comes back `409`: you should get
   "someone else changed this" and an offer to reload, never a silent overwrite. This is the
   single most important behaviour in the app; see
   [ADR-0003](adr/0003-apiresponse-envelope-and-status-code-contract.md).
4. **Delete.** Confirm the destructive-action dialog and the toast that follows.

Then read the code behind what you just clicked, in this order: `item-list-page`,
`item-form-page`, then `libs/data-access/api-client`. Seeing it work end to end now means that
when something breaks later, you know it is you.

---

## 4. Read the context files

In this order:

1. **[`CLAUDE.md`](../CLAUDE.md)** at the repository root — the stack, the layout, the enforced
   import direction, the commands, and the non-negotiable rules. Read it properly. It is short on
   purpose.
2. **[`DESIGN.md`](../DESIGN.md)** — the visual contract: tokens, spacing, states. Read it before
   you write any UI, and fill it in for your project before you write much.
3. **[`docs/architecture.md`](architecture.md)** — how the workspace is put together and why the
   library boundaries are where they are.
4. **[`.claude/standards/`](../.claude/standards/angular.md)** — skim the set, then read in full
   whichever standards cover what you are about to touch. Start with
   [`angular.md`](../.claude/standards/angular.md) and
   [`typescript.md`](../.claude/standards/typescript.md).

Note the hard rule while you are there: **never put a secret, connection string, token, or
credential in `CLAUDE.md`, in a prompt, or in any other context file. Ever.**

---

## 5. Get a green gate locally

Before you change anything, prove the baseline works on your machine.

```bash
/qa
```

Or the underlying commands, if you prefer to see them:

```bash
npx nx run-many -t lint --all         # includes the module-boundary rules
npm run typecheck
npx nx run-many -t test --all
npx nx build web --configuration=production
npx nx e2e web-e2e                    # Playwright journeys + axe; boots the demo build itself
npm audit --audit-level=high
```

**Everything must be green before you write a line of code.** If it is not, that is today's first
task and your tech lead wants to know — a broken baseline on a new machine is usually a missing
prerequisite, and it is worth fixing in the setup documentation for the next person.

The same gates run in CI ([`.github/workflows/frontend-ci.yml`](../.github/workflows/frontend-ci.yml)),
so a green local run is a good predictor of a green pull request.

---

## 6. Ship one small change, end to end

Pick something genuinely small with your tech lead — a validation message, a missing empty state,
a column on an existing table. Then take it through
[all five stages](workflow.md): **Spec → Plan → Execute → Verify → Review**.

- Write the spec from [the template](specs/TEMPLATE.md), even though the change is tiny. The
  point is the habit.
- Write the failing test first, and watch it fail.
- Handle all four view states, keyboard included. A missing error state is not a follow-up ticket.
- Run the full gate and paste the output into the pull request.
- Your tech lead pair-reviews it with you — walking through the code together, not approving it
  asynchronously. This review is the actual onboarding; the rest is setup.

Meet [the Definition of Done](definition-of-done.md), every condition, on this change. It is much
easier to learn the bar on something small.

---

## 7. Read the ADRs and the spec template

```bash
ls docs/adr/
```

Read all four [ADRs](adr/README.md). They tell you what was decided, why, and what was rejected —
which is the context that stops you from re-proposing an alternative the team already ruled out.
Two of them will come up in your first week: PrimeNG-only
([ADR-0001](adr/0001-primeng-as-sole-component-library.md)) and generated API types
([ADR-0002](adr/0002-openapi-generated-frontend-types.md)).

Then read [the spec template](specs/TEMPLATE.md) end to end, including the guidance blockquotes.
It is the shape of every piece of work you will be asked to do here.

---

## Checklist

- [ ] Claude Code installed, authenticated, plugins enabled
- [ ] Repository cloned, `npm ci` clean, `npx nx serve web --configuration=demo` running
- [ ] Sample Items slice exercised in the browser, including the `409` conflict path
- [ ] `CLAUDE.md`, `DESIGN.md`, `docs/architecture.md`, and the relevant standards read
- [ ] `/qa` green locally — lint, typecheck, tests, production build, e2e, audit
- [ ] One small change shipped through all five stages, pair-reviewed by the tech lead
- [ ] All four ADRs read
- [ ] Spec template read

---

## Where to ask

Ask early. A question that takes someone five minutes to answer is cheaper than a day spent
guessing, and the things that are obvious to the team are exactly the things nobody remembered to
write down.

| Topic | Look here first |
|---|---|
| How do I build/run/test X? | [`CLAUDE.md`](../CLAUDE.md) |
| How is the workspace laid out? | [`docs/architecture.md`](architecture.md) |
| Why is it built this way? | [`docs/adr/`](adr/README.md) |
| What should it look like? | [`DESIGN.md`](../DESIGN.md) |
| What is the process? | [`docs/workflow.md`](workflow.md) |
| When can I merge? | [`docs/definition-of-done.md`](definition-of-done.md) |
| What does the API guarantee? | [`docs/api/README.md`](api/README.md) |
| What are the coding standards? | [`.claude/standards/`](../.claude/standards/angular.md) |
| What happened in the last session? | [`docs/handoff/`](handoff/README.md) |
