---
name: stale-worktree-cleanup-policy
description: Daily policy for removing claude-worktrees/ entries untouched for 7+ days
metadata:
  node_type: memory
  type: project
---

`~/.claude/stale-worktree-cleanup.sh` removes worktrees under `~/repo/claude-worktrees/` with no activity in 7+ days. It is a plain bash/git script in the **real user crontab** (not a `CronCreate` session job — `CronList` shows nothing because it only reports the current session), invoked via `~/.claude/daily-maintenance.sh`, which is stamped to one run per day and triggered from both `@reboot` and the timed slot — an overnight cron slot never fires on a machine that is powered off at night.

**Criteria for "stale":** last activity = newer of (a) `git log -1 --format=%ct` on the checked-out branch and (b) newest mtime among non-`.git` files (catches uncommitted work). Older than 7 days = candidate.

**Before removing a candidate:**
1. `git status --porcelain` — if dirty, skip and flag; don't destroy unsaved work.
2. `gh pr list --head <branch> --state open` — if an open PR exists, skip and flag (stale PR ≠ abandoned).
3. Otherwise `rm -rf <worktree>`, `git -C <repo> worktree prune`, then `git branch -d <branch>` (safe delete, only succeeds if merged).

Report what was removed and what was flagged; never silently delete something flagged.

**Why:** worktrees should be culled automatically, but uncommitted work and an active PR's branch must never be destroyed — flag-don't-delete for those two cases specifically.

**The open-PR guard failed silently twice and now has two hard gates.** It was written as `pr_open=$(gh pr list ... 2>/dev/null)`, so *any* empty result read as "no open PR":
1. `gh` missing from cron's `PATH` (`/usr/bin:/bin` has git and flock, not gh) — this deleted the worktrees of two open PRs. Fixed by a `PATH=` line in the crontab plus an abort-if-no-gh precondition in the script.
2. A failing `gh` (network, token, rate limit) was indistinguishable from a clean "no PR" answer. Fixed by gating on gh's exit status and skipping when the query fails.

Both gates have a runnable check: run the script with `PATH=/usr/bin:/bin`, and again with a stub `gh` that exits 1 — the worktree count must not change either time.

The script's `LOG` path in `~/.claude/` is **not sandbox-writable**, so a manual in-session run loses its log lines while still performing removals — a removed tree then cannot be identified afterwards. Run it via cron, never in-session.
