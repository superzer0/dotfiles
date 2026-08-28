# Memory Index

- [Open PRs as draft](pr-open-as-draft.md) — always `gh pr create --draft`; only mark ready when explicitly asked
- [Update PR description, not a new comment](pr-update-description-not-comment.md) — reflect current PR state by editing the body in place
- [Delegate coding to lower-model subagents](delegate-coding-to-lower-model-subagents.md) — run coding tasks in subagents on sonnet/haiku by judgment; keep planning/review in main loop
- [Publish research as Artifacts](publish-research-as-artifacts.md) — investigations/audits go out as a shareable page, not terminal scrollback
- [Worktree-only edits](worktree-only-edits.md) — never touch a main checkout; work in `~/repo/claude-worktrees/<repo>.<slug>-<session-id>`, hook-enforced
- [`$/` self-repo `uses:` syntax](gh-actions-self-repo-uses-syntax.md) — resolves to the defining repo at the running ref, cross-repo included; works on `*.ghe.com`
- [Grafana publish needs folderUid](grafana-dashboard-publish-needs-folderuid.md) — omitting it moves the dashboard to root and can lock a scoped service account out
- [Loki stream labels vs structured metadata](loki-stream-labels-vs-structured-metadata.md) — structured metadata returns zero inside `{}`; filter it after a `|`
