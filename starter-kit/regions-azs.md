# Region and Availability Zone Design

## Region selection

<!-- Write 2-3 sentences: which region you would choose (e.g. eu-west-1 or
     us-east-1) and WHY — pick based on: where your users are (latency),
     data-residency/laws, service availability, and cost. -->

## What an availability zone is

<!-- 1-2 sentences: an AZ is one or more physically separate data centres within
     a region, with independent power/network, linked by low-latency connections. -->

## Multi-AZ reliability

<!-- 2-3 sentences: deploy across at least 2 AZs so a single data centre failure
     does not take the platform down. Mention: load balancer spreads traffic,
     database replicates across AZs (RDS Multi-AZ), automatic failover. -->

## Why not multi-region (yet)

<!-- 1-2 sentences: multi-region adds cost and complexity; it's disaster recovery
     for later, not the first step. Start multi-AZ, grow to multi-region if needed. -->
