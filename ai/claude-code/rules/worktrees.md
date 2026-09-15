## Worktree-only edits for ~/repo

Every repository under `~/repo` is a reference checkout: read it, never change it. No `Edit`/`Write`, no `sed -i`, heredoc, `git apply`, formatter, or codegen against a main checkout. All file changes happen in a per-session git worktree under `~/repo/claude-worktrees/`, so parallel sessions never collide and every change set is easy to find.

A `PreToolUse` hook (`~/.claude/hooks/worktree-guard.sh`) denies `Edit`/`Write`/`NotebookEdit` inside a main checkout, so this much is enforced, not just advised. Bash writes (`sed -i`, heredoc, `git checkout --`, `rm`) are not caught by any hook or by the sandbox — `~/repo` is Bash-writable — so for Bash this rule is discipline only.

### Making a change

1. Create (or reuse) this session's worktree for the repo:
   ```bash
   bash ~/.claude/new-worktree.sh <repo-dir-name> <topic-slug>
   ```
   It prints `~/repo/claude-worktrees/<repo>.<topic-slug>-<session-id-prefix>` and creates branch `claude/<topic-slug>-<session-id-prefix>`. The base ref is the main checkout's current `HEAD`; pass a third argument (e.g. `origin/main`) for a clean base.
2. `cd ~/repo/<repo-dir-name>`. `EnterWorktree` resolves the owning repo from the session's
   working directory, never from the `path:` argument, so calling it straight from the `~/repo` launch
   dir fails with `Cannot enter an existing worktree: the current directory is not in a git repository`
   (`~/repo` is not a repo, just sibling checkouts).
3. Call `EnterWorktree` with `path:` set to that path. The session's working directory moves there.
   Enter the worktree before any shell write anyway — the point is to get `Edit`/`Write` unblocked and
   the cwd correct. The guard fails open if `jq` or `git` is missing; that is deliberate (never block a
   session), not a permission.
4. Do the work, commit, push, and open the PR from inside the worktree.

One worktree per repo per session — run the script once per repo when a session touches several.

Fetching before creating the worktree is good practice for a clean base: `git fetch origin` first, then
`new-worktree.sh <repo> <slug> origin/main`.

### Rules

- Use `EnterWorktree` with `path:` only. Never `name:` — that creates `<repo>/.claude/worktrees/...`, outside the central directory.
- Never spawn subagents with `isolation: "worktree"`, for the same reason. Enter the worktree first; subagents inherit the working directory.
- One `EnterWorktree` at a time. Call `ExitWorktree` before entering a different worktree — a nested `EnterWorktree` can leave the session with no active worktree while the cwd is still inside one, and every `git commit` then fails on `<repo>/.git/worktrees/<name>/index.lock`.
- Switching repos mid-session takes all three steps, in this order: `ExitWorktree(action: "keep")` →
  `cd ~/repo/<next-repo>` → `EnterWorktree(path: …<next-repo>.<slug>-<session>)`. Skipping
  the `cd` gives `is not a registered worktree of <previous repo>`; calling `EnterWorktree` from inside
  another repo's worktree gives `<previous repo>/.claude/worktrees does not exist`. Both mean the
  anchor is still the old repo, not that the target worktree is missing.
- Prefer one repo per session over hopping — the `EnterWorktree` resolution behaviour above is the reason.
- Two sessions must not hold worktrees in `~/repo` at the same time: `activeWorktreeSession` in
  `~/.claude.json` is a single slot per project, so the second session's `EnterWorktree` overwrites the
  first session's record and its `ExitWorktree` nulls it. Files and branch survive; the bookkeeping
  does not. Use separate worktrees from separate sessions only if you accept that.
- Read-only work (reading, grep, `git log`, `terraform plan`, `helm template`) may stay in the main checkout.
- `git worktree remove` fails under the Bash sandbox with `Device or resource busy`. Clean up with `rm -rf <worktree-path>` followed by `git -C <repo> worktree prune`, run with `dangerouslyDisableSandbox: true`.
- Legacy worktrees parked next to the repos (`<repo>.wt-*`, `<repo>-pr<N>`) are blocked by the guard too. Migrate one with `git worktree move <old> ~/repo/claude-worktrees/<new-name>`, or finish it outside Claude Code.

The scripts read `CLAUDE_REPO_ROOT` and fall back to `$HOME/repo`. If your checkouts live elsewhere, export that variable and replace `~/repo` throughout this file — the hook, the rule text, and the sandbox `allowWrite` entry must agree.
