---
name: pr-open-as-draft
description: User wants every PR opened as draft by default
metadata:
  node_type: memory
  type: feedback
---

Always open new GitHub PRs as draft (`gh pr create --draft`), never ready-for-review by default.

**Why:** standing instruction, repeated after a PR was opened non-draft and merged before the request could be applied — draft can't be retrofitted onto a merged PR.

**How to apply:** every `gh pr create` call must include `--draft`. Only mark ready (`gh pr ready`) when explicitly asked. Applies across all repos and orgs, not just one project.
