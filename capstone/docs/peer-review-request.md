# Peer review request

Use this template to ask a classmate for the capstone peer review. The review
does not need a live meeting; asynchronous GitHub review is acceptable.

## Message to the reviewer

> Hi [name], I need a peer review for my KijaniKiosk capstone. The work is on the
> `feature/capstone-track-a` branch of
> https://github.com/mwekundujohn-ship-it/kijaniosk-devops-foundation. Please
> review the `capstone/` directory and file at least three GitHub Issues. For
> each issue, include the file and line, the severity (blocker, major, or
> minor), what you expected, what you observed, and how to reproduce it. Please
> do not rewrite the code; I will fix the issues and reference the issue number
> in the commit. Thank you.

## Minimum review standard

- At least three issues filed on GitHub.
- At least one issue at `blocker` or `major` severity.
- At least one issue closed by a commit that references the issue number.
- The reviewer must be a real person; do not fabricate a name, comment, or
  approval.
- A GitHub issue comment or PR review is sufficient. A live call is not required.

## Suggested review focus

1. Does the staging overlay actually differ from production in namespace,
   configuration, replicas, and image tag?
2. Does the Jenkins pipeline build once and promote the same tag, or does it
   rebuild?
3. Does the smoke test prove the payment calculation, not only process health?
4. Is the approval gate real, and what happens if nobody approves?
5. Are the Terraform bucket and namespaces safe and clearly owned?
6. Is any secret, token, or credential committed?
7. Are the claimed verified items actually verified?
8. Is the Week 10 gap stated honestly?

## Evidence log

Record the review here after it happens:

| Reviewer | GitHub issue | Severity | Status | Fix commit |
| --- | --- | --- | --- | --- |
|  |  |  |  |  |

## If no reviewer is available

Do a documented self-review instead and label it as self-review, not peer
review. The rubric gives partial credit at best. Do not invent a reviewer or a
review comment. The honest fallback is:

1. File the same three issues yourself.
2. Fix at least one.
3. Link the commit.
4. State clearly in the submission that no external reviewer was available.
