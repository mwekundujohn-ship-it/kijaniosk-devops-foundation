# Cloud Service Model

## What the three models mean

- IaaS = you rent the raw building blocks (virtual machines, storage, networking) and manage the OS, runtime, and everything above it yourself.
- PaaS = the provider runs the servers, OS, and scaling for you, so you only deploy your code and data.
- SaaS = you consume a finished, ready-to-use service and just manage your own data and settings, not the infrastructure at all.

## Recommendation for KijaniKiosk

KijaniKiosk should mainly use PaaS, with selective IaaS where real low-level control or cost tuning is needed, and SaaS for commodities it should never build itself. As a small team, the priority is shipping product fast, and PaaS removes the undifferentiated heavy lifting of patching servers, scaling, and OS maintenance. IaaS is reserved for the few components that genuinely need control, while SaaS covers things like email and monitoring that are cheaper to consume than to run.

## Reasons

1. Small team: engineers should focus on the product, not on patching and maintaining servers.
2. The provider handles scaling and patching, which means faster delivery and less operational risk.
3. Cost: you pay for what you use, and IaaS is only added where control or cost demands it.

## Examples per model

- IaaS  -> e.g. EC2 instances or EBS volumes for a workload that needs full control.
- PaaS  -> e.g. Elastic Beanstalk / RDS for running and scaling the app and database.
- SaaS  -> e.g. email (SES) or monitoring/dashboards consumed as a finished service.
