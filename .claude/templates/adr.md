# ADR-<NNN>: <Title>

Copy this to `docs/adr/<NNN>-<short-title>.md`.

- **Status:** Proposed | Accepted | Superseded by ADR-<NNN>
- **Date:** <YYYY-MM-DD>
- **Deciders:** <names/roles>

## Context

What problem or decision is this? What constraints apply — the spec in `docs/specs/`, the
standards in `.claude/standards/`, and the non-negotiable rules (push approval, the SonarQube
gate, generated-only API types)?

State the forces honestly, including the ones pulling the other way.

## Decision

The choice made, stated plainly in one or two sentences. Present tense, active voice:
"We use X." Not "It was decided that X might be used."

## Consequences

Positive, negative, and follow-ups. What this **locks in**, what it **leaves open**, and what
becomes harder. An ADR with only positive consequences has not been thought through.

## Alternatives considered

| Option | Why rejected |
|---|---|
| <option> | <reason> |

---

**Write an ADR when:** adopting or dropping a dependency, introducing a global store, absorbing
a breaking change from the upstream API contract, or changing the role/capability model. If you
find yourself explaining a past decision twice, it needed an ADR.
