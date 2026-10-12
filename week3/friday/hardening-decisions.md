# KijaniKiosk Production Foundation — decisions explained for Nia

## 1. What we built, in one paragraph

We made the three KijaniKiosk services on the production node much harder to abuse. We gave each service its own locked-down account, so the API, the payments process, and the logging process each run as themselves and cannot pretend to be one another. We tightened file access so that only the right service can read or write each thing — payments can read the logs but never change them, and nobody outside the team can touch the folder at all. We wrapped each service in a sandbox so that even if someone broke into one of them, they could do very little and could not reach the internet. And we turned the whole setup into a single script that brings any server to the same correct state, whether it is brand new or has been messed around with for days.

## 2. The decisions and what they mean for the business

| Decision | Technical detail | Business benefit | Cost / trade-off |
|----------|------------------|------------------|------------------|
| Dedicated service accounts | `kk-api/kk-payments/kk-logs`, nologin, no password | A bug in one service cannot act as another | Slightly more admin overhead |
| Least-privilege file access | ACLs: `kk-api`/`kk-logs` write logs, `kk-payments` read-only | Payments can't tamper with logs; audit trail stays trusted | ACLs must be re-applied on new files (we fixed logrotate for this) |
| Sandboxed services | `ProtectSystem=strict`, `PrivateTmp`, `NoNewPrivileges`, syscall filters | Even if a service is exploited, blast radius is tiny | Some services need exceptions to work |
| Network restriction | `IPAddressAllow` internal tier only | Data can't be exfiltrated to the internet | Must update the allow-list when we add tiers |
| Idempotent provisioning | one script converges any server state | Ready for the growth target's many servers; fewer human errors | Must be maintained as the system changes |
| Stray/held packages fixed | removed hold on `curl`, stray firewall rule | No surprise "why is this blocked?" outages | — |

The theme running through all of these is that we stopped trusting the services to behave and started assuming that any one of them could be taken over. If an attacker gets into the payments process, the accounts and the sandbox mean they still cannot read the API keys, cannot rewrite the logs to cover their tracks, and cannot send our data out to the internet. For a business handling money, that difference is the gap between an incident that is contained and an incident that becomes a headline.

## 3. Evidence (plain summary)

We did not just claim this works — we ran it and kept the receipts. The provisioning script was run twice: once from the messy "dirty" server left over from the earlier labs, and once from the already-configured server right after. Both runs finished with **19 checks out of 19 passing and exit code 0**, which is the proof that re-running it is safe and changes nothing unexpected. When it started, the old API service scored **9.2 (marked UNSAFE)** on the system's own security meter; after hardening, all three services score around **1.2–1.3**, comfortably inside the target. Finally, we did not assume the file permissions survived log rotation — we forced a real rotation and then tested as the API account itself. It could still write to the recreated log (`PASS`), and the detailed permission listing shows the payments process still sitting at read-only. The records are in `provision-run-dirty.log`, `provision-run-clean.log`, `kk-payments-hardening.md` and `post-remediation-verification.txt`.

## 4. What is still risky — honest gaps

This is honest rather than finished, and Nia should hear the limitations as clearly as the wins.

- **The services are placeholders.** The API and payments processes currently run a stand-in command (`socat ... /dev/null`), not the real application. What we proved is that the *hardening* is correct, on a stand-in — not that the real app runs cleanly inside the sandbox. The real app may need exceptions we cannot yet predict.
- **It is proven on one machine, not the fleet.** Everything was verified on a single local virtual machine. We have not yet run the provisioner against the real multi-server environment, so behaviour under real network conditions and real load is unknown.
- **Secrets sit in a plain file.** The service configuration, including secrets, lives in a readable `EnvironmentFile` on disk. Anyone with root on that box can read it. A dedicated secrets manager would be the proper fix.
- **The deploy step is untested at scale.** The `releases/` directory and its deployment behaviour have not been load-tested; we do not know how it behaves with many servers deploying at once.
- **The network allow-list is hardcoded.** The list of allowed internal addresses is written into the script by hand, so it is only as correct as our memory when we change the network.

## 5. Recommendation / what's next

Before trusting this in production, I would run the provisioner against a real, representative server with the actual application running inside the sandbox, and move the secrets out of the plain file into a proper secrets manager. Those two steps would turn a solid, well-evidenced foundation into something we can put in front of real customers.
