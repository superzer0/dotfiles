---
name: worktree-only-edits
description: Never edit repos under ~/repo directly; every change goes in a per-session worktree under ~/repo/claude-worktrees
metadata:
  node_type: memory
  type: feedback
---

All repositories under `~/repo` are read-only reference checkouts. Every file change happens in a git worktree under `~/repo/claude-worktrees/`, named `<repo>.<topic-slug>-<session-id-prefix>` on branch `claude/<topic-slug>-<session-id-prefix>`. Create it with `bash ~/.claude/new-worktree.sh <repo> <topic-slug>`, then `EnterWorktree` with the printed `path:`.

**Why:** many parallel Claude sessions run across dozens of repos; centralising worktrees in one directory keeps each session's changes isolated and easy to track, and stops sessions from stepping on each other's working trees.

**How to apply:** enforced by a `PreToolUse` hook (`~/.claude/worktree-guard.sh`) registered in `~/.claude/settings.json` for `Edit|Write|NotebookEdit`, plus the always-loaded rule `~/.claude/rules/worktrees.md`. Never use `EnterWorktree` with `name:` or subagent `isolation: "worktree"` — both create worktrees under `<repo>/.claude/worktrees/` instead.
