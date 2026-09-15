---
name: worktree-guard-blocks-pwsh
description: "In a worktree-isolated session the guard denies every pwsh invocation outright — -File, -Command and absolute path alike"
metadata:
  node_type: memory
  type: project
---

While `EnterWorktree` is active, every `pwsh` invocation is denied, regardless of content:
`pwsh -NoProfile -File <script in the worktree>`, a trivial `pwsh -NoProfile -Command "Write-Host
hello"`, and `/usr/bin/pwsh -NoProfile -File ...` all fail with the same message — "this command runs
pwsh in a plain command; what it reads or is handed as shell text cannot be shown not to run git" —
including for a script with zero git calls. `dangerouslyDisableSandbox: true` does not bypass it.

This is not the Bash-tool sandbox described in the system prompt. It is a separate categorical guard
on interpreter invocations (`pwsh`, and complex `rtk`-rewritten commands — same message shape, see
[[rtk-rewrite-breaks-git-in-worktrees]]).

**Why:** the guard has no PowerShell parser and cannot prove even a trivial script never shells out
to git outside the worktree, so it denies the interpreter rather than the command.

**How to apply:** do not spend more than one retry varying `-File` vs `-Command` or relative vs
absolute path — it is categorical, not shape-dependent. Fall back to CI as the verification evidence
for anything needing `pwsh` inside a worktree, and state that explicitly in the
verified/not-verified ledger per [[verify-before-claiming-done]]. Ask the user before calling
`ExitWorktree` if a local run is essential. Re-test occasionally; this behaviour has changed before.
