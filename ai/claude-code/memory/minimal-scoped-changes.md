---
name: minimal-scoped-changes
description: Prefer a simple constant over a derived value; keep diffs minimal and scoped — never merge PRs or refactor adjacent code unasked
metadata:
  node_type: memory
  type: feedback
---

Prefer the simplest constant or explicit value over a derived or coupled one — e.g. `minAvailable: 1`,
not a value computed from `replicaCount`. Keep diffs minimal and scoped to the request. Do not merge
PRs and do not refactor adjacent code unless explicitly asked.

**Why:** derived values couple two settings that then have to be reasoned about together at 3am;
unrequested refactors and merges expand the review surface and take a decision that belongs to the
user.

**How to apply:** when a value could be computed, write the constant. When you notice adjacent code
worth improving, mention it in one line instead of changing it. Open PRs as drafts
([[pr-open-as-draft]]) and leave merging to the user ([[never-admin-or-force-merge-prs]]).
