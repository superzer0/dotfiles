#!/usr/bin/env bash
# Create (or reuse) this session's git worktree for a repository under $REPO_ROOT.
#
#   usage: new-worktree.sh <repo-dir-name> <topic-slug> [base-ref]
#
# Prints the worktree path on stdout; pass it to EnterWorktree.
# Layout: $REPO_ROOT/claude-worktrees/<repo>.<topic-slug>-<session-id-prefix>
# Branch: claude/<topic-slug>-<session-id-prefix>
set -euo pipefail

ROOT=${CLAUDE_REPO_ROOT:-$HOME/repo}
usage="usage: new-worktree.sh <repo-dir-name> <topic-slug> [base-ref]"
repo=${1:?$usage}
topic=${2:?$usage}
base=${3:-HEAD}

repo=${repo%/}
src=$ROOT/$repo
[ -e "$src/.git" ] || { echo "not a git repo: $src" >&2; exit 1; }

sid=${CLAUDE_CODE_SESSION_ID:-manual}
slug=$(printf '%s-%s' "$topic" "${sid:0:8}" | tr -c 'A-Za-z0-9._-' '-')
path=$ROOT/claude-worktrees/$repo.$slug
branch=claude/$slug

if [ -d "$path" ]; then
  echo "$path"
  exit 0
fi

if git -C "$src" show-ref --verify --quiet "refs/heads/$branch"; then
  git -C "$src" worktree add "$path" "$branch" >&2
else
  git -C "$src" worktree add "$path" -b "$branch" "$base" >&2
fi

echo "$path"
