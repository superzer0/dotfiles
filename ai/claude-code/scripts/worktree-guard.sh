#!/usr/bin/env bash
# PreToolUse guard (Edit|Write|NotebookEdit): no file changes in a main checkout
# under $REPO_ROOT. Changes belong in a worktree under $REPO_ROOT/claude-worktrees.
# See ../rules/worktrees.md
set -uo pipefail

ROOT=${CLAUDE_REPO_ROOT:-$HOME/repo}
WORKTREES=$ROOT/claude-worktrees

target=$(jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' 2>/dev/null) || exit 0
[ -n "$target" ] || exit 0

dir=$(realpath -m "$(dirname -- "$target")" 2>/dev/null) || exit 0

case "$dir/" in
  "$WORKTREES"/*) exit 0 ;;  # already inside a central worktree
  "$ROOT"/*) ;;              # under $ROOT - keep checking
  *) exit 0 ;;               # outside $ROOT - not this policy's business
esac

# A new file may name directories that do not exist yet; ask git about the
# nearest existing ancestor instead.
while [ ! -d "$dir" ] && [ "$dir" != / ]; do dir=$(dirname -- "$dir"); done

top=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || exit 0
[ -n "$top" ] || exit 0  # loose file under $ROOT, not in any repo

repo=$(basename -- "$top")
jq -n --arg repo "$repo" --arg top "$top" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: (
      "Worktree-only policy: no direct changes in \($top).\n" +
      "1. bash ~/.claude/new-worktree.sh \($repo) <topic-slug>\n" +
      "2. call EnterWorktree with the path it prints\n" +
      "3. redo this change there (same relative path)\n" +
      "Details: ~/.claude/rules/worktrees.md"
    )
  }
}'
