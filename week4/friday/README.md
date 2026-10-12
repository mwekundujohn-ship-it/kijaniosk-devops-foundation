# Week 4 — IaC Pipeline (Friday)

Terraform provisions, Ansible configures, one script ties them together.

**Path used: cloud.** Multipass (no snapd on the controller) and MinIO (its
open-source server is archived and no longer distributed) were both unavailable,
so the brief's optional cloud path is used: AWS EC2 for compute and an S3 bucket
with an S3-native state lock for the remote backend. `pipeline.sh` still contains
the Multipass code path and accepts `multipass` as an argument. See
`environment-setup.md` for the full rationale and tool versions.

## Deliverables

| File | What it is |
|------|------------|
| `terraform/` | Root config (`main`, `variables`, `outputs`, `providers`, `backend`, `data`) + reusable `modules/app_server/`, called with `for_each`. |
| `ansible/` | `kijaniosk.yml`, `ansible.cfg`, `group_vars/`, `host_vars/`, `templates/` (units, env, journald, logrotate, health). |
| `pipeline.sh` | Terraform apply -> extract IPs -> write `inventory.ini` -> Ansible. Exits non-zero on failure. |
| `pipeline-run1.log` | First run: Terraform creates 6 resources, Ansible `changed=18` per host. |
| `pipeline-run2.log` | Second run: Terraform `0 added, 0 changed, 0 destroyed`, Ansible `changed=0`. |
| `hardening-decisions.md` | The Nia document (881 words, 12-row control table, honest gaps). |
| `destroy-output.txt` | `terraform destroy` proving clean teardown (6 destroyed). |
| `environment-setup.md` | Tool versions and reproducibility notes. |
| `verification-output.txt` | Post-run evidence: services active, scores 1.2, Challenge D, ACLs, journal. |
| `reflection.md` | The three reflection answers. |
| `scripts/bootstrap-backend.sh` | Creates the S3 bucket + SSH key the backend depends on. |

## Run

```bash
./scripts/bootstrap-backend.sh          # once: backend bucket + EC2 key pair
./pipeline.sh cloud                     # terraform apply -> inventory -> ansible
./pipeline.sh cloud                     # second run: 0 drift, changed=0
cd terraform && terraform destroy       # teardown
```

## Notable evidence

- kk-payments `exposure = 1.2` (target < 2.5) **and** active.
- Challenge D verified: the sandboxed payments service can read its environment
  file.
- Firewall: SSH only from the operator IP, app port only from the VPC.
- Journal persistence on and the journal directory present.
