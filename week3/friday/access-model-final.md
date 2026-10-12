# KijaniKiosk Access Model (final)

Owner: Dalton Wambui
Server: kijaniosk production node (payments service node)

This is Tuesday's access model, updated with the Friday additions (the `health/`
directory and the logrotate interaction).

## Accounts and groups

| Identity | UID | Type | Shell | Purpose |
|----------|-----|------|-------|---------|
| `kijaniosk` | 981 | system group | - | shared group for all KijaniKiosk service accounts |
| `kk-api` | 998 | system user | `/usr/sbin/nologin` | runs the API service (port 3000) |
| `kk-payments` | 999 | system user | `/usr/sbin/nologin` | runs the payments service (port 3001) |
| `kk-logs` | 996 | system user | `/usr/sbin/nologin` | runs the logging service (port 3002) |

All service accounts: no home directory, password locked, member of `kijaniosk`.
They are created/converged idempotently in Phase 2 (the accounts already existed
from Tuesday's hand-run lab).

## Directory ownership and modes

| Path | Owner:Group | Mode | Notes |
|------|-------------|------|-------|
| `/opt/kijaniosk` | root:kijaniosk | 0750 | no world access |
| `/opt/kijaniosk/config` | root:kijaniosk | 0750 | was `0777` on the dirty VM; tightened |
| `/opt/kijaniosk/releases` | root:kijaniosk | 0750 | deploy target |
| `/opt/kijaniosk/shared/logs` | root:kijaniosk | 2770 | setgid + ACLs (see below) |
| `/opt/kijaniosk/health` | root:kijaniosk | 0750 | new this week (see below) |

## Logs directory ACL model

`shared/logs` carries named-user ACLs **and default ACLs**, so anything created
inside inherits the same access (this is what makes logrotate safe):

```
# getfacl /opt/kijaniosk/shared/logs
user::rwx
user:kk-logs:rwx
user:kk-api:rwx
user:kk-payments:r-x      # missing on the dirty VM; added in Phase 3
group::rwx
mask::rwx
other::---
default:user::rwx
default:user:kk-logs:rw-
default:user:kk-api:rw-
default:user:kk-payments:r--
default:group::rwx
default:mask::rw-
default:other::---
```

Intent: **kk-api and kk-logs write**; **kk-payments reads only** (audit
correlation); nobody else has access.

## Logrotate interaction

logrotate recreates the log file after rotation using the config's `create`
directive. Two details matter:

1. `create 0660 root kijaniosk`: the mode's **group bits become the ACL mask**.
   Using `0640` would set the mask to `r--`, silently leaving `kk-api` unable to
   *write* the rotated file. `0660` keeps `rw` in the mask so the default ACLs
   grant `kk-api`/`kk-logs` write access on the new file.
2. `su root kijaniosk`: because `shared/logs` is group-writable as part of the
   ACL model, logrotate refuses to run without an explicit `su` directive.

Verified after a forced rotation:

```
# getfacl /opt/kijaniosk/shared/logs/api.log   (newly created)
user::rw-
user:kk-logs:rw-
user:kk-api:rw-
user:kk-payments:r--
```

and `sudo -u kk-api` can write to the recreated file (see
`post-remediation-verification.txt`).

## The `health/` directory (new)

- **Owner/group:** `root:kijaniosk`, mode `0750`.
- **Who writes:** the provisioning script runs as root and writes
  `last-provision.json`, then `chown kk-logs:kijaniosk` + `chmod 0640`.
- **Who reads:** the `kijaniosk` group (members `kk-api`, `kk-payments`,
  `kk-logs`), so the monitoring system reads it without sudo. Amina's regular
  user reads it by being added to `kijaniosk` (or an explicit read ACL).
- **ACLs:** none needed, standard group read is sufficient, and the file is
  short-lived (overwritten every run).
