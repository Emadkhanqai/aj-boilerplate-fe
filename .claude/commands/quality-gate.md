---
description: Run SonarQube and enforce zero Blocker/Critical/Major before a push may be proposed.
---

# /quality-gate

The focused SonarQube gate. Assumes build and tests are already green — if they are not, run
[`/qa`](qa.md) first.

Targets **SonarQube Community Build** (free, self-hosted). Community analyses one branch — the
default branch — so no step below names a branch or a pull request.

## Steps

1. Build coverage input: `npx nx run-many -t test --coverage`.
2. Run the scanner (plain `sonar-scanner` CLI against the project key in
   `sonar-project.properties`):
   ```bash
   sonar-scanner \
     -Dsonar.projectKey="$SONAR_PROJECT_KEY" \
     -Dsonar.host.url="$SONAR_HOST_URL" \
     -Dsonar.token="$SONAR_TOKEN" \
     -Dsonar.sources=apps,libs \
     -Dsonar.javascript.lcov.reportPaths='coverage/*/lcov.info'
   ```
   Never add `sonar.branch.name` or `sonar.pullrequest.*` — those need Developer Edition or
   above. See [`../standards/sonarqube.md`](../standards/sonarqube.md) for the exact
   invocation and the coverage report path.
3. Read the results over the SonarQube MCP:
   - `get_project_quality_gate_status`
   - `search_sonar_issues_in_projects` filtered to `BLOCKER,CRITICAL,MAJOR`
   - `search_security_hotspots` for the security review
   - Resolve the project key first, then call each tool with **no `branch` and no
     `pullRequest` argument**. Omitting both queries the default-branch analysis, which is the
     only analysis Community Build has.

## Rules

- **Blocker / Critical / Major must be zero before any push.** Fix → rebuild → rescan →
  repeat. Minor / Info are triaged.
- Coverage on new code ≥80%.
- **Do not suppress an issue to pass the gate** without explicit user approval and a recorded
  reason. `// NOSONAR`, "won't fix", and narrowing the scanned scope all count as suppression.
- If the server is unreachable, the gate has **not** passed. Say so — do not proceed as if it
  had. `SONAR_GATE_SKIP=1` exists only for first-run bootstrap and is a tech-lead decision.

See [`../standards/sonarqube.md`](../standards/sonarqube.md).
