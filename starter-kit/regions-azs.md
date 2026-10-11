# Region and Availability Zone Design

## Region selection

I would choose the region closest to KijaniKiosk's users (for example `eu-west-1` if the customers are in Europe) to keep latency low. Beyond proximity, the decision also weighs data-residency and legal requirements, the availability of the services we depend on, and cost.

## What an availability zone is

An availability zone (AZ) is one or more physically separate data centres inside a region, with their own independent power, cooling, and network. AZs within a region are linked by fast, low-latency connections.

## Multi-AZ reliability

We deploy across at least two AZs so that a single data-centre failure does not take the platform down. A load balancer spreads traffic across the AZs, while the database replicates between them (RDS Multi-AZ) and fails over automatically if one AZ is lost. This keeps the platform serving even when an entire data centre goes offline.

## Why not multi-region (yet)

Multi-region adds significant cost and complexity, and at this stage it is disaster recovery rather than a first step. We start multi-AZ and only grow to multi-region if the scale or business requirements justify it.
