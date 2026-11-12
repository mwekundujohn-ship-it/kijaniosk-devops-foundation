# Code ownership map

This map is the study sheet for the Wednesday oral-ownership check. For every
component, be ready to answer five questions in this order:

1. Show the exact line.
2. Read what it does.
3. Explain why it exists.
4. Name where it is used.
5. Predict what breaks if it is removed or changed.

## Capstone pipeline

| Component | Exact location | What it does | Why it exists | Where used | If removed |
| --- | --- | --- | --- | --- | --- |
| Docker agent | `capstone/Jenkinsfile:2-7` | Runs every stage inside `capstone-ci:1.0` with the host Docker socket and kubeconfig. | The Jenkins controller image has no Node, kubectl, or Python; the agent supplies them. | All stages. | Stages fail with `node: not found`, `kubectl: not found`, or no Docker daemon. |
| Agent mounts | `capstone/Jenkinsfile:5` | Mounts `/var/run/docker.sock`, `/home/user/.kube`, and `/home/user/.minikube`. | Docker CLI needs the host daemon; kubectl needs the cluster credentials and certificate files. | Build/push and deploy/smoke stages. | Docker cannot build; kubectl cannot authenticate or cannot read certificates. |
| Poll trigger | `capstone/Jenkinsfile:15-17` | Polls SCM every five minutes. | Makes the pipeline start from a commit instead of only a manual click. | Jenkins job trigger. | The job only runs when a human clicks Build Now. |
| Concurrency guard | `capstone/Jenkinsfile:11` | `disableConcurrentBuilds()`. | Prevents two releases from changing the same Deployment at once. | Every build. | Two builds can push and set different image tags, causing a race. |
| Build retention | `capstone/Jenkinsfile:12` | Keeps the last 20 builds. | Prevents unbounded Jenkins disk growth. | Every build. | Jenkins disk fills over time. |
| Registry variables | `capstone/Jenkinsfile:20-26` | Defines registry, image, namespaces, and directories. | One place to change the promotion targets. | Build, push, deploy, smoke stages. | Hard-coded names would drift between stages. |
| Release tag | `capstone/Jenkinsfile:30-41` | Reads `2.4.0` from `week8/friday/package.json` and appends the first seven characters of `GIT_COMMIT`. | Makes every image traceable to one commit. | Build, push, deploy, smoke. | Images overwrite a moving tag; rollback evidence is lost. |
| Verify | `capstone/Jenkinsfile:43-51` | Runs `npm ci`, lint, and tests in `week5/friday/app`. | Stops a broken payment calculation before it becomes an image. | Before build. | A defect reaches the registry and the cluster. |
| Build | `capstone/Jenkinsfile:53-57` | Builds `week8/friday/Dockerfile.production` with `APP_VERSION="$TAG"`. | Produces the exact artifact that will be promoted. | Push stage. | There is no image to deploy. |
| Push | `capstone/Jenkinsfile:59-63` | Pushes `localhost:5000/kk-payments:$TAG`. | The cluster must pull from a registry, not the Jenkins workspace. | Staging and production Deployments. | Pods fail with `ImagePullBackOff`. |
| Pull secrets | `capstone/Jenkinsfile:65-69` | Runs `create-pull-secret.sh` for both namespaces. | The Deployment references `kijani-registry-credentials`. | Before apply. | Pods cannot pull the image and stay in `ImagePullBackOff`. |
| Deploy staging | `capstone/Jenkinsfile:71-77` | Applies the staging overlay, sets the image tag, and waits for rollout. | Creates the staging release and proves it became ready. | Staging. | The smoke test has no release to test. |
| Smoke staging | `capstone/Jenkinsfile:79-83` | Calls `smoke-test.sh` with the expected tag. | Verifies `/health` and `/total` after deployment, not just pod readiness. | Before production. | A pod can be Ready while the application is wrong. |
| Approval | `capstone/Jenkinsfile:85-91` | Waits up to 15 minutes for a human `input`. | Production promotion must be deliberate. | Between staging and production. | Every green build deploys production automatically. |
| Deploy production | `capstone/Jenkinsfile:93-99` | Applies the production overlay with the same tag. | Promotes the tested artifact instead of rebuilding. | Production. | Production either does not change or gets a different artifact. |
| Smoke production | `capstone/Jenkinsfile:101-105` | Repeats the smoke test in `kijani-production`. | Confirms the promotion target is healthy. | After production rollout. | A failed production rollout is not detected. |
| Evidence archive | `capstone/Jenkinsfile:108-117` | Writes namespace state to `capstone/evidence/` and archives it. | Leaves proof for the demo and the marker. | Post-build. | The demo has no machine-generated evidence. |

## Terraform

| Component | Exact location | What it does | Why it exists | Where used | If removed |
| --- | --- | --- | --- | --- | --- |
| Provider versions | `capstone/terraform/versions.tf` | Pins Terraform, AWS, and Kubernetes providers. | Prevents an unplanned provider upgrade from changing behavior. | `terraform init`. | A future provider release can break the plan. |
| S3 backend | `capstone/terraform/backend.tf` | Stores state at `capstone/track-a/terraform.tfstate` in the existing state bucket. | Keeps state off the laptop and enables locking. | `terraform init`, `apply`, `destroy`. | State is local and can be lost or edited by accident. |
| AWS provider | `capstone/terraform/providers.tf:1-11` | Sets region and default tags. | Every AWS resource is tagged with project, manager, and capstone track. | S3 bucket. | Cost and ownership reports cannot attribute the bucket. |
| Kubernetes provider | `capstone/terraform/providers.tf:13-16` | Reads the kubeconfig and context. | Terraform must target minikube, not an unrelated cluster. | Namespace resources. | Terraform may target the wrong cluster. |
| Account data | `capstone/terraform/main.tf:1-15` | Reads the AWS account ID into common labels and the per-environment bucket names. | Makes the owning account visible and keeps each bucket name globally unique. | All resources and both ConfigMaps. | Bucket names can collide with another AWS account. |
| Staging namespace | `capstone/terraform/main.tf:17-24` | Creates `kijani-staging`. | Gives staging a stable, Terraform-owned boundary. | Staging overlay and Ansible. | `kubectl apply` fails with `namespace not found`. |
| Production namespace | `capstone/terraform/main.tf:26-33` | Creates `kijani-production`. | Separates the promotion target from staging. | Production overlay and Ansible. | Production apply fails. |
| Receipts buckets | `capstone/terraform/main.tf:35-45` | Creates one private, account-suffixed S3 bucket per environment. | The receipt chain needs durable storage outside the pod, and staging must not share production storage. | Week 10 integration; ConfigMap key `RECEIPTS_BUCKET`. | Week 10 has nowhere durable to write receipts. |
| Versioning | `capstone/terraform/main.tf:47-55` | Enables versioning on both buckets. | Protects against overwrite or deletion of receipts. | Receipts buckets. | A bad write cannot be recovered. |
| Encryption | `capstone/terraform/main.tf:57-67` | Enables SSE-S3 by default on both buckets. | Receipts contain payment data and must be encrypted at rest. | Receipts buckets. | Objects are stored without default encryption. |
| Public access block | `capstone/terraform/main.tf:69-77` | Blocks public ACLs and policies on both buckets. | Prevents accidental public exposure of receipts. | Receipts buckets. | A bucket policy mistake could expose receipts. |
| Outputs | `capstone/terraform/outputs.tf:1-29` | Exposes namespace names, per-environment bucket names, ARNs, and context. | The operator can verify targets without reading state. | Local verification and documentation. | Operators guess names and drift. |

## Kubernetes and Kustomize

| Component | Exact location | What it does | Why it exists | Where used | If removed |
| --- | --- | --- | --- | --- | --- |
| Deployment identity | `capstone/k8s/base/deployment.yaml:1-11` | Names the Deployment and selects pods with `app: kk-payments`. | The selector must match the pod template or the Deployment controls nothing. | Deployment controller. | The Deployment reports zero ready replicas. |
| Replica count | `capstone/k8s/base/deployment.yaml:8` | Base default of two replicas. | Survives one pod failure. | Base; overlays override. | A single pod failure removes capacity. |
| Pod labels | `capstone/k8s/base/deployment.yaml:12-15` | Labels pods `app: kk-payments`. | The Service and Deployment selectors depend on this label. | Service endpoints and Deployment selector. | The Service has no endpoints. |
| Pull secret | `capstone/k8s/base/deployment.yaml:17-18` | References `kijani-registry-credentials`. | The registry is private even in the lab. | Pod image pull. | `ImagePullBackOff`. |
| Pod security context | `capstone/k8s/base/deployment.yaml:19-23` | Enforces non-root UID/GID 10001. | Limits damage if the process is compromised. | Pod sandbox. | The container may run as root. |
| Container image | `capstone/k8s/base/deployment.yaml:26` | Base image and tag. | Gives a known-good default before the pipeline sets the release tag. | Kubelet. | The pod has no image. |
| Pull policy | `capstone/k8s/base/deployment.yaml:27` | `Always`. | Ensures the cluster fetches the pushed tag instead of a stale cache. | Kubelet. | A reused tag can run an old image. |
| Container port | `capstone/k8s/base/deployment.yaml:28-30` | Names port `http` and sets `containerPort: 3001`. | The probes and Service target the named port. | Probes and Service. | Named-port references do not resolve. |
| ConfigMap reference | `capstone/k8s/base/deployment.yaml:31-33` | Injects `kk-payments-config` as environment variables. | Separates runtime environment configuration from the immutable image. | Application process. | The ConfigMap reference is unresolved, so the pod does not start with the expected `PORT` and environment settings. Version is baked into the image, not the ConfigMap. |
| Readiness probe | `capstone/k8s/base/deployment.yaml:34-39` | Checks `/health` every five seconds. | Prevents traffic from reaching a pod that is not ready. | Service endpoints. | Traffic reaches a starting or broken pod. |
| Liveness probe | `capstone/k8s/base/deployment.yaml:40-45` | Checks `/health` every ten seconds. | Restarts a hung process. | Kubelet. | A hung pod stays in the endpoint list. |
| Resources | `capstone/k8s/base/deployment.yaml:46-52` | Requests and limits CPU and memory. | Makes scheduling predictable and bounds resource use. | Scheduler and kubelet. | The pod can consume unbounded memory or be unschedulable. |
| Container security | `capstone/k8s/base/deployment.yaml:53-58` | Drops all capabilities and disallows privilege escalation; read-only root filesystem. | Reduces the attack surface. | Container runtime. | A compromised process has more privilege. |
| Service identity | `capstone/k8s/base/service.yaml:1-10` | Names the Service and selects `app: kk-payments`. | Gives the Deployment a stable DNS name and virtual IP. | Smoke test and in-cluster clients. | Clients cannot find the pods. |
| Service port | `capstone/k8s/base/service.yaml:11-14` | Port 3001 targets named port `http`. | Maps the Service port to the container port without duplicating the number. | Clients and port-forward. | The Service points at the wrong port. |
| Staging namespace | `capstone/k8s/overlays/staging/kustomization.yaml:3` | Sets `kijani-staging`. | Prevents staging resources from landing in `default`. | All staging resources. | Staging and production collide. |
| Staging config | `capstone/k8s/overlays/staging/kustomization.yaml:6-15` | Generates the staging ConfigMap with `NODE_ENV`, `PORT`, `RECEIPTS_BUCKET`, and `LOG_LEVEL`. | Keeps environment values out of the base and out of the image. | Deployment `envFrom`. | Staging uses base or production values. |
| Staging image | `capstone/k8s/overlays/staging/kustomization.yaml:14-16` | Sets the default image tag. | Gives a deterministic first deployment; Jenkins overrides it. | Staging Deployment. | The overlay references an unintended tag. |
| Staging replicas | `capstone/k8s/overlays/staging/kustomization.yaml:17-19` | Two replicas. | Staging is smaller than production but still highly available. | Staging Deployment. | Staging uses the base count by accident. |
| Staging labels | `capstone/k8s/overlays/staging/kustomization.yaml:20-23` | Adds `environment: staging` and includes selectors. | Makes environment visible in selectors and dashboards. | Deployment and Service selectors. | Environment is only visible in the namespace name. |
| Production namespace | `capstone/k8s/overlays/production/kustomization.yaml:3` | Sets `kijani-production`. | Separates the production release. | All production resources. | Production resources collide with staging. |
| Production config | `capstone/k8s/overlays/production/kustomization.yaml:6-15` | Generates the production ConfigMap with `NODE_ENV`, `PORT`, `RECEIPTS_BUCKET`, and `LOG_LEVEL`. | Production gets its own environment, bucket name, and log level. | Deployment `envFrom`. | Production runs with staging settings. |
| Production replicas | `capstone/k8s/overlays/production/kustomization.yaml:17-19` | Three replicas. | More capacity and failure tolerance. | Production Deployment. | Production runs at staging capacity. |
| Production labels | `capstone/k8s/overlays/production/kustomization.yaml:20-23` | Adds `environment: production`. | Makes the promotion target explicit in selectors. | Production resources. | Selectors do not distinguish environments. |

## Ansible

| Component | Exact location | What it does | Why it exists | Where used | If removed |
| --- | --- | --- | --- | --- | --- |
| Local inventory | `capstone/ansible/inventory.ini:1-2` | Targets localhost without SSH. | The playbook drives kubectl on the operator machine. | Both playbooks. | Ansible has no host to run against. |
| Kubeconfig variable | `capstone/ansible/staging.yml:8` | Expands `$HOME/.kube/config`. | Avoids hard-coding the user's home directory. | kubectl commands. | The playbook only works for one user. |
| Overlay variable | `capstone/ansible/staging.yml:9` | Resolves the staging overlay relative to the playbook. | Makes the playbook runnable from any working directory. | Apply task. | The apply path depends on the caller's current directory. |
| Kubeconfig check | `capstone/ansible/staging.yml:12-16` | Fails with a clear message if the kubeconfig is missing. | Prevents a confusing kubectl error later. | Before apply. | The failure is harder to diagnose. |
| Apply task | `capstone/ansible/staging.yml:18-22` | Runs `kubectl apply -k` with the context. | Applies the rendered overlay declaratively. | Staging. | The namespace exists but the workload does not. |
| Changed detection | `capstone/ansible/staging.yml:21-22` | Reports changed only for created or configured resources. | Makes Ansible output honest on repeat runs. | Apply result. | Every run reports changed, hiding real drift. |
| Image tag task | `capstone/ansible/staging.yml:24-28` | Sets the Deployment image to `{{ image_registry }}/{{ image_repository }}:{{ image_tag }}`. | `kubectl apply -k` resets the image to the overlay default; this task makes the playbook deploy the requested tag. | Staging; production has the same task. | Ansible re-runs an older image than the tag passed with `-e image_tag=...`. |
| Rollout wait | `capstone/ansible/staging.yml:30-33` | Waits for the Deployment to become available. | Prevents a green playbook on a failed rollout. | After apply and image update. | The playbook succeeds before pods are ready. |
| ConfigMap readback | `capstone/ansible/staging.yml:35-43` | Lists applied ConfigMaps and prints them. | Proves the hash-suffixed ConfigMap was created. | After rollout. | The demo cannot show which ConfigMap was applied. |

## Scripts

| Component | Exact location | What it does | Why it exists | Where used | If removed |
| --- | --- | --- | --- | --- | --- |
| Strict mode | `capstone/scripts/smoke-test.sh:2` | `set -euo pipefail`. | Stops on first error, unset variable, or failed pipe. | Entire script. | Failures can be skipped and reported as success. |
| Defaults | `capstone/scripts/smoke-test.sh:4-7` | Defaults namespace, service, and port. | Makes the script usable without arguments. | Local and CI. | Every call must repeat all values. |
| Port-forward | `capstone/scripts/smoke-test.sh:19-21` | Forwards a local port to the Service. | Tests the Service path without exposing a NodePort. | Health and total checks. | The test cannot reach the service. |
| Readiness loop | `capstone/scripts/smoke-test.sh:23-30` | Retries health for 30 seconds. | Absorbs the time between rollout and endpoint readiness. | Before assertions. | A fast test can fail spuriously. |
| Failure output | `capstone/scripts/smoke-test.sh:32-36` | Prints the port-forward log and exits non-zero. | Turns a timeout into an actionable error. | CI failure path. | The error is silent. |
| Health assertion | `capstone/scripts/smoke-test.sh:38-67` | Polls `/health` until the expected version appears, then asserts status, service, and version. | Catches a wrong image or failed process, and avoids the rollout race where an old pod still serves traffic. | Staging and production. | A wrong release can pass, or a correct release can fail during rollout. |
| Total assertion | `capstone/scripts/smoke-test.sh:69-79` | Posts two line items and asserts total 42. | Exercises the actual payment calculation, not only health. | Staging and production. | A broken calculation passes the smoke test. |
| Cleanup | `capstone/scripts/smoke-test.sh:11-17` | Kills port-forward and removes the log on exit. | Prevents orphan processes and leaked temp files. | Every exit path. | Repeated runs accumulate processes and files. |
| App verification | `capstone/scripts/local-pipeline.sh:20-26` | Copies the app into a temp directory and runs Node 18 tests in Docker. | Reproduces CI without polluting the repository with root-owned `node_modules`. | Local pipeline. | Tests depend on the host Node version or modify the repo. |
| Image build | `capstone/scripts/local-pipeline.sh:28-30` | Builds the Week 8 production image. | Creates the artifact to promote. | Local pipeline. | There is no image to deploy. |
| Registry push | `capstone/scripts/local-pipeline.sh:32-33` | Pushes to the local registry. | The cluster pulls from the registry. | Local pipeline. | Pods cannot pull the image. |
| Secret creation | `capstone/scripts/local-pipeline.sh:35-36` | Creates pull secrets in both namespaces. | Satisfies the Deployment's image pull secret. | Local pipeline. | `ImagePullBackOff`. |
| Staging deploy | `capstone/scripts/local-pipeline.sh:38-41` | Applies the overlay, sets the tag, waits for rollout. | Implements the staging half of the promotion. | Local pipeline. | No staging release. |
| Approval gate | `capstone/scripts/local-pipeline.sh:46-51` | Stops unless `APPROVE_PRODUCTION=yes`. | Makes local production promotion deliberate. | Local pipeline. | A local run always deploys production. |
| Production deploy | `capstone/scripts/local-pipeline.sh:53-56` | Applies production and waits. | Completes the promotion. | Local pipeline. | Production does not receive the tested artifact. |
| Pull-secret helper | `capstone/scripts/create-pull-secret.sh:10-18` | Creates or updates the registry secret per namespace. | Keeps the secret out of Git and makes it repeatable. | Jenkins and local pipeline. | Pods cannot authenticate to the registry. |
| Verify script | `capstone/scripts/verify.sh` | Runs formatting, validation, rendering, YAML parse, shell syntax, and Ansible syntax. | Gives one command that proves the code is structurally valid. | Local pre-commit and demo. | Validation depends on ad-hoc commands. |

## Week 8 application and image

| Component | Exact location | What it does | Why it exists | Where used | If removed |
| --- | --- | --- | --- | --- | --- |
| HTTP server | `week8/friday/src/index.ts:1-68` | Starts the server, exposes `/health` and `/total`, and handles shutdown. | The capstone deployable workload. | Deployment container. | There is no service to deploy. |
| Health route | `week8/friday/src/index.ts` (`/health`) | Returns status, service, and version. | Readiness, liveness, and smoke tests depend on it. | Probes and smoke test. | Pods never become Ready; smoke test fails. |
| Total route | `week8/friday/src/index.ts` (`/total`) | Parses line items and returns the calculated total. | Proves the business function works. | Smoke test. | Only process health is tested. |
| Version source | `week8/friday/Dockerfile.production` | Builds TypeScript, copies only runtime files, runs as UID 10001. | Smaller, non-root runtime image. | Registry and Deployment. | The image is larger and may run as root. |
| Baseline Dockerfile | `week8/friday/Dockerfile.baseline` | Reference image for the size comparison. | Provides the 52.4% reduction evidence. | Week 8 evidence. | The size claim loses its baseline. |
| Week 5 tests | `week5/friday/app/test/payments.test.js:1-54` | Tests the payment calculation. | Catches logic regressions before image build. | Verify stage. | Broken arithmetic can reach the cluster. |
| Week 5 harness | `week5/friday/app/test/harness.js:1-44` | Minimal test runner and assertions. | The project intentionally has no external test framework. | `npm test`. | Tests do not run. |
| Week 5 build | `week5/friday/app/scripts/build.js:1-35` | Copies source into `dist`. | Produces the artifact the app expects. | Build script. | `dist` is stale. |
| Week 5 lint | `week5/friday/app/scripts/lint.js:1-57` | Checks style and obvious errors. | Fails fast before tests. | `npm run lint`. | Style regressions pass. |

## Shell fragments to explain

| Fragment | Location example | Meaning | Removal effect |
| --- | --- | --- | --- |
| `set -euo pipefail` | `smoke-test.sh:2` | Exit on error, unset variable, or failed pipe. | Silent failures. |
| `"${1:-default}"` | `smoke-test.sh:4` | Use argument one or a default. | Empty namespace. |
| `2>&1` | `smoke-test.sh:20` | Send stderr to stdout. | Port-forward errors are lost. |
| `&` and `$!` | `smoke-test.sh:20-21` | Run in background and capture PID. | No port-forward or no cleanup. |
| `trap cleanup EXIT` | `smoke-test.sh:17` | Run cleanup on every exit. | Orphan processes. |
| `-fsS` | `smoke-test.sh:38` | Fail on HTTP error, silent progress, show errors. | HTTP 500 is treated as success. |
| `--dry-run=client -o yaml \| kubectl apply -f -` | `create-pull-secret.sh:11-17` | Generate YAML and apply it idempotently. | Secret creation is not repeatable. |
| `apply -k` | `local-pipeline.sh:39` | Apply a Kustomize overlay. | Namespace and ConfigMap wiring are skipped. |
| `set image` | `local-pipeline.sh:40` | Update the Deployment image. | The cluster runs the old tag. |
| `rollout status` | `local-pipeline.sh:41` | Wait for the Deployment to become available. | The pipeline can pass before pods are ready. |
| `|| true` | `Jenkinsfile:111-113` | Do not fail evidence collection. | A missing namespace fails the post-build. |

## Git and release facts

- Branch: `feature/capstone-track-a`.
- Base branch: `develop`, which already contains the Week 5 and Week 8 merge
  commits.
- Current pushed commit at the time this map was written:
  `01e729c3e72a333893ceb0f8b68db81e0bfe4622`.
- No `v1.0.0` tag exists yet. Tag the final validated commit before submission.
- PRs #10 and #11 contain the Week 5 and Week 8 work; their commits are in
  `develop`. Verify the GitHub PR state before claiming them as merged.

## Required honest limitations

- The production namespace is in the same minikube cluster as staging. State
  this clearly instead of claiming separate-cluster isolation.
- The PrometheusRule is not evaluated because the monitoring stack is not
  installed.
- The Week 10 receipt chain is not implemented. `RECEIPTS_BUCKET` is a
  configuration placeholder.
- The per-environment S3 buckets are created by Terraform, but the Week 8
  application does not read or write them.
- Peer review, demo, slides, and reflection are student-owned deliverables.

## Mock answers

**What starts the Jenkins job?**
`capstone/Jenkinsfile:15-17` defines `pollSCM('H/5 * * * *')`. The job's SCM
configuration points at the repository and the branch; SCM polling detects a
new commit and starts the pipeline. Removing the trigger leaves only manual
builds.

**Where does Terraform state live?**
`capstone/terraform/backend.tf` stores it in
`s3://kijaniosk-tfstate-545572979505/capstone/track-a/terraform.tfstate` with
encryption and `use_lockfile`. Removing the backend makes state local and
lockless.

**How does staging differ from production?**
Same base Deployment and Service, different Kustomize overlay: namespace,
ConfigMap literals, image tag, replicas, and environment label. Production also
requires the Jenkins approval gate. The limitation is that both namespaces are
in one minikube cluster.

**Why build once and promote the same tag?**
`Jenkinsfile:53-63` builds and pushes one tag; `Jenkinsfile:74` and
`Jenkinsfile:96` set that same tag in staging and production. Rebuilding for
production would test a different artifact.

**What proves the Service is correctly wired?**
`smoke-test.sh` forwards to `kk-payments-service` on port 3001, which targets the
named container port `http` (3001). If the selector, labels, target port, or
readiness probe is wrong, the smoke test times out or fails.

**What happens if the ConfigMap is removed?**
The Deployment's `envFrom` reference is unresolved, so the pod does not start
with the expected `PORT` and environment settings. The app may listen on the
wrong port, and the smoke test fails.

**Why is `APP_VERSION` not in the ConfigMap?**
`APP_VERSION` is part of the immutable image: the Dockerfile accepts it as a
build argument and bakes it into the image. The ConfigMap is for runtime
environment values. Putting the version in the ConfigMap would let a pod report
a version that does not match the image it is running. The image tag and the
`/health` version must agree.

**What happens if the readiness probe is removed?**
The Service can send traffic to a pod that has not finished starting. The
rollout can report available before the application is actually serving.

**What is the rollback path?**
Each Deployment revision is retained. `kubectl rollout undo deployment/kk-payments
-n kijani-production` returns to the previous ReplicaSet. The image tag remains
traceable to the commit that produced it.

**What did AI generate, and what did you verify?**
State the governance-log entry for each AI-assisted file and name the command
that verified it: `terraform validate`, `kubectl kustomize`, `bash -n`,
`ansible-playbook --syntax-check`, the Week 5 tests, and the smoke test. Do not
claim a live Jenkins run unless the build exists.
