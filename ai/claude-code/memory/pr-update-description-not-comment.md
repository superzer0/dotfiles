---
name: pr-update-description-not-comment
description: Reflect current PR state by editing the PR description in place, not by adding a new comment
metadata:
  node_type: memory
  type: feedback
---

When a PR's state changes (e.g. a previously-unverified precondition gets verified), update the PR description (`gh pr edit --body`) to reflect the current state — do not post a new comment on top of the old description.

**Why:** the description is the PR's single source of truth for its current state; stacking comments makes a reader reconstruct history instead of just reading the top.

**How to apply:** when new information supersedes something already stated in a PR body (a caveat resolved, a check completed, a section now stale), edit the body directly. Comments are for discussion and replies (e.g. answering a reviewer's inline thread), not for state updates the description should already carry.
