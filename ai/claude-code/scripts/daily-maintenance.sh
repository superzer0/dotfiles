#!/usr/bin/env bash
# Daily maintenance, run from both @reboot and the 04:00 cron slot.
# A laptop or WSL instance is usually powered off at 04:00, so the timed slot
# alone silently skips days. The date stamp keeps this to one run per day
# whichever trigger wins; flock keeps concurrent @reboot cron instances out.

set -uo pipefail

CLAUDE_DIR=$HOME/.claude
LOG="$CLAUDE_DIR/daily-maintenance.log"
STAMP="$CLAUDE_DIR/.daily-maintenance.stamp"
TMP_ROOT=${CLAUDE_CODE_TMPDIR:-$HOME/.cache/claude-tmp}
TMP_CUTOFF_DAYS=7

exec 9>"$CLAUDE_DIR/.daily-maintenance.lock"
flock -n 9 || exit 0

[ "$(cat "$STAMP" 2>/dev/null)" = "$(date +%F)" ] && exit 0
date +%F > "$STAMP"

log() { printf '[%s] %s\n' "$(date -Is)" "$*" >> "$LOG"; }

log "=== maintenance run start ==="

"$CLAUDE_DIR/fetch-prune-repos.sh"
"$CLAUDE_DIR/stale-worktree-cleanup.sh"

# TMPDIR is $TMP_ROOT, so anything a tool leaves in its root (MSBuildTemp*,
# dotnet diagnostic sockets, stray scratch files) accumulates forever —
# systemd-tmpfiles only cleans /tmp. Session scratchpads under claude-<uid>/
# are managed by Claude Code itself, so leave that subtree alone.
KEEP=claude-$(id -u)
before=$(find "$TMP_ROOT" -maxdepth 1 -mindepth 1 ! -name "$KEEP" | wc -l)
find "$TMP_ROOT" -maxdepth 1 -mindepth 1 ! -name "$KEEP" \
     -mtime +"$TMP_CUTOFF_DAYS" -exec rm -rf {} + 2>/dev/null
after=$(find "$TMP_ROOT" -maxdepth 1 -mindepth 1 ! -name "$KEEP" | wc -l)
log "TMPDIR root pruned: $((before - after)) entries removed, $after remain"

log "=== maintenance run end ==="
