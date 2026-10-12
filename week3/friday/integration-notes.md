# Integration notes: where the hardening fought the requirements

Four conflicts that came up when the systemd hardening, the ACL access model,
logrotate, and the existing "dirty" VM state were combined. Each one is a real
trade-off, not just a config tweak.

## Challenge 1: `ProtectSystem=strict` vs. writing under `/opt`

**Conflict.** `ProtectSystem=strict` mounts the whole filesystem read-only except
the paths in `ReadWritePaths`. But the services must write to
`/opt/kijaniosk/shared/logs`, which lives under `/opt`.

**Options.**
1. Use `ProtectSystem=full`: weaker protection, keeps `/usr` read-only only.
2. Add `ReadWritePaths=/opt/kijaniosk/shared/logs` and keep `strict`.

**Choice: option 2.** `ReadWritePaths` punches a hole for *exactly* the logs
directory and nothing else, so the services still cannot touch `/opt/kijaniosk/config`
or `/opt/kijaniosk/releases`. `full` would have been a blunt downgrade of the
whole sandbox to solve one path.

**Why it matters.** `EnvironmentFile=/opt/kijaniosk/config/payments-api.env` is
read by systemd *before* the sandbox is applied, so the read-only filesystem does
not block it. That is a detail worth confirming rather than assuming.

## Challenge 2: kk-logs must read the health file without sudo

**Conflict.** The health report is written by the provisioning script (root), but
Amina's monitoring system must read it unprivileged.

**Options.**
1. A read ACL for Amina's user on the file.
2. `chown kk-logs:kijaniosk` + `chmod 0640`, relying on group membership.

**Choice: option 2**, plus adding Amina's operational account to `kijaniosk`.
Group read is simpler, survives file recreation (the script re-applies ownership
each run), and does not require tracking individual usernames in the script.

## Challenge 3: logrotate silently broke the ACL access model

**Conflict.** After rotation, the *new* log file did **not** have the write access
the ACL model promised. Two separate traps:

- logrotate refused to rotate at all: *"parent directory has insecure
  permissions"* because `shared/logs` is group-writable by design. Fix: add
  `su root kijaniosk`.
- With `create 0640`, the ACL **mask** inherited from the mode's group bits was
  `r--`, so `kk-api` could read but not write the recreated log. Fix:
  `create 0660` so the mask stays `rw-`.

**Options.** A `postrotate` script that re-applies ACLs vs. getting the `create`
mode right. **Choice:** fix the mode + `su` directive. It is declarative, with no
script drift, and keeps a `postrotate` `systemctl reload-or-restart` for the log fd.

**Why it matters.** This only shows up *after* a rotation. `logrotate --debug`
alone did not reveal it; I had to force a real rotation and then test as `kk-api`.

## Challenge 4: the "dirty" VM state blocked the provisioner

**Conflict.** The brief says the script must converge a dirty VM. In this lab the
dirty state included a `curl` package hold (`apt-mark hold curl`, lookalike for
the dangerous uptime/ss/ip holds) and a stray `ufw deny 3001` from Tuesday.

**Options.**
1. Assume a clean baseline and document the requirement.
2. Detect and fix each dirty condition in an early phase.

**Choice: option 2.** Phase 1 detects `apt-mark showhold` output and lifts holds
only for the four packages the script manages (so a hold on `curl` is removed),
and Phase 6 reconciles ufw so the only inbound rules are 3000/3001/3002 from
`10.0.1.0/24` plus SSH, and the stray `deny 3001` is gone. The script is then
genuinely idempotent: it was run twice (`provision-run-dirty.log` from the dirty
state, `provision-run-clean.log` from the already-provisioned state) and both
finished with **19/19 checks passing, exit 0**.
