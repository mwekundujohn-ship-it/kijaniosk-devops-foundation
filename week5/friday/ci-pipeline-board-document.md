# How a Change Reaches Our Payment Service

KijaniKiosk handles money, so every change to our payments code has to earn trust before anyone can rely on it. The checks that decide this are automatic. They run the same way whether the change is one line or two hundred, and they leave a record that we can read months later. This document explains the journey from a developer saving a change to a versioned package appearing in our internal registry.

## From a saved change to a stored version

The journey begins when a developer saves a change to the shared codebase. That save does not reach customers. Instead it wakes up an automated process that walks the change through a fixed sequence of checks. If every check passes, the result is a package that we can trace, reproduce, and install. If any check fails, the process stops and nothing is released.

The first check looks at the shape of the code. It reads every source file and confirms that there are no syntax errors, no stray tab characters, no trailing spaces, and no lines so long that they become hard to review. This check is fast, and it runs first for a simple reason. There is no value in building or testing code that cannot even be read.

The second check builds the software. It copies the source into a clean output folder and records the exact code revision that produced it. The result is a single package that moves through the rest of the process as one unit.

The third step runs two checks side by side. One executes the automated tests, which feed known inputs into the payment calculations and compare the answers with known results. The other asks the public vulnerability database whether any library we depend on has a known security weakness. Running both at once saves time without weakening either check.

The fourth step stores the built package together with a fingerprint. That fingerprint is a short code derived from the file itself. Anyone can recompute it later. If the stored file has been altered, the fingerprint will no longer match, so we can prove that the package we installed is the package that passed the checks.

The final step publishes the package to our internal registry, Nexus. Each published package carries a version made of two parts: the release number and a short identifier for the exact code change that produced it. Two different changes can therefore never share a version, and every package can be traced back to the change that created it.

| Step | What it confirms |
|---|---|
| Shape check | The code can be read, with no syntax or formatting errors |
| Build | The code assembles into one clean package |
| Tests and vulnerability scan | The payment logic behaves correctly and no known vulnerable library is present |
| Storage | The package is saved with a fingerprint that proves it was not altered |
| Publication | The package is available in the registry under a unique, traceable version |

## What Happens When Something Goes Wrong

When a check fails, the process stops at that check and the later steps do not run. Nothing reaches the registry. The run is recorded as failed and its full output is kept, so anyone can open that run and see exactly which check stopped it and why. The last good version remains available, so anyone who needs a working package can still get one.

This behaviour is deliberate. A failed shape check means the code was never valid, so building it would only waste time. A failed test means the behaviour is wrong, so publishing it would place a faulty package within reach of anyone who installs it. A failed vulnerability scan means we would be shipping a known weakness. In every case, stopping early costs less than discovering the problem after release.

## What This Does Not Do Yet

This process does not deploy anything. It produces a trusted package and leaves the release decision to a person. It also does not measure how the service behaves under heavy traffic, does not scan the container image itself, and does not rotate the credentials it uses. Those gaps are honest ones, and they are the next problems we intend to solve.
