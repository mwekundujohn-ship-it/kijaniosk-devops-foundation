# Week 7 and Week 8: A Comparison for the Board

## Why this document exists

Nia asked the same question she asks every week: what does this give us that we did not have before? This document answers that for the payments service. In Week 7 we delivered the software as a package that was copied onto a server and restarted by our automation. Week 8 changes what we hand over. Instead of a package sitting on a server, we ship a sealed container image. The table below compares the two approaches on the four points that matter to the board, and the sections after it explain the numbers and the gaps.

## The comparison

| Concern | How Week 7 handled it | How Week 8 handles it |
| --- | --- | --- |
| How the software is delivered | A build artifact was published to the package registry, then copied onto a server and restarted as a background service by our deployment tooling. | A sealed container image is published to a private registry, then the container platform pulls it and runs two copies behind a stable service name. |
| How a release is undone | We re-ran the deployment with the previous artifact version and restarted the service. How quickly that works depends on reaching the server and restarting it. | We point the deployment back to the previous image version. The platform replaces the running copies for us, and nobody edits the server. |
| How a failure is recovered | The service manager restarted the process if it stopped, and an engineer looked into it. Recovery depended on the restart rule and on someone noticing. | The platform detected the missing copy and created a replacement automatically. In this week's measurement, a deleted copy was ready again in 1.70 seconds. |
| How capacity grows | We added another server and repeated the deployment on it. | We increase the number of copies and the platform places more of them across the cluster. |

## What the evidence shows

The first number to remember is 1.70 seconds. That is how long it took, in this week's test, for the platform to notice that one copy of the payments service had gone and to have a replacement running. Nobody typed a command and nobody was called. In the previous approach, the same event would have waited for the restart rule to fire, and a person would have had to confirm that the service was healthy again before anyone could trust it.

The second number is 52.4 percent. The new production image is 80.1 megabytes, down from 168.4 megabytes for the earlier build. That saving comes from separating the tools we need to build the software from the software we actually ship. The board does not need to know how a container is put together, but the saving matters: a smaller image is faster to move, cheaper to store, and shows less to an attacker because the build tools are not present when the service runs.

## Why the change matters

Together these two numbers describe a service that is cheaper to run and quicker to recover. The smaller image reduces the amount of software we have to trust in production. The automatic replacement shortens the time a customer could be affected by a lost copy. Neither number is a promise about the future. Both come from evidence collected in this week's lab and are written down in the supporting records.

## What this does not solve yet

This week proves that the delivery chain works from a clean start, but it is not finished, and the board should not be told otherwise. Configuration and secret material are still written directly into the deployment definition, so changing environment means editing a shared file instead of changing a setting. The service has no readiness signal yet, so a copy can receive traffic before it is ready. The cluster is a single local machine, not a resilient group of machines. There is no persistent storage, no image scanning, and the whole sequence is still run by hand rather than by an automated pipeline. Week 9 begins to close the first gap by moving configuration and secrets out of the application definition and into managed settings. The other gaps stay on the list.

---

Short version for the board: same service, lighter package, faster recovery, and a clear list of what is still missing.
