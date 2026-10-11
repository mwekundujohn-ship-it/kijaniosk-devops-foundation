# kk-payments.service — hardening log

Target: exposure score **< 2.5** (stretch < 2.0). Starting point: **9.2 UNSAFE**.

## Iterative hardening

Each row was applied, reloaded, and re-scored with
`systemd-analyze security kk-payments.service`:

| Step | Directive(s) added | Exposure |
|------|--------------------|----------|
| 0 | (dirty VM baseline) | 9.2 UNSAFE |
| 1 | `NoNewPrivileges`, `PrivateTmp`, `ProtectSystem=strict`, `ProtectHome`, `ProtectKernel*`, `ProtectControlGroups`, `ProtectClock`, `ProtectHostname` | 6.3 |
| 2 | `RestrictAddressFamilies`, `RestrictNamespaces`, `RestrictRealtime`, `RestrictSUIDSGID`, `LockPersonality`, `MemoryDenyWriteExecute` | 4.6 |
| 3 | `SystemCallArchitectures=native`, `SystemCallFilter=@system-service` + `~@privileged @resources @obsolete`, `CapabilityBoundingSet=`, `AmbientCapabilities=` | 2.9 |
| 4 | `ProtectProc=invisible`, `ProcSubset=pid`, `UMask=0027`, `ReadWritePaths=/opt/kijaniosk/shared/logs` | 1.3 |
| 5 | `IPAddressDeny=any` + `IPAddressAllow=localhost`, `10.0.1.0/24` | 1.3 |
| 6 | tighten `SystemCallFilter` (`~@mount @debug @cpu-emulation @swap @clock`) | **1.2 OK** |

Result: **1.2** — well inside both the < 2.5 target and the < 2.0 stretch goal.

## Directives I evaluated and rejected

1. **`DynamicUser=yes`** — would allocate an ephemeral UID at each start.
   Rejected because payments must own `/opt/kijaniosk/config/payments-api.env`
   and write stable log files; a dynamic UID cannot own persistent files across
   restarts, which would break the EnvironmentFile and the ACL model.

2. **`PrivateNetwork=yes`** — would give the unit a network namespace with only
   `lo`. Rejected because kk-payments must `IPAddressAllow` the internal
   `10.0.1.0/24` tier; cutting it off from the network contradicts the service's
   purpose. I kept `IPAddressDeny=any` + explicit `IPAddressAllow` instead,
   which restricts *egress* without removing connectivity.

3. **`ProtectSystem=full`** (instead of `strict`) — rejected as weaker: `full`
   leaves `/usr` read-only only, whereas `strict` makes the whole filesystem
   read-only except `ReadWritePaths`. `strict` is the stronger of the two and
   cost nothing once `ReadWritePaths` was declared.

## Final unit

```ini
[Unit]
Description=KijaniKiosk kk-payments service
After=network-online.target
Wants=network-online.target
After=kk-api.service
Wants=kk-api.service

[Service]
Type=simple
User=kk-payments
Group=kijaniosk
EnvironmentFile=/opt/kijaniosk/config/payments-api.env
Environment=PYTHONDONTWRITEBYTECODE=1
ExecStart=/usr/bin/socat TCP-LISTEN:3001,fork,reuseaddr /dev/null
Restart=on-failure
RestartSec=2
ReadWritePaths=/opt/kijaniosk/shared/logs
NoNewPrivileges=yes
PrivateTmp=yes
PrivateDevices=yes
ProtectSystem=strict
ProtectHome=yes
ProtectKernelTunables=yes
ProtectKernelModules=yes
ProtectKernelLogs=yes
ProtectControlGroups=yes
ProtectClock=yes
ProtectHostname=yes
ProtectProc=invisible
ProcSubset=pid
RestrictRealtime=yes
RestrictSUIDSGID=yes
LockPersonality=yes
MemoryDenyWriteExecute=yes
RestrictNamespaces=yes
RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6
SystemCallArchitectures=native
SystemCallFilter=@system-service
SystemCallFilter=~@privileged @resources @obsolete @mount @debug @cpu-emulation @swap @clock
CapabilityBoundingSet=
AmbientCapabilities=
UMask=0027
IPAddressDeny=any
IPAddressAllow=localhost
IPAddressAllow=10.0.1.0/24

[Install]
WantedBy=multi-user.target
```

For comparison, `kk-api` and `kk-logs` were hardened with the same directive set
and score **1.3** each.
