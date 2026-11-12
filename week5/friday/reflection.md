# Week 5 Reflection

## 1. Where two requirements pulled against each other

The tension I actually hit was between proving that the publish step had authenticated and the rule that no credential may appear in a build log. My first working Jenkinsfile printed the resolved Nexus username and password to show that `withCredentials` had injected them. Jenkins masked the password, so the log showed `****`, but the design still depended on writing a credential to standard output to prove a point. Requirement 5 treats any credential in any block or log as a failure, so "masked" was not the same as "absent".

I chose credential hygiene and removed the echo. The evidence that authentication worked is now indirect but stronger: Jenkins logs `Masking supported pattern matches of $NEXUS_PASS`, the publish step returns success, the success block prints the artifact URL, and the package is downloadable from Nexus. I gave up a convenient piece of evidence to keep the log clean.

A second, smaller tension was isolation versus reachability. The Docker agent cannot reach Nexus on `localhost` because localhost inside the container is the container itself. I used `--network=host`, which makes `127.0.0.1` mean the VM. That reduces network isolation. The alternative was the VM's address on the bridge, which keeps the bridge but ties the pipeline to one machine's address. I chose host networking because it is reproducible on this VM, and I recorded the choice in the pipeline rather than leaving it implicit.

## 2. One sentence, two registers

Board document: "When a check fails, the process stops at that check and the later steps do not run."

Technical version: "A failing stage aborts the Declarative Pipeline; subsequent stages are skipped, the `post { failure }` block runs, and no artifact is published."

The information that is the same is the causal chain: a failure halts progress and nothing is released. What changes is vocabulary and detail. The board version describes what happens to the work. The technical version names the mechanism (Declarative Pipeline stage skipping and the failure post condition) and the concrete consequence (no publish). The board version deliberately leaves out the mechanism because Nia does not need it to make a decision.

## 3. What breaks first at forty developers

The first part to break is the version string, which today is only the base version plus the git SHA. Each commit produces one version, so re-running the same commit tries to publish the same version again. With four developers that is manageable. With forty, branches, merges, retries, and rebuilds multiply, and the registry either refuses the duplicate or silently overwrites it. Either way we lose the ability to tell a rebuild from the original upload.

The fix is a version that includes a monotonically increasing build number or timestamp alongside the SHA, plus a rule that a rebuild always receives a new version. The pipeline would compute the version from the build number and the SHA instead of the SHA alone. That keeps traceability to the commit and still makes every published artifact unique. Capacity on the single Jenkins controller would be the next thing to watch, but the versioning collision is the first correctness problem that appears.
