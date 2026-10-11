# DevOps Week 1 — Revision Notes (Dalton Wambui)

Study notes for the KijaniKiosk DevOps Foundation project. These explain the
concepts; the submitted files in `starter-kit/` should be written in my own words.

---

## 1. DevOps and the "Three Ways"

**DevOps** = a culture + set of practices where Development and Operations teams
work together, automate as much as possible, and deliver software quickly and
reliably. Instead of "throw it over the wall to ops", the same team builds, ships,
and runs the software.

The **Three Ways** (Gene Kim) describe DevOps thinking:

- **Flow** — work should move smoothly and quickly from a developer's laptop to
  production. We do this by working in small batches, using short-lived branches,
  Pull Requests, and CI/CD pipelines so nothing sits waiting.
- **Feedback** — we want fast signals about whether our change is good or bad.
  Examples: automated tests running on every push, code review comments, monitoring
  and alerting in production, error logs. Fast feedback = fix problems early.
- **Learning** — we continuously improve. Blameless post-mortems after incidents,
  sharing knowledge, experimenting, and feeding lessons back into the process.

**Evidence of the Three Ways in a Git workflow:**
- Flow: branch -> commit -> Pull Request -> merge (small, reviewable changes).
- Feedback: PR review + CI checks give feedback before code reaches `main`.
- Learning: reviewing what went wrong/right and improving the workflow over time.

---

## 2. Cloud Service Models (IaaS / PaaS / SaaS)

Think of it as a **"how much do I manage vs. how much does the provider manage"**
spectrum.

| Model | You rent | You manage | Provider manages | AWS example |
|-------|----------|------------|------------------|-------------|
| **IaaS** (Infrastructure as a Service) | Raw compute, storage, network | OS, runtime, app, data, scaling | Physical hardware, virtualization | EC2, VPC, EBS |
| **PaaS** (Platform as a Service) | A ready-to-run platform/runtime | Just your app + data | OS, runtime, patching, scaling | Elastic Beanstalk, Heroku, App Engine, RDS |
| **SaaS** (Software as a Service) | Finished software | Nothing (only config/data) | Everything | Gmail, Shopify, Salesforce |

**Rule of thumb:** moving IaaS -> PaaS -> SaaS = *less control, less work*.

**Reasoning framework for a startup:** a small team should not spend time on
"undifferentiated heavy lifting" (patching servers, tuning databases). Prefer
managed services (PaaS) for the app and database, SaaS for commodities (email,
monitoring, payments), and IaaS only where you truly need control.

---

## 3. Regions and Availability Zones

- **Region** = a separate geographic area (e.g. `us-east-1`, `eu-west-1`).
  Regions are fully independent of each other.
- **Availability Zone (AZ)** = one or more physically separate data centres
  *within* a region. They have independent power, cooling, and networking, but are
  connected by low-latency links.

**Reliability tiers:**
- **Single-AZ** = cheapest, but if that data centre fails, your app is down.
- **Multi-AZ** = run copies in >= 2 AZs in the same region. Survives a single
  data-centre failure. A load balancer spreads traffic; the database replicates
  across AZs (e.g. RDS Multi-AZ). This is the standard reliability baseline.
- **Multi-region** = copies in different regions. Survives a whole-region outage,
  reduces latency for global users, but is more complex and expensive (disaster
  recovery, not usually step one).

**Choosing a region:** latency to your users, data-residency/compliance laws,
which services are available, cost, and disaster-recovery needs.

---

## 4. IAM Least Privilege

- **IAM** = Identity and Access Management: who can do what, on which resources.
- Building blocks: **users** (people/apps), **groups**, **roles** (assumable
  identities, best for apps), **policies** (JSON documents that allow/deny actions).
- **Least privilege** = give an identity ONLY the permissions it needs, on ONLY the
  resources it needs, for ONLY as long as it needs. Nothing more.

**Best practices:**
- Prefer **roles** over long-lived access keys.
- Name exact **actions** (`s3:GetObject`) instead of wildcards (`s3:*`) where possible.
- Scope **resources** (a specific bucket/prefix, not `*`).
- Add **conditions** when useful (e.g. require TLS).

**Example task:** an app that only needs to read files from one S3 folder ->
allow only `s3:GetObject` on `arn:aws:s3:::my-bucket/uploads/*`.

---

## 5. Network Segmentation

- **VPC (Virtual Private Cloud)** = your own isolated network inside AWS, defined by
  a CIDR block (e.g. `10.0.0.0/16`).
- **Subnet** = a slice of the VPC's range, tied to ONE AZ.
- **Public subnet** = has a route to an **Internet Gateway (IGW)** -> resources can
  be reached from the internet (e.g. a load balancer, a bastion host).
- **Private subnet** = NO direct route to the internet -> used for app servers and
  databases. Outbound internet (for updates) goes through a **NAT Gateway**.
- **Route tables** decide where traffic goes; the difference between public and
  private is which route table (and whether it points at the IGW).

**Two layers of firewalls:**
- **Security Groups** — instance-level, stateful, allow rules only.
- **NACLs** — subnet-level, stateless, allow and deny rules.

**Typical 3-tier layout:** internet -> **public subnet** (Load Balancer) ->
**private subnet** (application) -> **private subnet** (database). Only the load
balancer is exposed; the app and data are unreachable directly from the internet.

---

## 6. Practice Questions (for revision)

Try answering these from memory:

1. Explain Flow, Feedback, and Learning and give one example of each from a Git workflow.
2. What is the difference between IaaS, PaaS, and SaaS? Which would you pick for a startup's database and why?
3. What is an Availability Zone and how is it different from a Region?
4. Why is multi-AZ better than single-AZ for reliability?
5. In one sentence, define least privilege.
6. Why is it better to attach a role to an application than to hard-code access keys?
7. What makes a subnet "public"?
8. How does a private subnet still get software updates without being publicly reachable?
9. What is the difference between a Security Group and a NACL?
10. Sketch (on paper) a VPC with a public subnet and a private subnet, and label the routing.
