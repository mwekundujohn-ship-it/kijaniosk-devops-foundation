# KijaniKiosk Capstone — Track A

Track A is the infrastructure-first capstone path. This directory connects the
existing Week 3–8 work into a staging-to-production promotion flow that can be
demonstrated locally and explained line by line.

## Delivered connection

1. Terraform creates the `kijani-staging` and `kijani-production` namespaces and
   one private S3 receipts bucket per environment for Week 10.
2. Kustomize renders the same `kk-payments` Deployment and Service into each
   namespace with environment-specific ConfigMaps, replicas, and image tags.
3. Ansible applies the staging or production overlay and waits for the rollout.
4. The Jenkins pipeline verifies the Week 5 application, builds and pushes the
   Week 8 production image, deploys staging, runs a smoke test, waits for a
   human approval, then promotes the same image to production.
5. A PrometheusRule describes the two minimum operational signals for
   `kk-payments`: no available replicas and container restarts.

## Promotion flow

```
commit -> Jenkins pollSCM -> verify (lint, tests)
       -> build image -> push to local registry
       -> apply staging overlay -> set image -> rollout status
       -> smoke test staging
       -> manual approval
       -> apply production overlay -> set image -> rollout status
       -> smoke test production
```

## Local commands

```bash
terraform -chdir=capstone/terraform init
terraform -chdir=capstone/terraform apply
ansible-playbook -i capstone/ansible/inventory.ini capstone/ansible/staging.yml
capstone/scripts/local-pipeline.sh
APPROVE_PRODUCTION=yes capstone/scripts/local-pipeline.sh
```

The local pipeline builds the image as `localhost:5000/kk-payments:<tag>` and
deploys it as `host.minikube.internal:5000/kk-payments:<tag>`. Both names point
at the same local registry; the first is used by the host Docker daemon and the
second is resolvable from inside minikube.

## Validation

```bash
capstone/scripts/verify.sh
```

This runs `terraform fmt -check`, `terraform validate`, renders both Kustomize
overlays, parses the monitoring YAML, checks every shell script with `bash -n`,
and runs `ansible-playbook --syntax-check` on both playbooks.

## What is verified

- Terraform formatting and validation.
- Kustomize rendering for staging and production.
- Ansible syntax.
- Shell syntax.
- Jenkinsfile syntax through the Jenkins declarative linter when Jenkins is
  running.
- The Week 5 test suite and Week 8 image build through the local pipeline.
- A full Jenkins build: build #2 succeeded for `2.4.0-2a84c81`, including
  staging smoke, the production approval gate, production smoke, and archived
  evidence in `capstone/evidence/jenkins-build-2/`.

## What is not verified

- PrometheusRule evaluation. The rule requires kube-state-metrics and the
  Prometheus Operator; neither is installed in the current minikube cluster.
- The Week 10 serverless receipt chain. No Week 10 specification or code exists
  in the repository. `RECEIPTS_BUCKET` is wired into the ConfigMaps but the
  Week 8 application does not consume it yet.
- A real peer review. The request template is in `docs/peer-review-request.md`;
  a named reviewer must still complete it.

## Security notes

- The pull-secret helper defaults to lab-only credentials. Supply real values
  through `REGISTRY_USER`, `REGISTRY_PASSWORD`, and `REGISTRY_EMAIL`; never
  commit them.
- The S3 buckets are private, versioned, and encrypted with SSE-S3. The capstone
  buckets use `force_destroy = true` because they are lab resources.
- The production namespace is a promotion target inside the same minikube
  cluster, not a separate AWS account. This is a documented capstone
  limitation, not a claim of multi-account production isolation.
