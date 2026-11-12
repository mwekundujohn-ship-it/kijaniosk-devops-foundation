# Reflection

## 1. The hardest step to automate

Building the image and pushing it to the registry is the easy part. The step I would expect to break first is deciding when the deployment is actually finished. A pipeline can start a rollout and get a success message back while the new copies are still starting up, and the old ones are already gone. The failure I worry about most is a pipeline that reports green while customers are getting errors for a few seconds. Nothing in the job log looks wrong, so the first sign is a complaint rather than a failed build. To make it reliable I would add an explicit wait for both copies to report ready, and a check against the service itself before the job is allowed to pass.

## 2. One sentence, two audiences

The plain version says: "The platform detected the missing copy and created a replacement automatically." For Tendo I would write: "The ReplicaSet controller saw the pod deletion and reconciled the desired replica count by scheduling a replacement pod in the same namespace." Both sentences say that one copy disappeared and another appeared without a person acting. The plain version explains the outcome. The technical version names the controller, the desired state, and the mechanism, so another engineer can check it and reproduce it. What is lost in the plain version is the ability to verify the claim from the sentence alone. What is gained is a reader who understands why it matters without knowing the machinery.

## 3. Hardcoded values that should move to configuration management

Several values in the deployment are fixed in the manifest and should be supplied per environment. The environment label, the service port, the number of copies, and the registry address are all settings that differ between environments; they belong in a shared configuration source. The registry credential already lives in a cluster secret and is only referenced by name, which is the right pattern. If the settings stay hardcoded, promoting the same service to a second environment means editing and recommitting the manifest, which invites drift between what is stored and what is running. It also makes a small operational change look like a code release. Week 9's configuration objects remove that risk by letting the same image run against different settings without a rebuild.
