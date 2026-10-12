# Hardening decisions — explained for Nia

This page sets out the security choices behind the KijaniKiosk staging
environment in plain language. It covers the two layers we built: the cloud
infrastructure Terraform creates, and the operating-system protections Ansible
applies to every server. Together they mean that if any one piece is compromised
the damage stays contained, and that the whole environment can be rebuilt
identically rather than drifting server by server through hand edits.

Two ideas run through every choice below. The first is **least privilege**: each
part receives only the access it truly needs, and nothing beyond that. The second
is **defence in depth**: no single control is trusted on its own, so if one layer
gives way the next still holds. That is why the same goal — protecting the
payments flow — is pursued at the network, the operating system and the file
level all at once.

| Control | What it does | Risk mitigated |
|---------|--------------|----------------|
| Restricted network exposure (`aws_security_group`) | Only the operator's current address can reach the management port; application ports are open only to other servers on the private network. | A stranger on the internet cannot even see the services, let alone connect. |
| Key-based access, no passwords (`aws_key_pair`) | Servers accept only a cryptographic key we hold; password login is impossible. | Removes password guessing and entry with a stolen password. |
| Encrypted, versioned remote state (`backend "s3"`) | The record of what was built is kept remotely, encrypted at rest, versioned, and locked while a run is in progress. | Losing or tampering with the infrastructure record, and two people changing it simultaneously. |
| Operator-IP allow-listing (`admin_cidr`) | The management door opens to one known address instead of the whole world. | Everyone else is shut out before a login is even attempted. |
| No privilege escalation (`NoNewPrivileges`, `CapabilityBoundingSet`, `AmbientCapabilities`) | Each service runs with no way to gain extra powers during its life. | A bug in a service cannot be turned into control of the server. |
| Read-only operating system (`ProtectSystem=strict`, `ReadWritePaths`) | The service sees the system as read-only and can write only to its own log area. | Stops an intruder leaving permanent changes behind. |
| Private scratch space (`PrivateTmp`) | Each service gets its own private temporary area, invisible to the others. | Stops services spying on each other through shared temporary files. |
| Least-privilege system calls (`SystemCallFilter`, `SystemCallArchitectures`) | Services may use only the operations they actually need and nothing else. | Closes unused, dangerous doorways an attacker could otherwise exploit. |
| Protected kernel and clock (`ProtectKernel*`, `ProtectControlGroups`, `ProtectClock`, `ProtectHostname`, `ProtectProc`, `ProcSubset`) | Services cannot alter kernel settings, the system clock, control groups, or the identity of the machine. | Prevents system-wide manipulation and evasion of logging. |
| Outbound network restriction (`IPAddressDeny`, `IPAddressAllow`) | A service may talk only to the private network, never straight out to the internet. | Limits data theft and an attacker "phoning home". |
| Log access model (permissions + access control lists) | Only the API and logging identities may write logs; the payments identity may only read them. | Payments cannot rewrite history; the audit trail stays trustworthy. |
| Rotation-safe logs (log rotation policy) | When logs are archived, the new file inherits exactly the same protections. | Prevents archived logs from accidentally becoming readable by everyone. |

The payments service was measured against the system's standard exposure scale
and scored 1.2, comfortably inside the 2.5 ceiling we set, and it starts and
reports itself healthy. The other two services scored the same.

## What this posture does not protect against

Honesty matters more here than a perfect score. The three services in this
environment are stand-ins: they prove the pipeline works, but they are not the
real KijaniKiosk application, so some protections may need small exceptions once
the real software runs inside them. The environment trusts the private network,
so a compromised server inside it could still reach the application ports of the
others. Secrets sit in plain configuration files readable by the service rather
than in a dedicated vault with automatic rotation. The management door is pinned
to the operator's current address, which is safe but brittle — if that address
changes, access is lost until it is updated. Most importantly, this work secures
the servers, not the cloud account that controls them: whoever holds the account's
keys can undo every protection here. The infrastructure record, though encrypted
and versioned, still lives in a single region with no cross-region copy. There is
also no monitoring or alerting yet, so a determined attacker who works quietly
might go unnoticed, and access is not yet reviewed on a schedule. Finally, it is
worth being clear about what a hardening score is: it measures how few dangerous
capabilities a service keeps, not whether the data it handles is correct, private
in transit, or backed up. A good score is one signal, not a certificate of safety.

In short: the environment is reproducible, tightly scoped, and explains itself —
but it is a strong foundation, not a finished security program. The next steps
would be a managed secrets store, monitoring and alerts, and protecting the cloud
account itself with the same rigour.
