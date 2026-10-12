# Cloud Service Model

## What the three models mean

- IaaS = you rent the raw building blocks (virtual machines, storage, networking) and manage the OS, runtime, and everything above it yourself.
- PaaS = the provider runs the servers, OS, and scaling for you, so you only deploy your code and data.
- SaaS = you consume a finished, ready-to-use service and just manage your own data and settings, not the infrastructure at all.

## Recommendation for KijaniKiosk

KijaniKiosk should mainly use PaaS. We only drop to IaaS for the few parts that need real low-level control or careful cost tuning, and we use SaaS for anything that is a commodity. Our team is small, so the priority is shipping product, not patching servers. PaaS handles the scaling and the OS updates for us, which speeds delivery and cuts operational risk. SaaS covers things like email and monitoring, which are cheaper to consume than to run ourselves.

## Reasons

1. Small team: engineers should focus on the product, not on patching and maintaining servers.
2. The provider handles scaling and patching, which means faster delivery and less operational risk.
3. Cost: you pay for what you use, and IaaS is only added where control or cost demands it.

## Examples per model

- IaaS  -> e.g. EC2 instances or EBS volumes for a workload that needs full control.
- PaaS  -> e.g. Elastic Beanstalk / RDS for running and scaling the app and database.
- SaaS  -> e.g. email (SES) or monitoring/dashboards consumed as a finished service.
