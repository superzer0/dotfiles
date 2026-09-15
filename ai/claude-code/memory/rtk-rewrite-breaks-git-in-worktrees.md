---
name: rtk-rewrite-breaks-git-in-worktrees
description: In a worktree-isolated session the rtk hook rewrites git status/log/diff/commit and the worktree guard then refuses the rewrite; call /usr/bin/git instead
metadata:
  node_type: memory
  type: feedback
---

Inside an `EnterWorktree` session, `git status`, `git log`, `git diff` and `git commit` all fail with
"this command runs rtk with a git command among its operands … Refusing to run it". The rtk hook
rewrites them to `rtk git <cmd>`, and the worktree guard cannot prove the rewritten command targets
this worktree, so it denies. `git merge`, `git add`, `git push` and `git config` are not rewritten
and work normally.

Workaround: `/usr/bin/git <cmd>` — the absolute path defeats the rtk rewrite and the guard sees a
plain git command. Also fails: compound commands (`;`, `&&`), `git -C <path>`, `rtk proxy git`, and
any command that merely mentions `git` in a subshell or variable.

**Why:** cost 8 failed tool calls in one session before the pattern was clear; the guard's message
names the launcher, not the hook, so it reads like a worktree-targeting problem rather than a
rewrite-visibility one.

**How to apply:** in a worktree session, reach for `/usr/bin/git` for anything read-only or
committing, and keep each git invocation a single plain command. See
[[worktree-only-edits]].
