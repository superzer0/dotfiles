#!/usr/bin/env bash
# Weekly audit (report-only, no changes) for the layout in
# [[session-cwd-is-repo-root]] / [[worktree-only-edits-for-repo]]:
#   - stray Claude session dirs: ~/.claude/projects/-home-YOUR_USER-repo-<something>
#     that isn't under the canonical claude-worktrees/ dir
#   - rogue git worktrees: any `git worktree list` entry outside
#     ${CLAUDE_REPO_ROOT:-$HOME/repo}/claude-worktrees/
#
# Does NOT fix anything automatically — merging stray session history
# (MEMORY.md dedup) and relocating worktrees needs judgment. It only logs
# findings so they don't go unnoticed again. Ask Claude to run the actual
# migration when this reports something.

set -uo pipefail

REPO_ROOT=${CLAUDE_REPO_ROOT:-$HOME/repo}
PROJECTS_DIR=$HOME/.claude/projects
LOG=$HOME/.claude/worktree-layout-audit.log

log() { printf '[%s] %s\n' "$(date -Is)" "$*" >> "$LOG"; }

log "=== layout audit run start ==="

strays=$(ls "$PROJECTS_DIR" 2>/dev/null | grep '^-home-YOUR_USER-repo-' | grep -v '^-home-YOUR_USER-repo-claude-worktrees-')
if [ -n "$strays" ]; then
  log "STRAY session dirs found:"
  while IFS= read -r d; do log "  - $d"; done <<< "$strays"
else
  log "no stray session dirs"
fi

rogue_found=0
shopt -s nullglob
for repo in "$REPO_ROOT"/*/; do
  repo="${repo%/}"
  name=$(basename "$repo")
  [ "$name" = "claude-worktrees" ] && continue
  [ -d "$repo/.git" ] || continue

  rogues=$(git -C "$repo" worktree list 2>/dev/null | tail -n +2 | grep -v '/claude-worktrees/')
  if [ -n "$rogues" ]; then
    rogue_found=1
    log "ROGUE worktrees ($name):"
    while IFS= read -r line; do log "  - $line"; done <<< "$rogues"
  fi
done
[ "$rogue_found" -eq 0 ] && log "no rogue worktrees"

log "=== layout audit run end ==="
