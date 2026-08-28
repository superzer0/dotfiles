## Worktree-only edits for ~/repo

Every repository under `~/repo` is a reference checkout: read it, never change it. No `Edit`/`Write`, no `sed -i`, heredoc, `git apply`, formatter, or codegen against a main checkout. All file changes happen in a per-session git worktree under `~/repo/claude-worktrees/`, so parallel sessions never collide and every change set is easy to find.

A `PreToolUse` hook (`~/.claude/worktree-guard.sh`) denies `Edit`/`Write`/`NotebookEdit` inside a main checkout, so this is enforced, not just advised.

### Making a change

1. Create (or reuse) this session's worktree for the repo:
   ```bash
   bash ~/.claude/new-worktree.sh <repo-dir-name> <topic-slug>
   ```
   It prints `~/repo/claude-worktrees/<repo>.<topic-slug>-<session-id-prefix>` and creates branch `claude/<topic-slug>-<session-id-prefix>`. The base ref is the main checkout's current `HEAD`; pass a third argument (e.g. `origin/main`) for a clean base.
2. Call `EnterWorktree` with `path:` set to that path. The session's working directory moves there and the Bash sandbox narrows to the worktree, which also stops shell commands from writing to main checkouts.
3. Do the work, commit, push, and open the PR from inside the worktree.

One worktree per repo per session — run the script once per repo when a session touches several.

### Rules

- Use `EnterWorktree` with `path:` only. Never `name:` — that creates `<repo>/.claude/worktrees/...`, outside the central directory.
- Never spawn subagents with `isolation: "worktree"`, for the same reason. Enter the worktree first; subagents inherit the working directory.
- Read-only work (reading, grep, `git log`, `terraform plan`, `helm template`) may stay in the main checkout.
- `git worktree remove` fails under the Bash sandbox with `Device or resource busy`. Clean up with `rm -rf <worktree-path>` followed by `git -C <repo> worktree prune`, run with `dangerouslyDisableSandbox: true`.
- Legacy worktrees parked next to the repos (`<repo>.wt-*`, `<repo>-pr<N>`) are blocked by the guard too. Migrate one with `git worktree move <old> ~/repo/claude-worktrees/<new-name>`, or finish it outside Claude Code.

### Adapting the root directory

The scripts read `CLAUDE_REPO_ROOT` and fall back to `$HOME/repo`. If your checkouts live elsewhere, export that variable and replace `~/repo` throughout this file — the hook, the rule text, and the sandbox `allowWrite` entry must agree.
