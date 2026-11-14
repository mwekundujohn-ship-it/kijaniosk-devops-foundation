# Test Plan - Track A Release and Demo

**Author:** Dalton Wambui  
**Prepared:** 2026-11-14  
**Scope:** Track A staging-to-production promotion, runtime recovery, and evidence quality.

This plan was written before the review/demo session so that the checks are explicit and repeatable rather than chosen after seeing the result. Commands assume the repository root and a running minikube cluster.

## Test environment

| Item | Value |
|---|---|
| Cluster | minikube, namespaces `kijani-staging` and `kijani-production` |
| Registry | `localhost:5000` (cluster address `host.minikube.internal:5000`) |
| Jenkins | `http://localhost:8080/job/kijanikiosk-capstone` |
| Image | `kk-payments:<package-version>-<short-sha>` |
| Expected staging replicas | 2 |
| Expected production replicas | 3 |
| Smoke endpoint | `/health` and `POST /total` through a port-forwarded Service |

## Cases

| ID | Area | Steps | Expected result | Evidence |
|---|---|---|---|---|
| T01 | Terraform syntax | `terraform -chdir=capstone/terraform fmt -check` and `terraform -chdir=capstone/terraform validate` | Both exit 0; no formatting or validation errors | `capstone/evidence/demo/verify.txt` |
| T02 | Environment configuration | `kubectl kustomize capstone/k8s/overlays/staging` and the production equivalent; inspect `DB_HOST` | Staging and production render different `DB_HOST`, `NODE_ENV`, `RECEIPTS_BUCKET`, and replica counts | rendered output in `capstone/evidence/demo/config-render.txt` |
| T03 | Jenkins pipeline | Trigger a build, wait for staging smoke, approve production with a reason | One image is built and pushed; staging smoke passes; approval is recorded; production smoke passes | Jenkins console and `capstone/evidence/approval.txt` |
| T04 | Negative smoke test | `capstone/scripts/smoke-test.sh kijani-production deliberately-wrong-version` | Script exits non-zero after reporting a version mismatch; it must not print `PASS` | `capstone/evidence/demo/negative-smoke.txt` |
| T05 | Pod self-healing | Delete one staging pod, then watch the Deployment | A replacement pod becomes Ready and the Deployment returns to 2/2 available | `capstone/evidence/demo/fault-handling.txt` |
| T06 | Same image promotion | Compare the image field in both namespaces after a successful build | Both namespaces run the same `kk-payments:<tag>` image | `capstone/evidence/demo/image-parity.txt` |
| T07 | Production health | Run the smoke test against production | `/health` returns `status=ok`, `service=kk-payments`, expected version; `/total` returns `42` | `capstone/evidence/demo/production-smoke.txt` |
| T08 | Secret handling | `git grep` for common key/token patterns; inspect tracked files | No tracked cloud key, registry password, or GitHub token | `capstone/evidence/demo/secret-scan.txt` |
| T09 | Diagram accuracy | Compare each solid arrow in `docs/architecture.png` to a file or live object | Every solid connection has an implementation; unimplemented paths are dashed red | architecture review note in `docs/demo-script.md` |
| T10 | Submission documents | Open each PDF and check page count and content | Scope is 1 page; slides are 6-10 pages; reflection is 1 page; diagram, governance log, and feedback log exist | `pdfinfo` output and file listing |

## Exit criteria

- T01-T03 and T05-T08 must pass for the live demo.
- T04 must fail in the expected, controlled way; a failing negative test is a pass for the test design.
- T09 and T10 must be checked before submission.
- Any check that cannot be run must be labelled "not verified" in `capstone/docs/requirement-matrix.md`; it must not be described as passing.

## Known constraints

- PrometheusRule evaluation is not in this plan because the Prometheus Operator and kube-state-metrics are not installed.
- Week 10 serverless receipt delivery is not in this plan because the specification and function code are absent.
- Peer review is a human activity and is tracked separately in `docs/peer-feedback-log.md`.
