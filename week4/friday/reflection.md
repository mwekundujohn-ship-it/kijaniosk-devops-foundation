# Reflection

## 1. Where two requirements conflicted

The conflict surfaced in Requirement 2 versus Requirement 5, through Challenge D.
The Week 3 hardening puts the payments service behind a read-only filesystem so
it cannot modify anything outside its own log area. But the service still has to
read its own configuration at startup. My first instinct — keep the
configuration with everything else under the system's read-only area — looked
correct until the service failed to read it. I had to move the configuration into
the writable application tree and then prove, by reading the file *as the service
account*, that it was actually reachable in the sandboxed context rather than
just existing on disk. I learned that hardened settings are not "set and forget":
a control that is correct in isolation can silently break the thing it is meant
to protect, and the only way to know is to test from the same vantage point the
service has.

## 2. One sentence, translated for Tendo

For Nia I wrote: *"The service sees the system as read-only and can write only to
its own log area."* For Tendo I would write: *"`ProtectSystem=strict` mounts the
root filesystem read-only inside the unit's namespace, with
`ReadWritePaths=/opt/kijaniosk/shared/logs` carved out as the sole writable
exception."* The technical version is precise and reviewable — it names the exact
directive and path, so another engineer can reproduce it — but it loses the sense
of *why* anyone outside engineering should care. The plain version trades that
precision for a risk statement the board can act on. Nothing is free in the
translation: each version is only complete for one audience, which is exactly why
the brief asks for both.

## 3. The most fragile handoff

The most fragile handoff is the SSH boundary between the control plane and the
targets — specifically, the operator's address being allow-listed on the security
group. The pipeline assumes the machine running Ansible can reach the servers on
the management port, and that grant is pinned to the operator's public address at
plan time. In a real environment that address is dynamic: a VPN, a load-balanced
office egress, or a CI runner will present a different address, and the very
first task becomes "unreachable" with no useful error. It is fragile because it
is silent — nothing in the pipeline detects that the allow-list is stale; it just
fails to connect. To make it robust I would need to know how operators and any
automation reach these hosts: a stable bastion or jump host, a VPN or private
network address space, or a machine-identity-based access method. Given that, I
would stop pinning a single user's address and instead route access through that
known, stable entry point — for example, allowing the management port only from a
bastion subnet or only from within the private network.
