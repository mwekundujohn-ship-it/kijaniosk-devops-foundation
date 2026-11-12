# Capstone requirement matrix

Status values: `VERIFIED`, `PARTIAL`, `MISSING`, `USER-OWNED`.

| ID | Requirement | Artifact | Evidence | Status |
| --- | --- | --- | --- | --- |
| A1 | Clear capstone scope and architecture | `capstone/README.md`, this matrix | Promotion flow and component boundaries documented | VERIFIED |
| A2 | Infrastructure as code | `capstone/terraform/` | `terraform fmt` and `validate`; namespaces and buckets | VERIFIED |
| A3 | Environment separation | `capstone/k8s/overlays/staging`, `capstone/k8s/overlays/production` | Separate namespaces, ConfigMaps, replicas, image tags | VERIFIED |
| A4 | Configuration as code | `capstone/k8s/base`, overlays | Kustomize renders both overlays | VERIFIED |
| A5 | Application verification | `capstone/Jenkinsfile` Verify stage | Week 5 lint and 10/10 tests | VERIFIED |
| A6 | Image build and registry push | `capstone/Jenkinsfile`, `week8/friday/Dockerfile.production` | Week 8 build evidence plus local pipeline | VERIFIED |
| A7 | Staging deployment | `capstone/ansible/staging.yml`, staging overlay | Jenkins build #2 deployed and rolled out `2.4.0-2a84c81` | VERIFIED |
| A8 | Staging smoke test | `capstone/scripts/smoke-test.sh` | `/health` and `/total` assertions | VERIFIED |
| A9 | Human approval before production | `capstone/Jenkinsfile` Approve production stage | Build #2 paused at `Deploy 2.4.0-2a84c81 to production?` and was approved | VERIFIED |
| A10 | Production promotion | `capstone/ansible/production.yml`, production overlay | Build #2 promoted the same tag and reached 3/3 ready | VERIFIED |
| A11 | Production smoke test | `capstone/scripts/smoke-test.sh` | Build #2 reported `PASS health`, `PASS total`, and `PASS smoke test` in production | VERIFIED |
| A12 | Monitoring and alerting | `capstone/monitoring/kk-payments-alerts.yaml` | Three PrometheusRule alerts | PARTIAL |
| A13 | Rollback path | Deployment revision history | `kubectl rollout undo` documented in oral defense | PARTIAL |
| A14 | Ownership and explainability | `capstone/docs/code-ownership-map.md` | Five-part answer protocol per component | USER-OWNED |
| A15 | Peer review | `capstone/docs/peer-review-request.md` | Template only; reviewer must file issues | MISSING |
| A16 | Version control evidence | Git branches and commits | Capstone commits `7c331ba` and `2a84c81` pushed to `feature/capstone-track-a`; PRs #10/#11 remain separate Week 5/8 evidence | VERIFIED |
| A17 | Release tag | Git tag | `v1.0.0` tags the final validated commit | VERIFIED |
| A18 | Demo recording | Loom or screenshots | Not recorded | USER-OWNED |
| A19 | Slide deck | Presentation artifact | Not created | USER-OWNED |
| A20 | Written reflection | Reflection artifact | Not created | USER-OWNED |
| A21 | Week 9 observability brief | Brief | Brief not available in repository | MISSING |
| A22 | Week 10 receipt chain | Serverless spec and implementation | Spec not available; ConfigMap key and per-environment buckets only | MISSING |
| A23 | AI governance log | Governance record | Not created; required if AI-assisted code is submitted | MISSING |
| A24 | Cost and teardown evidence | AWS destroy output | Week 4 destroy evidence exists; capstone buckets are new | PARTIAL |

## Evidence paths

- Jenkins build #2: `capstone/evidence/jenkins-build-2/` (`console.txt`, `build.json`, namespace state, staging ConfigMap).
- Week 5 tests: `week5/friday/green-pipeline-run.txt`, `week5/friday/app/test-results/`.
- Week 8 build: `week8/friday/build-verification.txt`.
- Week 8 registry push: `week8/friday/registry-push.txt`.
- Week 8 deployment: `week8/friday/deploy-output.txt`, `week8/friday/service-output.txt`.
- Week 8 self-healing: `week8/friday/self-healing-rerun.txt`.
- Week 8 credential audit: `week8/friday/credential-audit.txt`.

## Honest gaps

- The capstone guide pages 2 and 6 were not available, so the rubric row names
  are reconstructed from the visible requirements.
- Week 9 and Week 10 specifications were not available. No Week 10
  implementation is claimed.
- The production environment is a separate Kubernetes namespace, not a separate
  AWS account.
- Peer feedback, demo, deck, and reflection cannot be produced on the student's
  behalf.
