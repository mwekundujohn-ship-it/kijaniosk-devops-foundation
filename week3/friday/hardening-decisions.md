# KijaniKiosk Production Foundation — decisions explained for Nia

> **Draft scaffold — WRITE THIS IN YOUR OWN WORDS.**
> Nia is non-technical. Keep it plain: what changed, why it protects the
> business, what is still risky, and the cost of getting it wrong. Aim for
> 800–1000 words. Replace every `<...>` prompt with your own sentences.

## 1. What we built, in one paragraph

<Say plainly: we hardened the three KijaniKiosk services so a break-in in one
cannot spread, locked down file access so only the right service can read/write
each thing, and made setup repeatable so it works the same on a fresh or a messy
server. Avoid jargon.>

## 2. The decisions and what they mean for the business

<Fill the table. "Benefit" should be business language (e.g. "a compromised
payments process cannot read the API keys"). Rows already listed — add any you
want.>

| Decision | Technical detail | Business benefit | Cost / trade-off |
|----------|------------------|------------------|------------------|
| Dedicated service accounts | `kk-api/kk-payments/kk-logs`, nologin, no password | A bug in one service cannot act as another | Slightly more admin overhead |
| Least-privilege file access | ACLs: `kk-api`/`kk-logs` write logs, `kk-payments` read-only | Payments can't tamper with logs; audit trail stays trusted | ACLs must be re-applied on new files (we fixed logrotate for this) |
| Sandboxed services | `ProtectSystem=strict`, `PrivateTmp`, `NoNewPrivileges`, syscall filters | Even if a service is exploited, blast radius is tiny | Some services need exceptions to work |
| Network restriction | `IPAddressAllow` internal tier only | Data can't be exfiltrated to the internet | Must update the allow-list when we add tiers |
| Idempotent provisioning | one script converges any server state | Ready for the growth target's many servers; fewer human errors | Must be maintained as the system changes |
| Stray/held packages fixed | removed hold on `curl`, stray firewall rule | No surprise "why is this blocked?" outages | — |

## 3. Evidence (plain summary)

<Point to the files: two run logs both exit 0 with 19/19 checks; hardening scores
dropped from 9.2 (unsafe) to ~1.2; the post-remediation file shows `kk-api` can
still write to logs after rotation.>

## 4. What is still risky — honest gaps

<Be truthful. Examples: the services are still placeholders (`socat ... /dev/null`),
so hardening is proven on a stand-in not the real app; the whole approach is
verified on one local VM, not the real multi-server fleet; secrets are in a plain
`EnvironmentFile` (consider a secrets manager); we have not load-tested the
`releases/` deploy step; the network allow-list is hardcoded.>

## 5. Recommendation / what's next

<1–2 sentences: what you'd do before trusting this in production.>
