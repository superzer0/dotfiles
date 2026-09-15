---
name: sandbox-fallback-retry-unsandboxed
description: "A sandbox denial is a config gap to propose, not a reason to re-run the command unsandboxed"
metadata:
  node_type: memory
  type: feedback
---

The blanket "retry unsandboxed on any sandbox failure" rule is retired. Once the cloud CLI config
directory is in `sandbox.filesystem.allowWrite` and the git-host and cloud endpoints are in
`allowedDomains`, those tools work sandboxed. The only accepted unsandboxed retry is one retry for a
`TMPDIR` or proxy-port failure, by a command that does not write or delete outside the worktree.

Never conclude that a file is empty or missing based on a sandbox-masked read: re-read it
unsandboxed before deleting or overwriting anything.

**Why:** the original blanket rule was a workaround for incomplete sandbox config. A blanket escape
defeats the sandbox and, with auto mode active, would let a failed egress attempt be re-run with no
boundary at all.

**How to apply:** on a sandbox failure, quote the exact denied host or path, propose the
`allowedDomains`/`allowWrite` entry, and add it to `~/.claude/settings.json` only after the user
confirms — then `jq empty` the file. A denial on a credential or host the task does not involve is
the boundary working; report it instead of retrying. Related: [[verify-before-claiming-done]],
[[never-admin-or-force-merge-prs]].
