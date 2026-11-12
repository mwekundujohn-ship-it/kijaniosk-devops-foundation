# Oral defense drill

The Wednesday session was an ownership test, not a recall test. The interviewer
opened a file, pointed at a line, and asked what it did, why it existed, where it
was used, and what would happen if it were removed. Practise the same loop.

## Five-step answer template

Use this order for every line:

1. **Name the line and file.** Example: `capstone/Jenkinsfile:15-17`.
2. **Read the behavior.** "This registers a five-minute SCM poll trigger."
3. **State the purpose.** "It lets a commit start the pipeline without a human."
4. **Name the consumer.** "Jenkins' SCM polling mechanism uses the job's branch
   configuration to detect the commit."
5. **Predict the failure.** "Without it, only manual builds start the pipeline."

Do not answer with a definition alone. The interviewer will follow up with
"where is it used?" and "what breaks if I delete it?"

## Drill 1 — Jenkins trigger

- Line: `capstone/Jenkinsfile:15-17`.
- Behavior: `pollSCM('H/5 * * * *')` asks Jenkins to check the SCM for changes
  roughly every five minutes, with a hash-jittered offset.
- Purpose: convert a commit into a pipeline run.
- Consumer: the Jenkins job's SCM configuration; the job must point at the
  repository and branch.
- Removal effect: the job becomes manual-only.
- Follow-up: "Is this a webhook?" No. A webhook is push-based; this is polling.
  State that distinction honestly.

## Drill 2 — Docker agent mounts

- Line: `capstone/Jenkinsfile:2-7`, especially line 5.
- Behavior: starts the `capstone-ci:1.0` container as root, uses the host
  network, mounts the host Docker socket, and mounts the kubeconfig and
  minikube certificate directory read-only.
- Purpose: the Jenkins controller image lacks Node, kubectl, and Python; the
  agent supplies them. Docker CLI needs the host daemon. kubectl needs the
  credentials and the certificate files referenced by the kubeconfig.
- Consumer: the Build, Push, Deploy, and Smoke stages.
- Removal effect: `node: not found`, `kubectl: not found`, or certificate
  errors during cluster access.

## Drill 3 — Shell strict mode

- Line: `capstone/scripts/smoke-test.sh:2`.
- Behavior: `set -e` exits on a failed command; `set -u` exits on an unset
  variable; `set -o pipefail` makes a pipeline fail if any element fails.
- Purpose: a smoke test must fail loudly, not print a warning and exit zero.
- Consumer: every command in the script, including the port-forward and Python
  assertions.
- Removal effect: a failed `curl` or a broken pipe can be ignored, producing a
  false pass.

## Drill 4 — Port-forward and cleanup

- Lines: `capstone/scripts/smoke-test.sh:11-21`.
- Behavior: starts `kubectl port-forward` in the background, stores the PID, and
  registers a `trap` that kills it on exit.
- Purpose: test the Service path without exposing a NodePort, and avoid orphan
  processes.
- Consumer: the readiness loop and the HTTP assertions.
- Removal effect: the test cannot reach the Service, or repeated runs leave
  port-forward processes behind.

## Drill 5 — Idempotent secret creation

- Lines: `capstone/scripts/create-pull-secret.sh:10-18`.
- Behavior: generates a namespace and a Docker registry secret with
  `--dry-run=client -o yaml`, then pipes the YAML into `kubectl apply -f -`.
- Purpose: create or update the secret without failing when it already exists,
  and without committing secret values.
- Consumer: the Deployment's `imagePullSecrets` reference.
- Removal effect: the namespaces may not exist, or the secret is missing and the
  pods enter `ImagePullBackOff`.

## Drill 6 — Kustomize overlay

- File: `capstone/k8s/overlays/staging/kustomization.yaml`.
- Behavior: sets the namespace, generates a hash-suffixed ConfigMap from
  literals, overrides the image tag, sets replicas, and adds an environment
  label that is included in selectors.
- Purpose: one base, two environments, no copy-pasted YAML.
- Consumer: `kubectl apply -k` and `kubectl kustomize`.
- Removal effect: staging and production either collide in one namespace or
  lose their environment-specific configuration.

## Drill 7 — Deployment selector and probes

- Lines: `capstone/k8s/base/deployment.yaml:7-15` and `34-45`.
- Behavior: the Deployment selects `app: kk-payments`; the pod template carries
  that label; readiness and liveness probe `/health` on named port `http`.
- Purpose: the selector must match or the Deployment controls no pods; the
  probes decide when the pod receives traffic and when it is restarted.
- Consumer: the Deployment controller, the Service endpoints, and the kubelet.
- Removal effect: a selector mismatch yields zero pods; removing probes sends
  traffic to unready pods or leaves a hung pod running.

## Drill 8 — Service wiring

- File: `capstone/k8s/base/service.yaml`.
- Behavior: a ClusterIP Service named `kk-payments-service` selects
  `app: kk-payments`, maps port 3001 to target port `http`.
- Purpose: stable in-cluster discovery and a single port contract.
- Consumer: the smoke test's port-forward and any in-cluster client.
- Removal effect: the smoke test cannot resolve the Service; clients have no
  stable endpoint.

## Drill 9 — Terraform state and namespaces

- Files: `capstone/terraform/backend.tf` and `capstone/terraform/main.tf:12-28`.
- Behavior: remote S3 state with locking; two `kubernetes_namespace_v1`
  resources with common labels.
- Purpose: durable state and Terraform-owned environment boundaries.
- Consumer: `terraform init/apply` and the Kustomize overlays.
- Removal effect: state is local and lockless; the overlays fail because the
  namespaces do not exist.

## Drill 10 — Build once, promote the same tag

- Lines: `capstone/Jenkinsfile:30-41`, `53-63`, `74`, `96`.
- Behavior: the tag is `package version + first seven commit characters`; the
  image is built and pushed once; the same tag is set in staging and production.
- Purpose: the artifact tested in staging is the artifact promoted.
- Consumer: both Deployments and the smoke tests.
- Removal effect: production gets a different artifact or an untraceable tag,
  and rollback evidence is lost.

## Drill 11 — Approval gate

- Lines: `capstone/Jenkinsfile:85-91`.
- Behavior: a 15-minute `input` step pauses the pipeline.
- Purpose: production promotion is deliberate.
- Consumer: the production deploy stage.
- Removal effect: every green build deploys production automatically.
- Limitation: Jenkins in this lab has no authentication, so the gate is a
  process control, not a strong authorization control. Say that plainly.

## Drill 12 — Monitoring rule

- File: `capstone/monitoring/kk-payments-alerts.yaml`.
- Behavior: three Prometheus alerts: no available replicas, container restarts,
  and no Service endpoints.
- Purpose: surface the two failure modes the smoke test cannot catch
  continuously.
- Consumer: Prometheus Operator via the `PrometheusRule` CRD.
- Removal effect: no alert fires when the Deployment loses all replicas or the
  Service loses endpoints.
- Limitation: kube-state-metrics and the Prometheus Operator are not installed
  in the current minikube cluster, so the rule is not evaluated live.

## Questions the interviewer is likely to ask

1. "Why does the Jenkins agent need the Docker socket?" Because the agent runs
   `docker build` and `docker push`, and those commands talk to the host Docker
   daemon.
2. "Why mount `.minikube` as well as `.kube`?" The kubeconfig references
   certificate files under `/home/user/.minikube`; kubectl needs both.
3. "Why `--network=host`?" The agent must reach the local registry and the
   minikube API without extra DNS or bridge configuration.
4. "Why `readOnlyRootFilesystem`?" The application only reads its files and
   listens on a port; a read-only root filesystem limits what a compromised
   process can change.
5. "Why a ConfigMap instead of baking environment values into the image?" The
   same image is promoted; environment differences belong in configuration.
   `APP_VERSION` is the exception: it identifies the immutable artifact, so it
   is baked in at build time. `NODE_ENV`, `PORT`, `RECEIPTS_BUCKET`, and
   `LOG_LEVEL` are runtime configuration.
6. "Why does the ConfigMap name have a hash?" Kustomize appends a content hash
   and rewrites the Deployment reference, so a config change triggers a rollout.
7. "Why `imagePullPolicy: Always`?" The lab reuses tags during development; the
   policy forces a registry check instead of a stale local image.
8. "Why not use a NodePort for the smoke test?" A port-forward tests the
   Service and does not expose the workload on every node.
9. "What is the rollback command?" `kubectl rollout undo
   deployment/kk-payments -n kijani-production`.
9a. "Why does the smoke test poll for the expected version?" A rollout can
    finish while an old pod is still terminating and still receiving Service
    traffic. Polling until the expected version appears removes that race; it
    caught a real failure in build #1.
10. "What is not production-grade here?" Single minikube cluster, local
    registry, lab credentials, no ingress/TLS, no external secret manager, no
    real Prometheus stack, and no Week 10 receipt implementation. State these
    before the interviewer finds them.

## One-minute summary

"My capstone connects the existing Weeks 3–8 work. Terraform owns the staging
and production namespaces and the receipts bucket. Kustomize renders one base
into two environments. Jenkins verifies the Week 5 app, builds and pushes the
Week 8 image, deploys staging, runs a real `/health` and `/total` smoke test,
waits for approval, and promotes the same image to production. The monitoring
rule covers lost replicas and restarts. The honest gaps are the single-cluster
production target, the unevaluated Prometheus rule, the missing Week 10 receipt
chain, and the peer review that still needs a human reviewer."
