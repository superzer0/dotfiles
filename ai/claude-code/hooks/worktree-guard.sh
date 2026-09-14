#!/usr/bin/env bash
# PreToolUse guard (Edit|Write|NotebookEdit): no file changes in a main checkout
# under $REPO_ROOT. Changes belong in a worktree under $REPO_ROOT/claude-worktrees.
# See ../rules/worktrees.md
set -uo pipefail

ROOT=${CLAUDE_REPO_ROOT:-$HOME/repo}
WORKTREES=$ROOT/claude-worktrees

target=$(jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' 2>/dev/null) || exit 0
[ -n "$target" ] || exit 0

# BSD realpath (macOS) has no -m. With the `|| exit 0` below, `realpath -m`
# there fails and the guard silently stops guarding, so normalise portably:
# GNU realpath when it exists, otherwise resolve the nearest existing ancestor
# and re-append the tail that does not exist yet.
REALPATH_M=
if command -v grealpath >/dev/null 2>&1; then
  REALPATH_M=grealpath
elif realpath -m / >/dev/null 2>&1; then
  REALPATH_M=realpath
fi

abspath() {
  if [ -n "$REALPATH_M" ]; then
    "$REALPATH_M" -m "$1"
    return
  fi
  local p=$1 tail=
  case $p in /*) ;; *) p=$PWD/$p ;; esac
  while [ ! -d "$p" ] && [ "$p" != / ]; do
    tail=$(basename -- "$p")${tail:+/$tail}
    p=$(dirname -- "$p")
  done
  p=$(cd -P -- "$p" 2>/dev/null && pwd) || return 1
  if [ -n "$tail" ]; then printf '%s/%s\n' "${p%/}" "$tail"; else printf '%s\n' "$p"; fi
}

dir=$(abspath "$(dirname -- "$target")" 2>/dev/null) || exit 0

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
