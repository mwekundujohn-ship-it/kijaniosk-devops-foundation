# Live Demo Script - Track A

**Presenter:** Dalton Wambui  
**Target length:** 7-9 minutes  
**Goal:** prove one tested image moves from staging to production through a recorded approval gate, then survives a pod fault.

Do not narrate the architecture for more than 60 seconds. Spend the time on evidence: a command, its output, and what the output proves.

## Before the demo

```bash
cd ~/Projects/kijaniosk-devops-foundation
kubectl get ns kijani-staging kijani-production
kubectl -n kijani-staging get deploy,pods,svc
kubectl -n kijani-production get deploy,pods,svc
```

Have these open in separate tabs:

- Jenkins build page: `http://localhost:8080/job/kijanikiosk-capstone/`
- `capstone/evidence/demo/approval.txt` or the archived `approval.txt` from the latest successful build
- `docs/architecture.png`
- `capstone/evidence/demo/fault-handling.txt` as a fallback if the live deletion is not appropriate

## 1. Framing (45 seconds)

"This is Track A. The claim is not that I can run `kubectl apply`. The claim is that one image is built once, proven in staging, approved by a human with a recorded reason, promoted to production, and verified there. The same image tag must appear in both namespaces."

Show `docs/architecture.png` and point to the three evidence links: registry, smoke test, approval gate. State the Week 10 gap in one sentence; do not hide it.

## 2. Environment separation (60 seconds)

```bash
kubectl kustomize capstone/k8s/overlays/staging | python3 -c 'import sys,yaml; [print(d["data"]) for d in yaml.safe_load_all(sys.stdin) if d and d.get("kind")=="ConfigMap"]'
kubectl kustomize capstone/k8s/overlays/production | python3 -c 'import sys,yaml; [print(d["data"]) for d in yaml.safe_load_all(sys.stdin) if d and d.get("kind")=="ConfigMap"]'
```

Say: "The base Deployment and Service are shared. The overlays change namespace, replicas, labels, and ConfigMap values. `DB_HOST` differs by environment. `APP_VERSION` is deliberately absent because it is baked into the image."

## 3. Cluster state (60 seconds)

```bash
kubectl -n kijani-staging get deploy kk-payments -o wide
kubectl -n kijani-production get deploy kk-payments -o wide
kubectl -n kijani-staging get pods -l app=kk-payments
kubectl -n kijani-production get pods -l app=kk-payments
```

Point at the image tags. "These must match after a successful promotion; if they do not, the release is not complete even if both Deployments are Ready."

## 4. Pipeline and approval (90 seconds)

Open the latest successful Jenkins build. Show:

- Verify stage passed.
- One Build image and one Push image.
- Staging smoke passed.
- Approve production stage paused.
- Production deploy and smoke passed.
- Archived `approval.txt`.

```bash
cat capstone/evidence/demo/approval.txt
```

Expected content: `approver`, `reason`, `tag`. Say: "The gate is not just a pause; it records who accepted the risk and why."

If the approval file is not present yet, use the latest archived build artefact and say so; do not claim the file exists.

## 5. Negative check (30-45 seconds)

Run only if there is time and the audience wants to see the guardrail:

```bash
capstone/scripts/smoke-test.sh kijani-staging deliberately-wrong-version
```

Expected: non-zero exit and an assertion showing the actual version versus the wrong expected version. No `PASS` line.

Say: "This is the check that caught build #1. An HTTP 200 was not enough; the version assertion is what proves the promoted artifact."

## 6. Fault handling (60-90 seconds)

```bash
POD=$(kubectl -n kijani-staging get pods -l app=kk-payments -o jsonpath='{.items[0].metadata.name}')
kubectl -n kijani-staging delete pod "$POD" --wait=false
kubectl -n kijani-staging get pods -l app=kk-payments -o wide
kubectl -n kijani-staging rollout status deployment/kk-payments --timeout=180s
kubectl -n kijani-staging get deploy kk-payments
```

Expected: one pod Terminating, one new pod ContainerCreating, then the Deployment returns to 2/2 available without a manual rollout.

Say: "The Deployment controller replaces the pod because the desired replica count is 2. This is self-healing, not a rollback. The rollback command for a bad release is `kubectl rollout undo deployment/kk-payments -n kijani-production`."

## 7. Production proof (45 seconds)

```bash
TAG=$(kubectl -n kijani-production get deploy kk-payments -o jsonpath='{.spec.template.spec.containers[0].image}' | sed 's#.*:##')
capstone/scripts/smoke-test.sh kijani-production "$TAG"
```

Expected: `PASS health`, `PASS total`, `PASS smoke test`.

## 8. Close honestly (45 seconds)

State the four gaps:

1. Production is a namespace in the same minikube cluster, not a separate cluster.
2. Week 10 serverless receipt chain is not implemented; the buckets and environment key are prepared.
3. The PrometheusRule is validated but not evaluated because the operator and kube-state-metrics are absent.
4. Peer review is currently a self-review fallback, not an external classmate review.

Then state the next iteration: merge-to-main trigger, receipt producer, live alert, secret manager, and independent peer review.

## Failure fallback

| Failure | Response |
|---|---|
| Jenkins is down | Use archived build evidence and say the live rerun is unavailable; do not claim a new build. |
| Registry is unavailable | Show the existing image and smoke evidence; explain that a rebuild cannot be proven without the registry. |
| Pod deletion is not permitted | Use `capstone/evidence/demo/fault-handling.txt` and state that it was captured from the live cluster. |
| Version mismatch | Do not approve production. Explain that the guardrail is doing its job and investigate the rollout. |
| Week 10 question | "Not implemented. The bucket and key exist; the serverless producer does not. I am not claiming it as complete." |
