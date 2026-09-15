#!/usr/bin/env bash
# Daily cleanup of stale entries in ${CLAUDE_REPO_ROOT:-$HOME/repo}/claude-worktrees/.
# Pure bash/git — no Claude CLI, no permission bypass.
# Policy: see memory/stale-worktree-cleanup-policy.md
#
# A worktree is a removal candidate when BOTH its last commit date and its
# newest tracked/untracked file mtime are older than CUTOFF_DAYS. Candidates
# are skipped (never deleted) when dirty or when their branch has an open PR.

set -uo pipefail

WORKTREES_DIR=${CLAUDE_REPO_ROOT:-$HOME/repo}/claude-worktrees
LOG=$HOME/.claude/stale-worktree-cleanup.log
CUTOFF_DAYS=7

# `date -Is` is GNU-only; BSD date rejects -I. This spelling works on both.
log() { printf '[%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" >> "$LOG"; }

log "=== cleanup run start ==="

# The open-PR check below is the only thing between an active PR's branch and
# rm -rf, and it degrades silently when gh is absent. cron's PATH is
# /usr/bin:/bin, which has git and flock but no gh — that disabled the guard
# once and took the worktrees of two open PRs with it.
# Refuse to run rather than delete blind.
command -v gh >/dev/null 2>&1 || {
  log "ABORT: gh not found on PATH ($PATH) — refusing to delete without the open-PR check"
  exit 1
}

now=$(date +%s)
cutoff=$(( now - CUTOFF_DAYS * 86400 ))

# Newest mtime among non-.git files, as a unix timestamp.
#
# `find -printf` is GNU-only; BSD find (macOS) rejects it. The old spelling sent
# that error to /dev/null, so on macOS this returned empty and staleness fell
# back to the commit date alone — meaning a clean worktree with an old commit
# but recently touched files read as stale. This is the staleness test of a
# script that runs `rm -rf`, so it must not degrade silently: prefer GNU find
# (coreutils/findutils `gfind`), fall back to `stat`, and pick the stat flavour
# by probing rather than by guessing the platform.
if command -v gfind >/dev/null 2>&1; then
  FIND_BIN=gfind
else
  FIND_BIN=find
fi
if "$FIND_BIN" . -maxdepth 0 -printf '' >/dev/null 2>&1; then
  MTIME_MODE=printf
elif stat -f '%m' . >/dev/null 2>&1; then
  MTIME_MODE=stat_bsd        # macOS / BSD
elif stat -c '%Y' . >/dev/null 2>&1; then
  MTIME_MODE=stat_gnu
else
  MTIME_MODE=none
fi

newest_mtime() {
  local dir=$1
  case $MTIME_MODE in
    printf)
      "$FIND_BIN" "$dir" -path "$dir/.git" -prune -o -type f -printf '%T@\n' 2>/dev/null \
        | sort -n | tail -1 ;;
    stat_bsd)
      find "$dir" -path "$dir/.git" -prune -o -type f -print0 2>/dev/null \
        | xargs -0 stat -f '%m' 2>/dev/null | sort -n | tail -1 ;;
    stat_gnu)
      find "$dir" -path "$dir/.git" -prune -o -type f -print0 2>/dev/null \
        | xargs -0 stat -c '%Y' 2>/dev/null | sort -n | tail -1 ;;
    none)
      echo "" ;;
  esac
}

# No way to read mtimes means the staleness test is running on half its inputs.
# Refuse rather than delete on a weaker signal than the policy describes.
if [ "$MTIME_MODE" = none ]; then
  log "ABORT: no usable find -printf or stat on PATH — refusing to delete on commit date alone"
  exit 1
fi

shopt -s nullglob
for wt in "$WORKTREES_DIR"/*/; do
  wt="${wt%/}"
  name=$(basename "$wt")
  [ -e "$wt/.git" ] || continue

  lc_ts=$(git -C "$wt" log -1 --format=%ct 2>/dev/null || echo 0)
  mt_ts=$(newest_mtime "$wt")
  mt_ts=${mt_ts%.*}
  [ -z "$mt_ts" ] && mt_ts=0

  last=$lc_ts
  [ "$mt_ts" -gt "$last" ] && last=$mt_ts

  if [ "$last" -ge "$cutoff" ]; then
    continue
  fi
  age_days=$(( (now - last) / 86400 ))

  if [ -n "$(git -C "$wt" status --porcelain 2>/dev/null)" ]; then
    log "SKIP dirty (${age_days}d stale): $name"
    continue
  fi

  branch=$(git -C "$wt" branch --show-current 2>/dev/null)
  if [ -z "$branch" ]; then
    log "SKIP no branch, cannot check for an open PR (${age_days}d stale): $name"
    continue
  fi

  # An empty result must mean "no open PR", never "the query failed" — a
  # network blip, an expired token or a rate limit would otherwise read as
  # permission to delete. Gate on gh's exit status, not on its output.
  pr_open=$(cd "$wt" && gh pr list --head "$branch" --state open --json number -q '.[0].number' 2>/dev/null)
  if [ $? -ne 0 ]; then
    log "SKIP gh query failed, open-PR state unknown (${age_days}d stale): $name"
    continue
  fi
  if [ -n "$pr_open" ]; then
    log "SKIP open PR #$pr_open (${age_days}d stale): $name"
    continue
  fi

  common_dir=$(git -C "$wt" rev-parse --git-common-dir 2>/dev/null)
  case "$common_dir" in
    /*) : ;;
    *) common_dir="$wt/$common_dir" ;;
  esac
  main_repo=$(dirname "$common_dir")

  rm -rf "$wt"
  git -C "$main_repo" worktree prune
  # safe delete: only succeeds if branch is fully merged, leaves it otherwise
  [ -n "$branch" ] && git -C "$main_repo" branch -d "$branch" >/dev/null 2>&1

  log "REMOVED (${age_days}d stale, branch $branch): $name"
done

log "=== cleanup run end ==="
