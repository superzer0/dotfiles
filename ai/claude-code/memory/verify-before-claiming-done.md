---
name: verify-before-claiming-done
description: "Never claim a change works without live proof — render, plan, or query the real system first"
metadata:
  node_type: memory
  type: feedback
---

Never state that a change works without empirical proof from the live system:

- **Grafana:** render the FULL dashboard image (not individual panels) and inspect it.
- **Terraform:** attach the `terraform plan` output showing exactly which resources change.
- **Kubernetes:** query the live cluster (kubectl / Prometheus) after apply.
- **.NET:** quote the pass / fail / skipped counts from `dotnet test`. "Build succeeded" is not
  test evidence.

Close the task with a verified / not-verified ledger: one line per claim, naming the evidence or
saying it was not checked. Strip from PR descriptions and comments any claim not verified this way.

**Why:** query-level or config-level checks prove that something is syntactically valid, not that it
is correct in the running system; unverified claims in a PR body mislead the reviewer into trusting
work nobody actually checked.

**How to apply:** do the verification step before writing the "done" message or the PR body. If a
check cannot be run, say so explicitly instead of implying it passed — and edit the claim out rather
than softening it. When a claim later becomes verified, update the PR body in place per
[[pr-update-description-not-comment]].
