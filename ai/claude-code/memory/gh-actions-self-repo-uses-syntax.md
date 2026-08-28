---
name: gh-actions-self-repo-uses-syntax
description: GitHub Actions `$/` self-repository uses: syntax, and the two things the changelog does not make obvious
metadata:
  node_type: memory
  type: reference
---

A `uses:` value starting with `$/` resolves to the workflow's or action's **own**
repository at the exact commit that is running, with no checkout. Announced
2026-07-30: https://github.blog/changelog/2026-07-30-reference-same-repository-actions-with-self-repository-syntax/

Works everywhere the workspace-relative `./` syntax works: workflow steps,
composite action steps, nested composition, and reusable workflow calls.
Requires Actions runner 2.336.0 or newer.

Two things the changelog does not make obvious, both verified 2026-08-13:

- **It works on GitHub Enterprise Cloud with data residency** (`*.ghe.com`)
  even though the changelog says "github.com only". Those hosts report
  `X-Github-Enterprise-Version: ghe.com` and are not Enterprise Server.
- **"Own repository" means the repository that *defines* the file, not the
  repository of the run.** A composite action consumed cross-repo at a pinned
  tag resolves `$/` against its defining repository at that tag.

Use it instead of hardcoding `<org>/<repo>/.github/actions/x@<version>` inside a
repository's own workflows — that self-pin has to be bumped on every release and
lets a workflow drift from the sibling action it depends on.
