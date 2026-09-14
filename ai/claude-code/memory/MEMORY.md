# Memory Index

- [Open PRs as draft](pr-open-as-draft.md) — always `gh pr create --draft`; only mark ready when explicitly asked
- [Update PR description, not a new comment](pr-update-description-not-comment.md) — reflect current PR state by editing the body in place
- [Delegate coding to lower-model subagents](delegate-coding-to-lower-model-subagents.md) — run coding tasks in subagents on sonnet/haiku by judgment; keep planning/review in main loop
- [Publish research as Artifacts](publish-research-as-artifacts.md) — investigations/audits go out as a shareable page, not terminal scrollback
- [Worktree-only edits](worktree-only-edits.md) — never touch a main checkout; work in `~/repo/claude-worktrees/<repo>.<slug>-<session-id>`, hook-enforced
- [`$/` self-repo `uses:` syntax](gh-actions-self-repo-uses-syntax.md) — resolves to the defining repo at the running ref, cross-repo included; works on `*.ghe.com`
- [Grafana publish needs folderUid](grafana-dashboard-publish-needs-folderuid.md) — omitting it moves the dashboard to root and can lock a scoped service account out
- [Loki stream labels vs structured metadata](loki-stream-labels-vs-structured-metadata.md) — structured metadata returns zero inside `{}`; filter it after a `|`
- [Stale worktree cleanup policy](stale-worktree-cleanup-policy.md) — cull worktrees untouched 7+ days; flag (don't delete) dirty trees or open PRs
- [WSL cron misses overnight slots](wsl-cron-misses-overnight-slots.md) — 04:00 jobs silently never fire; `@reboot` + date stamp + `flock` is the fix
- [`gh pr checks --watch` exits 0 too early](gh-pr-checks-watch-exits-zero-before-checks-register.md) — right after a push it reports "no checks reported" and exits 0; resolve the run id and use `gh run view`
- [rtk rewrite breaks git in worktrees](rtk-rewrite-breaks-git-in-worktrees.md) — status/log/diff/commit get denied by the worktree guard; use `/usr/bin/git`
- [Worktree guard blocks compound git/gh](worktree-guard-blocks-compound-git-gh.md) — refuses loops over `.github` paths, `$TMPDIR` in args, quoted jq in `gh -q`; split into plain commands
- [Sandbox netns is loopback-only](sandbox-netns-is-loopback-only.md) — docker daemon reachable over its socket, published ports and container IPs are not
