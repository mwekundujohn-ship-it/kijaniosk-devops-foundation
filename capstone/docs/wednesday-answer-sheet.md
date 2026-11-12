# Wednesday answer sheet

Use this as the presentation and oral-ownership cheat sheet. The verified run is
Jenkins build **#2: SUCCESS** for tag `2.4.0-2a84c81`.

## 90-second opening

"I built the Track A capstone as a build-once, promote-the-same-artifact
pipeline. Terraform creates the staging and production namespaces and the two
private, versioned receipts buckets. Kustomize keeps one base workload and two
environment overlays. Jenkins runs lint and tests, builds one image tagged with
the package version plus the commit SHA, pushes it, deploys staging, waits for
rollout, and smoke-tests `/health` and `/total`. A human approval step then
promotes the same tag to production, waits for rollout, and repeats the smoke
test. Build #2 passed end to end; both namespaces run `2.4.0-2a84c81`.
Production is a separate namespace in the same minikube cluster, not a separate
AWS account."

## Verified live facts

| Fact | Value |
| --- | --- |
| Branch | `feature/capstone-track-a` |
| HEAD | `2a84c81` |
| Jenkins job | `kijanikiosk-capstone` |
| Verified build | `#2 SUCCESS` |
| Promoted tag | `2.4.0-2a84c81` |
| Staging | `kijani-staging`, 2 replicas, smoke PASS |
| Production | `kijani-production`, 3 replicas, smoke PASS |
| Production smoke | `PASS health`, `PASS total`, `PASS smoke test` |
| Terraform resources | 2 namespaces, 2 S3 buckets, 6 bucket settings |

## Highest-value exact lines

| Question | Exact location | One-line answer |
| --- | --- | --- |
| What runs the pipeline? | `capstone/Jenkinsfile:2-7` | A `capstone-ci:1.0` container supplies Node, Python, kubectl, Docker, and git; it mounts the host Docker socket, kubeconfig, and minikube certificates. |
| What starts the pipeline? | `capstone/Jenkinsfile:15-17` | `pollSCM('H/5 * * * *')` checks the branch about every five minutes. It is polling, not a webhook. |
| How is the tag made? | `capstone/Jenkinsfile:30-41` | Read `2.4.0` from `week8/friday/package.json`, append the first seven characters of `GIT_COMMIT`, producing `2.4.0-2a84c81`. |
| Where is the artifact built once? | `capstone/Jenkinsfile:53-63` | Build with `APP_VERSION="$TAG"` and push once. Neither staging nor production rebuilds. |
| How is staging deployed? | `capstone/Jenkinsfile:71-77` | `kubectl apply -k`, then `set image` to the exact tag, then `rollout status --timeout=180s`. |
| Where is the approval gate? | `capstone/Jenkinsfile:85-91` | A 15-minute `input` step pauses before production. Removing it auto-deploys every green build. |
| How is production promoted? | `capstone/Jenkinsfile:93-103` | Apply the production overlay, set the same tag, wait for rollout, run the same smoke test. |
| Where is evidence archived? | `capstone/Jenkinsfile:108-117` | Writes staging/production state and the staging ConfigMap to `capstone/evidence/` and archives them. |
| Where is remote state? | `capstone/terraform/backend.tf:2-5` | S3 state at `capstone/track-a/terraform.tfstate` with locking. |
| Where are namespaces created? | `capstone/terraform/main.tf:17-33` | `kubernetes_namespace_v1` for `kijani-staging` and `kijani-production`. |
| Where are receipts buckets created? | `capstone/terraform/main.tf:11-45` | One account-suffixed bucket per environment. |
| Where are buckets protected? | `capstone/terraform/main.tf:47-77` | Versioning, SSE-S3, and a full public-access block. |
| Where is the staging ConfigMap? | `capstone/k8s/overlays/staging/kustomization.yaml:6-15` | Generates `NODE_ENV`, `PORT`, `RECEIPTS_BUCKET`, `LOG_LEVEL` with a content hash in the name. |
| Where is the image tag overridden? | `capstone/k8s/overlays/staging/kustomization.yaml:16-18`; production `:16-18` | The overlay has a safe default; Jenkins/Ansible set the release tag after apply. |
| Where are replicas set? | `capstone/k8s/overlays/staging/kustomization.yaml:19-21`; production `:19-21` | Staging 2, production 3. |
| Where is the environment label? | `capstone/k8s/overlays/staging/kustomization.yaml:22-25`; production `:22-25` | Adds `environment` to selectors. |
| Where are probes? | `capstone/k8s/base/deployment.yaml:34-45` | Readiness and liveness both GET `/health` on named port `http`. |
| Where is the Service selector? | `capstone/k8s/base/service.yaml:8-14` | ClusterIP, selects `app: kk-payments`, port 3001 to named port `http`. |
| Where is the image tag enforced in Ansible? | `capstone/ansible/staging.yml:24-28`; production `:24-28` | `kubectl set image` after `apply -k`; otherwise apply resets the tag to the overlay default. |
| Where does smoke poll the expected version? | `capstone/scripts/smoke-test.sh:38-49` | Waits until `/health.version` equals the expected tag before asserting. |
| Where is the business check? | `capstone/scripts/smoke-test.sh:69-79` | POSTs two line items and asserts total `42`. |
| Why no `APP_VERSION` in ConfigMap? | `capstone/k8s/overlays/staging/kustomization.yaml:6-12` | Version is immutable build metadata baked into the image, not runtime config. |
| Where is the monitoring rule? | `capstone/monitoring/kk-payments-alerts.yaml:13-38` | Three Prometheus alerts: unavailable replicas, restarts, no endpoints. |

## Commands to type during the presentation

```bash
# Repo and release state
git log --oneline -3
git status --short

# Jenkins proof
curl -fsS http://localhost:8080/job/kijanikiosk-capstone/2/api/json?tree=result,timestamp,duration
curl -fsS http://localhost:8080/job/kijanikiosk-capstone/2/consoleText | tail -40

# Trigger a new pipeline run
curl -X POST http://localhost:8080/job/kijanikiosk-capstone/build

# Terraform remote state and resources
terraform -chdir=capstone/terraform init
terraform -chdir=capstone/terraform state list

# Kustomize renders two environments from one base
kubectl kustomize capstone/k8s/overlays/staging | grep -E 'namespace:|name: kk-payments-config|newTag|replicas|environment:'
kubectl kustomize capstone/k8s/overlays/production | grep -E 'namespace:|name: kk-payments-config|newTag|replicas|environment:'

# Ansible deploy with the exact tested tag
ansible-playbook -i capstone/ansible/inventory.ini capstone/ansible/staging.yml -e image_tag=2.4.0-2a84c81

# Same smoke test used by Jenkins
./capstone/scripts/smoke-test.sh kijani-production 2.4.0-2a84c81

# Live state
kubectl get deploy,rs,pods,svc,configmap -n kijani-staging -o wide
kubectl get deploy,rs,pods,svc,configmap -n kijani-production -o wide

# Prove the running image and immutable version
kubectl -n kijani-production get deploy kk-payments -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
kubectl -n kijani-production exec deploy/kk-payments -- printenv APP_VERSION

# Show an exact line range
nl -ba capstone/Jenkinsfile | sed -n '85,91p'
```

## Rollback command

```bash
kubectl -n kijani-production rollout history deployment/kk-payments
kubectl -n kijani-production rollout undo deployment/kk-payments
kubectl -n kijani-production rollout status deployment/kk-payments
```

Rollback is documented and available, but it was not exercised on the final
tag. Say that honestly if asked for proof.

## Rapid Q&A

- **Why build once?** Production receives the exact bytes tested in staging.
  Rebuilding can produce a different image from the same commit.
- **Why tag with the commit SHA?** Every running image maps to one commit; the
  tag is immutable evidence for rollback and audit.
- **Why Ansible if Jenkins already uses kubectl?** Ansible is the repeatable
  operator path and the fallback when Jenkins is unavailable. Both use the same
  overlay and the same tag.
- **Why `set image` after `apply -k`?** `apply -k` resets the Deployment to the
  overlay's default tag. The explicit `set image` is what enforces
  `-e image_tag`.
- **Why does smoke poll the expected version?** During a rollout the Service can
  still route to an old pod. Polling prevents a false pass and the false failure
  seen in build #1.
- **Why remove `APP_VERSION` from the ConfigMap?** It is build provenance. If it
  lived in runtime config, a ConfigMap edit or restart could advertise a version
  that is not in the image.
- **What breaks without the readiness probe?** Traffic reaches a pod before the
  process is ready; a rolling update can also declare success too early.
- **What breaks without the Service selector?** The Service has no endpoints and
  the smoke test cannot reach the app.
- **What breaks without the approval gate?** Every green build deploys
  production automatically.
- **What breaks without the pull secret?** Pods fail with `ImagePullBackOff`.
- **What breaks without the S3 backend?** State becomes local and lockless;
  two operators can overwrite each other.
- **Is production isolated?** No. It is a separate namespace in the same
  minikube cluster. Do not claim a separate cluster or AWS account.

## Honest limitations to state

- Capstone guide pages 2 and 6 were unavailable, so the rubric labels are
  reconstructed.
- Week 9 and Week 10 specifications were unavailable; the receipt chain is not
  implemented. `RECEIPTS_BUCKET` is a placeholder for it.
- The PrometheusRule is valid YAML but not evaluated because kube-state-metrics
  and the Prometheus Operator are not installed.
- Peer review, the Loom demo, the slide deck, and the reflection are
  student-owned deliverables.
- The GitHub token embedded in `.git/config` must be rotated.
