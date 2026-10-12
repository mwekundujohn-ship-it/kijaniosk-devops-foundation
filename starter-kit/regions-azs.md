# Region and Availability Zone Design

## Region selection

I would pick the region closest to KijaniKiosk's users, so if the customers are in Europe that is `eu-west-1`. The main reason is latency. I would also weigh data-residency and legal requirements, which services we depend on are available, and cost.

## What an availability zone is

An availability zone (AZ) is one or more physically separate data centres inside a region, with their own independent power, cooling, and network. AZs within a region are linked by fast, low-latency connections.

## Multi-AZ reliability

We deploy across at least two AZs. That way a single data-centre failure does not take the platform down. A load balancer spreads traffic across the AZs. The database replicates between them (RDS Multi-AZ) and fails over automatically if one AZ is lost. So the platform keeps serving even when a whole data centre goes offline.

## Why not multi-region (yet)

Multi-region adds significant cost and complexity, and at this stage it is disaster recovery rather than a first step. We start multi-AZ and only grow to multi-region if the scale or business requirements justify it.
