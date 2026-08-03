# ADR-0005: The "What's new" modal is bespoke markup and CSS — a single, bounded exception to PrimeNG-only

**Status:** Accepted
**Date:** 2026-08-03
**Deciders:** Boilerplate maintainers
**Supersedes:** —

---

## Context

[ADR-0001](0001-primeng-as-sole-component-library.md) makes PrimeNG the only component library and
bans native form controls outright, and it says why the rule is absolute rather than a default: a
default is what produces four kinds of dropdown. `DESIGN.md` §6 carries the same rule, and adds a
second one — visual values live in `tokens.css`, `components.css`, and `app-preset.ts`, and a
colour hard-coded in a component is a bug.

The "What's new" feature spotlight (`libs/shared/ui/src/lib/whats-new-modal/`) is the first thing
built here that those two rules cannot accommodate, and it is worth being precise about why,
because "the rule was inconvenient" is not a reason.

The component is a marketing surface, not product chrome. Its job is to feel like an interruption
— a one-off, celebratory panel that a user sees once and then never again. Concretely, the design
is:

- a gradient hero band, layering two radial gradients over a linear one, with a bouncing spotlight
  glyph and eight absolutely-positioned confetti elements bounded by `overflow: hidden`;
- a blurred backdrop (`backdrop-filter: blur(6px)`) over the whole viewport;
- benefit cards that cycle through five gradient tints;
- seven keyframe animations;
- a full-height bottom-sheet treatment below 480px.

None of that is expressible through PrimeNG's `p-dialog`. `p-dialog` gives a themed chrome — a
header bar, a content region, a footer — driven by the same design tokens as the rest of the
application. That is exactly its value everywhere else, and exactly the problem here: the theme
layer's job is to make things look like the product, and this panel must not. Building on it would
have meant overriding its header, its content padding, its mask, and its close affordance, which
is not "using PrimeNG" in any sense that ADR-0001 was defending — it is fighting a component to
produce something it was designed not to be, and shipping the override CSS anyway.

Three specific behaviours would have been lost or fought for:

1. **The gradient hero band.** `p-dialog`'s header is a themed bar. Replacing its background with
   a multi-layer gradient, removing its border, and letting decorative elements overflow into it
   means overriding the parts of the component that make it a `p-dialog`.
2. **The backdrop blur.** `p-dialog`'s mask is themed as a flat scrim. Blurring it is a global
   override, and a global override to serve one component is worse than a local stylesheet.
3. **The deliberately inert backdrop.** `p-dialog` treats a mask click as a dismissal — that is
   correct default behaviour and it is what we want everywhere else. Here it is wrong: dismissing
   writes a permanent, per-user, cross-device acknowledgement, so it must be a considered action.
   `[dismissableMask]="false"` gets close, but the point is that this component's dismissal
   semantics are not a dialog's, and modelling them as a dialog's-with-a-flag understates it.

There is also a mechanical consequence. `apps/web/project.json` set the `anyComponentStyle` budget
at 4 kB warning / 8 kB error, precisely to flag a component accumulating too much bespoke CSS.
This component's stylesheet minifies to roughly 7.8 kB. The budget was not wrong; it was
correctly identifying a component with a lot of bespoke CSS in it.

## Decision

We will keep the "What's new" modal as bespoke markup with its own component stylesheet, as a
**named, bounded exception** to PrimeNG-only and to token-driven styling — and we will not
generalise it.

What is in scope:

- **Markup.** The component uses plain `<div>`, `<button>`, and `<footer>` elements rather than
  PrimeNG components. `p-button` is not used for "Got it", "Next", "Previous", the close control,
  or the pagination dots.
- **Styling.** Literal colour values, gradients, and keyframes live in
  `libs/shared/ui/src/lib/whats-new-modal/whats-new-modal.css` rather than in `tokens.css` or
  `components.css`. This is the intended outcome, not a shortcut: this palette is one-off by
  design, and admitting it to the shared token set would make the product's tokens describe
  something no product surface uses.
- **The style budget.** `apps/web/project.json`'s `anyComponentStyle` budget is raised from
  4 kB / 8 kB to **10 kB / 14 kB** to accommodate it — in two steps, see Consequences.

What is explicitly **not** in scope:

- **Icons.** The three glyphs it needs come from PrimeIcons (`pi pi-times`, `pi pi-arrow-left`,
  `pi pi-arrow-right`). No second icon set, no hand-drawn chevrons.
- **Accessibility.** The exception buys visual freedom and nothing else. Because PrimeNG is not
  there to supply them, the component carries `role="dialog"`, `aria-modal="true"`,
  `aria-labelledby`, an `aria-label` on the close button, and `role="tab"` / `aria-selected` on the
  pagination dots itself. It is held to the same axe-green standard as everything else.
- **Every other component.** The exception names one directory. It is not a category.

Enforcement is documentation plus review, not a lint rule: the exception is recorded in the
component's own class comment, in `libs/shared/ui/README.md`, in `CLAUDE.md`, in `DESIGN.md` §6,
and here. A second bespoke component arriving without its own ADR is the thing review is looking
for.

## Consequences

### Positive

- The announcement surface reads as an announcement. It does not look like the rest of the app,
  which is the entire point of it, and it achieved that without a single override leaking into the
  shared theme.
- No global overrides. Everything unusual is scoped to one component's stylesheet, so nothing
  about this component can change how a `p-dialog` looks anywhere else.
- The dismissal semantics are stated in the component that owns them, rather than encoded as a
  configuration flag on a component whose defaults mean something different.
- The rule survives being tested. An exception argued in writing, with a boundary and an ADR, is
  materially different from a rule that quietly stopped being followed — and it gives the next
  person a standard to be held to.

### Negative

- **There are now two styling idioms in the workspace**, and someone will find the second one
  first. A developer reading `whats-new-modal.css` before reading `DESIGN.md` learns the wrong
  lesson about how this codebase styles things.
- **The style budget is looser than it was, and was raised twice.** At 10 kB / 14 kB it will no
  longer catch a component that grows to 6 kB of bespoke CSS — exactly what the original 4 kB
  warning existed to surface early. We have traded that early warning away. The second raise is
  worth remembering: 8 kB had been set flush against a stylesheet minifying to ~7.8 kB, so adding
  the `prefers-reduced-motion` block this component was missing exceeded it by ten bytes. A ceiling
  set to hug today's size is a tripwire, not a budget — it forces a choice between shaving
  semantic CSS and moving the number, and shaving loses.
- **The exception is precedent-shaped whether we like it or not.** "There is already one" is the
  opening argument for the second, and refusing it will cost an actual conversation.
- **PrimeNG's maintenance is not inherited here.** When PrimeNG ships an accessibility or
  browser-compatibility fix in `p-dialog`, this component does not get it. Its focus handling, its
  ARIA wiring, and its mobile behaviour are ours to keep working.
- Its seven animations shipped without honouring `prefers-reduced-motion`, which a themed PrimeNG
  component would have handled for us. They now do, via a `@media (prefers-reduced-motion: reduce)`
  block. Treat that as the standing cost of this decision rather than a closed item: every
  affordance a component library would have supplied here is one somebody has to remember to
  build, and this one was missed until it was audited against `DESIGN.md` §8.

### Neutral

- `libs/shared/ui` now contains one component that does not follow the library's own stated rules,
  and its README has to say so before the table of components stops being trustworthy.
- Reviewers need a shared answer to "why is this one different?", which is what this file is.

### Follow-on work

- The ESLint rule flagging native control elements, already listed as follow-on work in
  [ADR-0001](0001-primeng-as-sole-component-library.md), needs a path-scoped exemption for this
  directory when it is written — an exemption that is itself the enforcement of this ADR's
  boundary.
- If a second component ever needs this treatment, it gets its own ADR arguing its own case. It
  does not inherit this one.

## Alternatives considered

### Build it on `p-dialog` and theme it

The orthodox answer, and the one ADR-0001 points at. Rejected on what it would have cost: the
gradient hero band, the backdrop blur, and the inert backdrop each require overriding a part of
`p-dialog` that is the reason to use `p-dialog`. The end state would have been a themed component
plus a comparable volume of override CSS defeating the theme — the same bespoke stylesheet, minus
the honesty about it, plus a dependency on internals that a PrimeNG major upgrade can move.

### Promote the modal's palette into `tokens.css`

Would have kept the token rule intact. Rejected because it inverts the meaning of the token set.
`tokens.css` describes the product's visual language; these gradients exist specifically to *not*
be that language. Adding `--wn-hero-gradient-start` to the shared tokens makes the shared tokens a
grab bag and offers every future component a colour it must not use.

### Drop the ornamentation and ship a plain themed dialog

Cheapest option, and a legitimate product decision — but it is a different product decision, not
an implementation of this one. A spotlight that looks like every other dialog is not read as a
spotlight; it is read as an interruption to dismiss, which is the outcome the feature exists to
avoid. If the product later decides the ornamentation is not worth it, that is a new ADR
superseding this one, and it deletes the exception cleanly.

### Add a second component or animation library for this surface

Rejected on ADR-0001's own reasoning, which applies with full force. One bespoke component is a
bounded cost; a second supplier in `package.json` is a permanent one, and it would be a far larger
breach than the one taken here.

### Doing nothing — refuse the exception, do not ship the feature

Real, and briefly considered. Rejected because the constraint being enforced would have been a
styling rule, and the thing sacrificed would have been a shipped feature. A rule that blocks
working software with no better alternative on offer is a rule that has stopped paying for itself;
the correct response is a written exception with a boundary, which is this document.

## Verification

The decision is being honoured while all four of these hold:

- `libs/shared/ui/src/lib/whats-new-modal/` is the **only** place outside `apps/web/src/design/`
  and `apps/web/src/styles/` carrying literal colour values. Today this returns exactly two files
  — that component's `.css` and the inline SVG in its `.html`:

  ```bash
  grep -rIlE '#[0-9a-fA-F]{3,8}\b' libs/*/src libs/*/*/src apps/web/src/app
  ```

  Any third file in that output is either a violation of `DESIGN.md` §6 or a second exception that
  needs its own ADR.
- `apps/web/project.json`'s `anyComponentStyle` budget is still 10 kB / 14 kB, and
  `npx nx build web` reports no budget warning. A second component approaching the ceiling is the
  signal to question that component, not to raise the budget.
- `npx nx e2e web-e2e` stays axe-green with no rules disabled — the accessibility carve-out that
  this ADR explicitly refused.
- `package.json` still lists exactly one UI component library.

The signal that should trigger a superseding ADR is a **second** request for bespoke markup. If
one arrives and is granted, the honest conclusion is that PrimeNG-only has become PrimeNG-mostly,
and ADR-0001 should be rewritten to say so rather than accumulating exceptions beneath it.

## References

- [ADR-0001](0001-primeng-as-sole-component-library.md) — the rule this bounds an exception to
- [`DESIGN.md`](../../DESIGN.md) §6 (the exception and the raised budget) and §8 (the
  reduced-motion gap)
- [`libs/shared/ui/README.md`](../../libs/shared/ui/README.md) — the exception at library level
- [`docs/whats-new.md`](../whats-new.md) — how the module is wired and how announcements are
  authored
- `libs/shared/ui/src/lib/whats-new-modal/whats-new-modal.ts` — the class comment stating the
  exception at the point of use
