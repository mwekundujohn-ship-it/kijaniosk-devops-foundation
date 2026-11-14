# Peer Feedback Log

**Status: self-review fallback. No external classmate review has been completed yet. This must not be described as peer review.**

The capstone rubric gives the strongest evidence credit to a review by another student. The honest fallback is a documented self-review using the same issue format. Three findings are recorded below; all three are linked to real GitHub Issues and were fixed in commit `2a84c81`.

**Reviewer for the entries below:** Dalton Wambui (self-review)  
**Test plan used:** `docs/test-plan.md`  
**Repository:** `mwekundujohn-ship-it/kijaniosk-devops-foundation`

## Findings

| # | Location | Severity | What was found | Expected | Resolution | Evidence |
|---|---|---|---|---|---|---|
| 1 | `capstone/scripts/smoke-test.sh` | Blocker | The first smoke test checked HTTP success only. Build #1 could pass while an old pod was still serving through the Service, so the new image was not actually proven. | The smoke test must assert the version of the image being promoted before the approval gate. | Added an `EXPECTED_VERSION` argument, polled `/health` until the served version matched the image tag, and failed the build on mismatch. Jenkins passes `$TAG`. | [Issue #12](https://github.com/mwekundujohn-ship-it/kijaniosk-devops-foundation/issues/12), fixed in `2a84c81`; build #2 console. |
| 2 | `capstone/ansible/staging.yml`, `capstone/ansible/production.yml` | Major | `kubectl apply -k` can reset the Deployment to the overlay's placeholder image tag after Jenkins built and pushed the real tag. The playbook could report success while running the wrong image. | The playbook must apply configuration and then explicitly set the exact tag being promoted. | Added a `kubectl set image` task after `apply -k` in both environments, then wait for rollout. | [Issue #13](https://github.com/mwekundujohn-ship-it/kijaniosk-devops-foundation/issues/13), fixed in `2a84c81`; build #2 console. |
| 3 | `capstone/k8s/overlays/staging/kustomization.yaml`, `capstone/k8s/overlays/production/kustomization.yaml` | Major | An early design put `APP_VERSION` in the ConfigMap. The reported version could then disagree with the immutable image. | Build metadata belongs in the image; environment configuration belongs in the ConfigMap. | Removed `APP_VERSION` from both ConfigMaps. The Dockerfile receives it via `--build-arg`; the image reports it; the smoke test asserts it. | [Issue #14](https://github.com/mwekundujohn-ship-it/kijaniosk-devops-foundation/issues/14), fixed in `2a84c81`; `week8/friday/Dockerfile.production`. |

## GitHub Issue closure evidence

| Issue | Title | State | Fix reference |
|---|---|---|---|
| [#12](https://github.com/mwekundujohn-ship-it/kijaniosk-devops-foundation/issues/12) | Self-review: staging smoke test can pass against an old pod | Closed | commit `2a84c81` |
| [#13](https://github.com/mwekundujohn-ship-it/kijaniosk-devops-foundation/issues/13) | Self-review: Ansible apply can reset the promoted image tag | Closed | commit `2a84c81` |
| [#14](https://github.com/mwekundujohn-ship-it/kijaniosk-devops-foundation/issues/14) | Self-review: APP_VERSION must not be mutable ConfigMap data | Closed | commit `2a84c81` |

## What is still missing for Exemplary

An external classmate must independently review the repository, file at least three issues (including one blocker or major), and the student must resolve at least one with a commit that references the issue. Use `capstone/docs/peer-review-request.md` as the request message.

If a classmate completes the review before submission, replace the status line and add their name, issue numbers, and fix commits. Do not invent a reviewer or copy these self-review findings as if someone else found them.
