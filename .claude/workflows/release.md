# Workflow: Release

> **Model routing (do first):** see [`../model-routing.md`](../model-routing.md). Release
> *mechanics* → workhorse tier; the go/no-go *risk call* → frontier tier.

Shipping the built SPA to an environment. Nothing here bypasses the approval or SonarQube
rules.

## 0. Preconditions

- The feature and API-sync workflows are complete; the branch is up to date.
- Every non-negotiable rule is satisfied: explicit push approval, a green SonarQube gate, no
  secrets, generated API types current with the upstream OpenAPI document.

## 1. Full verification

Run [`pre-push-quality-gate.md`](pre-push-quality-gate.md) end to end. If SonarQube reports any
**Blocker / Critical / Major**: stop → fix → rerun the scanner → repeat until clean. Minor and
Info may be triaged.

## 2. Summarise & request approval

Provide the change summary, the changed files, build and test results, the SonarQube result,
the remaining risks, and a suggested commit message. **Then wait for explicit user approval.**
No push, force-push, merge, rebase, tag, or release without it
([`../standards/git-approval-policy.md`](../standards/git-approval-policy.md)).

## 3. Build the image

```bash
npx nx build web --configuration=production   # static output: dist/apps/web/browser
docker build -t <image>:<tag> .
```

The `Dockerfile` copies the static build into an `nginx:alpine` runtime; `nginx.conf` proxies
`/api/...` to wherever the environment's API lives, and `docker/40-env.sh` rewrites
`public/env.js` with that environment's auth mode and OIDC settings at container start — the
same image is promoted across environments unrebuilt.

## 4. Deploy

- Promote dev → staging → production. Never deploy straight to production.
- Secrets (`OIDC_CLIENT_ID`, `OIDC_AUTHORITY`, `OIDC_SCOPE`) are supplied at container start
  from the environment's own secret store — **never** baked into the image, never committed to
  `docker-compose.yml` or `nginx.conf`.
- Configuration keys stay at parity across environments.

## 5. Verify after deploy

- The app loads and its requests resolve against the intended API — check a network request in
  the browser, not just that the container is running.
- Auth mode matches the environment (`dev` role picker only in non-production).
- A hard-reloaded tab survives; a **stale open tab surviving a deploy** does too — see the
  chunk-load-error-reload behaviour in `apps/web/src/chunk-load-error-handler.ts`.
- Watch error rate and latency in the environment's own telemetry before declaring success.

## 6. Post-release

Record follow-ups and anything learned in `docs/adr/` (if a decision was made) or the next
session handoff. If the release went wrong, write down what would have caught it — that is the
raw material for the weekly context retro in [`../README.md`](../README.md).
