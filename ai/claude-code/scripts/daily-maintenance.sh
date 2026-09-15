#!/usr/bin/env bash
# Daily maintenance, run from both @reboot and the 04:00 cron slot.
# A laptop or WSL instance is usually powered off at 04:00, so the timed slot
# alone silently skips days. The date stamp keeps this to one run per day
# whichever trigger wins; the lock keeps concurrent @reboot cron instances out.

set -uo pipefail

CLAUDE_DIR=$HOME/.claude
LOG="$CLAUDE_DIR/daily-maintenance.log"
STAMP="$CLAUDE_DIR/.daily-maintenance.stamp"
LOCKDIR="$CLAUDE_DIR/.daily-maintenance.lock.d"
TMP_ROOT=${CLAUDE_CODE_TMPDIR:-$HOME/.cache/claude-tmp}
TMP_CUTOFF_DAYS=7

# macOS has no flock(1). `flock -n 9 || exit 0` there is a command-not-found
# that trips the `|| exit 0` on every run, so the whole maintenance layer
# becomes a silent no-op that cron still reports as success. mkdir is atomic
# on every POSIX filesystem, so use it as the mutex and keep flock nowhere in
# the path.
if mkdir "$LOCKDIR" 2>/dev/null; then
  printf '%s\n' "$$" > "$LOCKDIR/pid"
  trap 'rm -rf "$LOCKDIR"' EXIT INT TERM
else
  # The lock exists. Either a sibling is running, or a previous run was killed
  # before its trap fired — in which case the recorded pid is gone and the lock
  # must not wedge maintenance forever.
  lock_pid=$(cat "$LOCKDIR/pid" 2>/dev/null)
  if [ -n "$lock_pid" ] && kill -0 "$lock_pid" 2>/dev/null; then
    exit 0
  fi
  rm -rf "$LOCKDIR"
  mkdir "$LOCKDIR" 2>/dev/null || exit 0
  printf '%s\n' "$$" > "$LOCKDIR/pid"
  trap 'rm -rf "$LOCKDIR"' EXIT INT TERM
fi

[ "$(cat "$STAMP" 2>/dev/null)" = "$(date +%F)" ] && exit 0
date +%F > "$STAMP"

# `date -Is` is GNU-only; BSD date rejects -I. This spelling is identical on
# both and is what every log() in this directory uses.
log() { printf '[%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" >> "$LOG"; }

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
