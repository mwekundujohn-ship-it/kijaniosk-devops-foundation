# AI Governance Log

This log records material AI assistance on the Track A capstone. It is intentionally about the work that required a human correction, not a claim that AI output was accepted unchanged. No AI was used to invent peer feedback, test results, build results, or screenshots.

**Tool used:** OpenCode CLI coding assistant, model `opencode/big-pickle`, and the student's own terminal/editor review.  
**Reviewer:** Dalton Wambui.

## Six-point governance checklist used for this project

| # | Checklist item | How it was applied |
|---|---|---|
| 1 | Human review before merge | Every generated file was read and corrected before commit; the student can explain each line in the oral defense. |
| 2 | Tests and verification | Generated changes were checked with `terraform validate`, `kubectl kustomize`, Ansible syntax checks, Jenkins lint, and live smoke tests. |
| 3 | Security and secrets review | No credentials were added to tracked files; the pull secret is created at runtime from environment variables. The existing `.git/config` token still needs rotation outside the repository. |
| 4 | Data handling and privacy | Only synthetic payment data (`unitPrice`/`quantity`) is used; no customer or receipt data is stored. |
| 5 | Traceability and attribution | AI-assisted changes are identified here and tied to commits, failures, and evidence. |
| 6 | Runtime monitoring and recovery | Probes, rollout status, smoke tests, PrometheusRule design, and the pod self-healing demo were reviewed as operational safeguards. |

## Entry 1 - Smoke test accepted an old pod as a successful release

| Field | Record |
|---|---|
| **Date** | 2026-11-12 |
| **Tool / model** | OpenCode CLI, `opencode/big-pickle` |
| **Task and prompt** | Draft a staging smoke test that proves the newly built image is actually serving traffic before production approval. |
| **AI output** | A script that port-forwarded the Service and checked that `/health` returned HTTP 200 and `/total` returned `42`. |
| **What the AI got wrong** | It treated "an HTTP response" as "the new release is healthy". During build #1 the new image had rolled out, but the Service still had an old pod behind it. The smoke test passed against the old version, so the release was not actually proven. |
| **Specific human change** | Added an `EXPECTED_VERSION` argument, polled `/health` until the returned version matched the image tag, and failed the build on a mismatch. The pipeline now passes `$TAG` into `capstone/scripts/smoke-test.sh`. |
| **Verification / evidence** | Build #1 failed on a version mismatch; build #4 succeeded in `capstone/evidence/jenkins-build-4/console.txt`; commit `ec8568e`; the smoke test prints the asserted version. |
| **Checklist items** | #1 Human review before merge; #2 Tests and verification. |

## Entry 2 - Ansible apply reset the promoted image tag

| Field | Record |
|---|---|
| **Date** | 2026-11-12 |
| **Tool / model** | OpenCode CLI, `opencode/big-pickle` |
| **Task and prompt** | Make the Ansible staging/production playbooks apply the Kustomize overlay and wait for the rollout. |
| **AI output** | A playbook that ran `kubectl apply -k` and `kubectl rollout status`. |
| **What the AI got wrong** | The overlay contains a placeholder image tag. `kubectl apply -k` rewrites the Deployment to that placeholder and can undo the tag that Jenkins just built and pushed. The task name said "apply the overlay", but the release intent was "deploy this exact image tag". |
| **Specific human change** | Added an explicit `kubectl set image deployment/kk-payments kk-payments=<registry>/<image>:<tag>` task after `apply -k`, followed by `rollout status`. This makes the release tag explicit and independent of the overlay placeholder. |
| **Verification / evidence** | Staging and production installs in the Jenkins build #4 console show `deployment.apps/kk-payments image updated` and successful rollouts; Ansible syntax checks pass; build #4 archived the approval reason. |
| **Checklist items** | #1 Human review before merge; #2 Tests and verification; #5 Traceability and attribution. |

## Entry 3 - Version metadata was conflated with runtime configuration

| Field | Record |
|---|---|
| **Date** | 2026-11-12 |
| **Tool / model** | OpenCode CLI, `opencode/big-pickle` |
| **Task and prompt** | Make the running service report the release version so the smoke test can verify promotion. |
| **AI output** | A suggestion to place `APP_VERSION` in the environment-specific ConfigMap. |
| **What the AI got wrong** | `APP_VERSION` is build metadata, not runtime configuration. Putting it in a ConfigMap allows the reported version to drift from the image that was actually built. The image already receives `APP_VERSION` as a Docker build argument and bakes it in. |
| **Specific human change** | Kept `APP_VERSION` out of both ConfigMaps; the Dockerfile receives it as a build argument and the smoke test compares `/health` to the immutable image tag. |
| **Verification / evidence** | `week8/friday/Dockerfile.production` build arg and `week8/friday/src/index.ts` `resolveVersion()`; `capstone/Jenkinsfile` passes `--build-arg APP_VERSION="$TAG"`; ConfigMaps contain only environment-specific runtime values. |
| **Checklist items** | #1 Human review before merge; #2 Tests and verification; #5 Traceability and attribution. |

## Entry 4 - Approval gate did not record why production was approved

| Field | Record |
|---|---|
| **Date** | 2026-11-14 |
| **Tool / model** | OpenCode CLI, `opencode/big-pickle` |
| **Task and prompt** | Add a production approval gate to the Jenkins pipeline. |
| **AI output** | A bare `input` step with only a message and an OK button. |
| **What the AI got wrong** | The gate paused the pipeline but left no durable record of who approved or why. That is a control without evidence, and it does not meet the capstone requirement to record the reason. |
| **Specific human change** | Added `submitterParameter: 'APPROVER'`, an `APPROVAL_REASON` string parameter, and a `writeFile` step that archives `capstone/evidence/approval.txt` with approver, reason, and tag. |
| **Verification / evidence** | Jenkins declarative linter passes; the next verified build archives `approval.txt` alongside the deployment state. |
| **Checklist items** | #1 Human review before merge; #5 Traceability and attribution; #6 Runtime monitoring and recovery. |

## Boundaries

- The AI did not perform the peer review and did not write fabricated reviewer comments.
- The AI did not run the live demo unattended; the fault-injection evidence in `capstone/evidence/demo/` must come from the actual cluster.
- The AI's explanation of the system is not a substitute for the student's oral defense; the student must be able to trace each claim to a file and line.
