---
name: wsl-cron-misses-overnight-slots
description: Cron jobs at overnight hours silently never fire in WSL; use @reboot plus a date stamp
metadata:
  node_type: memory
  type: project
---

Any WSL crontab entry at an overnight hour silently never fires — WSL is powered off, and cron has no catch-up. Two daily cleanup jobs scheduled at 04:00 and 04:42 fired exactly once in a week, on the one night the machine was left on.

**Fix:** `~/.claude/daily-maintenance.sh` wraps both scripts, guarded by a `date +%F` stamp (one run per day) and `flock -n` (WSL starts cron 2-3 times per boot, so `@reboot` multi-fires and races the stamp). The crontab runs it from both `@reboot sleep 60` and `0 4 * * *`; whichever fires first wins.

Not a `systemd --user` timer with `Persistent=true`: no user D-Bus in WSL (`Failed to connect to bus`). Not anacron, which is the textbook answer: it needs root.

`crontab <file>` is **blocked by the auto-mode classifier** — install it yourself (`! crontab ~/.claude/crontab.example`). Don't try to route around it.

Any weekly job has the same defect, and a weekend slot makes it worse.

**Why:** a scheduled cleanup that looks installed but never runs is worse than none — it hides growth. See [[stale-worktree-cleanup-policy]].
