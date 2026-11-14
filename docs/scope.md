# KijaniKiosk Capstone - Scope and Success Criteria

**Author:** Dalton Wambui  
**Track:** A - Infrastructure-first  
**Repository:** `mwekundujohn-ship-it/kijaniosk-devops-foundation`  
**Release:** `v1.0.0` (`feature/capstone-track-a`)

## Problem

KijaniKiosk can build the `kk-payments` service, but a release is not trustworthy unless the same tested image can move from a staging environment to production through one repeatable, observable, permission-gated path. The capstone must prove that infrastructure, configuration, deployment, smoke testing, approval, and runtime recovery are connected rather than separate weekly exercises.

## In scope

1. Terraform provisions the `kijani-staging` and `kijani-production` namespaces and separate private, versioned, SSE-S3 receipt buckets.
2. Kustomize renders one `kk-payments` Deployment and Service into both namespaces, with environment-specific ConfigMaps (`NODE_ENV`, `DB_HOST`, `RECEIPTS_BUCKET`, `LOG_LEVEL`) and replica counts.
3. Ansible applies the selected overlay, sets the image tag, and waits for the Kubernetes rollout.
4. Jenkins verifies the Week 5 application, builds and pushes the Week 8 production image, deploys staging, runs HTTP smoke tests, stops for human approval that records the approver and reason, then promotes the same image to production.
5. A PrometheusRule defines three `kk-payments` alerts for unavailable replicas, container restarts, and missing Service endpoints.

## Out of scope

- **Week 10 serverless receipt chain.** The Week 10 specification and function code are not available in this repository. The per-environment buckets and `RECEIPTS_BUCKET` key are prepared, but no serverless producer is claimed.
- **Separate production cluster or AWS account.** Production is a namespace in the same minikube cluster. This demonstrates promotion and isolation logic, not production-grade failure isolation.
- **A live database.** `DB_HOST` is present and differs by environment, but no database workload is deployed and the Week 8 service does not query it.
- **Live alert evaluation.** The PrometheusRule requires the Prometheus Operator and kube-state-metrics; neither is installed, so the rule is syntax-checked but not firing.

## Measurable success criteria

| Criterion | Evidence |
|---|---|
| Terraform formats and validates | `terraform fmt -check` and `terraform validate` pass |
| Both overlays render with different ConfigMaps | `kubectl kustomize` output and rendered manifest evidence |
| Jenkins builds one image and promotes that same tag | Jenkins console shows one build/push and the same tag in both namespaces |
| Staging proves health before approval | Smoke test returns `status=ok`, the expected version, and `total=42` |
| Human approval is recorded | `capstone/evidence/approval.txt` contains approver, reason, and tag |
| Production serves the promoted image | `kubectl` shows 3/3 ready; production smoke test passes |
| A pod fault self-heals | Deleted staging pod is recreated and the Deployment returns to 2/2 ready |
| Architecture and decisions are explainable | README, architecture diagram, AI governance log, slides, and oral drill |

## Architecture

The labelled diagram is delivered as `docs/architecture.png` (source: `docs/architecture.dot`). Solid arrows show implemented, exercised flows. Dashed red arrows show explicitly unimplemented or unevaluated scope.
