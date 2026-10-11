# Week 3 — Production Server Foundation (Friday)

Idempotent provisioning, systemd hardening, firewall reconciliation and log
rotation for the KijaniKiosk production node.

## Deliverables

| File | What it is |
|------|------------|
| `kijaniosk-provision.sh` | The single idempotent provisioner (8 phases + final verification; exits non-zero on any failed check). |
| `pre-provisioning-audit.txt` | What was wrong on the "dirty" VM and how each item was interpreted. |
| `provision-run-dirty.log` | First run from the dirty state — 19/19 checks, exit 0. |
| `provision-run-clean.log` | Second run from the already-provisioned state — 19/19 checks, exit 0 (idempotency proof). |
| `access-model-final.md` | Accounts, directory modes, ACLs and the logrotate interaction. |
| `kk-payments-hardening.md` | Iterative hardening 9.2 → 1.2 with rejected directives. |
| `post-remediation-verification.txt` | Forced logrotate + `kk-api` write test + `getfacl` evidence. |
| `integration-notes.md` | The four hardening-vs-requirements conflicts and how they were resolved. |
| `hardening-decisions.md` | Non-technical explanation for Nia. |

## Run

```bash
sudo ./kijaniosk-provision.sh          # idempotent; safe to re-run
systemd-analyze security kk-api.service kk-payments.service kk-logs.service
```

The script converges on either a fresh or a previously-configured server: it
detects and lifts stale package holds, removes stray firewall rules, recreates
any missing users/directories/ACLs, and re-verifies at the end.
