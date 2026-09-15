#!/usr/bin/env bash
# Daily `git fetch --prune` across every top-level repo checkout under $HOME/repo.
# Surfaces newly-[gone] local branches so commit-commands:clean_gone has something to find.

set -uo pipefail

REPO_ROOT=${CLAUDE_REPO_ROOT:-$HOME/repo}
LOG=$HOME/.claude/fetch-prune-repos.log

log() { printf '[%s] %s\n' "$(date -Is)" "$*" >> "$LOG"; }

log "=== fetch --prune run start ==="

shopt -s nullglob
for repo in "$REPO_ROOT"/*/; do
  repo="${repo%/}"
  name=$(basename "$repo")
  [ "$name" = "claude-worktrees" ] && continue
  [ -d "$repo/.git" ] || continue

  out=$(git -C "$repo" fetch --prune --quiet 2>&1)
  status=$?
  if [ "$status" -ne 0 ]; then
    log "FETCH FAILED ($name): $out"
    continue
  fi

  gone=$(git -C "$repo" branch -vv 2>/dev/null | grep ': gone]' | awk '{print $1}')
  if [ -n "$gone" ]; then
    log "GONE branches ($name): $(echo "$gone" | tr '\n' ' ')"
  fi
done

log "=== fetch --prune run end ==="
