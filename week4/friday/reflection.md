# Reflection

## 1. Where two requirements conflicted

The clash showed up between Requirement 2 and Requirement 5, and Challenge D is
where it surfaced. Week 3 put the payments service behind a read-only filesystem
so it cannot modify anything outside its own log area, but the service still has
to read its own configuration when it starts. My first instinct was to leave that
configuration alongside everything else in the read-only region, and that looked
fine on paper until the service could not read it. The fix was to place the
configuration where the sandboxed unit could still reach it, and then to confirm
by reading the file *as the service account* that it was genuinely reachable in
the sandbox rather than merely present on disk. The lesson I took from it is that
hardening is not a set-and-forget setting: a control that is right in isolation
can quietly break the very thing it is meant to defend, and the only reliable way
to know is to test from the same vantage point the service has.

## 2. One sentence, translated for Tendo

For Nia I wrote: *"The service sees the system as read-only and can write only to
its own log area."* For Tendo I would write: *"`ProtectSystem=strict` mounts the
root filesystem read-only inside the unit's namespace, with
`ReadWritePaths=/opt/kijaniosk/shared/logs` carved out as the sole writable
exception."* The technical sentence is exact and reviewable — it names the
directive and the path, so another engineer can reproduce it — but it drops the
sense of why anyone outside engineering should care. The plain sentence gives up
that precision in exchange for a risk statement a board can act on. Neither is
free: each is complete for one audience only, which is precisely why the brief
asks for both.

## 3. The most fragile handoff

The most fragile handoff is the SSH boundary between the control plane and the
targets, and in particular the operator's address being allow-listed on the
security group. The pipeline assumes the machine running Ansible can reach the
servers on the management port, and that grant is pinned to the operator's public
address at plan time. In a real environment that address moves: a VPN, a
load-balanced office egress, or a CI runner will present something different, and
the first task fails as "unreachable" with no useful error to explain why. What
makes it fragile is that it is silent — nothing in the pipeline notices the
allow-list has gone stale, it simply cannot connect. To make it robust I would
first need to know how operators and any automation actually reach these hosts:
a stable bastion or jump host, a VPN or private address space, or an access method
built on machine identity. With that answered, I would stop pinning one person's
address and route management access through that known, stable entry point —
allowing the management port only from a bastion subnet, or only from inside the
private network.
