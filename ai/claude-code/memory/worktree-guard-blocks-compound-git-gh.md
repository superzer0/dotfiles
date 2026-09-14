---
name: worktree-guard-blocks-compound-git-gh
description: "In a worktree-isolated session the guard refuses compound Bash commands naming git/gh with computed values, including harmless ones like cat of a .github path"
metadata:
  node_type: memory
  type: reference
---

While a session is worktree-isolated, the guard rejects any Bash command it cannot statically prove
targets that worktree. It refuses more than real git writes:

- a `for` loop `cat`-ing paths containing `.github`
- `cd ~/repo/<other-repo> && git ...` (reading another checkout)
- `dotnet ... -o "$TMPDIR/x"` — a runtime-computed value inside a construct it cannot parse
- `gh run view -q '.status + " / " + .conclusion'` — the quoted jq expression is "too complex"
- a `sed` program containing a literal `.git/config` or a `#` delimiter clash

The message always says the operation must target the session's own worktree, even when the command
does not touch git at all. Workarounds: use `Read` instead of shelling out for files in another
checkout, pass literal paths rather than `$TMPDIR`, and split compound commands into single plain
invocations with simple `-q` selectors.

Distinct from [[rtk-rewrite-breaks-git-in-worktrees]], which is the rtk rewrite, not this guard.
