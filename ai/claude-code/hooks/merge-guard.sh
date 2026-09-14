#!/usr/bin/env bash
# PreToolUse(Bash): user-set HARD STOP — never merge a PR as admin or by force.
# Denies deterministically, regardless of permission mode, allow rules, sandbox
# auto-allow, or another hook's "allow" (deny always wins). Companion to
# autoMode.hard_deny in ~/.claude/settings.json, which only the classifier reads.
# Requires: jq, git. See ~/.claude/hooks/tests/hooks.test.sh for the contract.
set -uo pipefail

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null) || exit 0
[ -n "$cmd" ] || exit 0
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)

deny() {
  jq -cn --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",
    permissionDecisionReason:("merge-guard: " + $r + ". User-set hard stop: do not retry, reword, or run unsandboxed — tell the user and let them do it.")}}'
  exit 0
}

PROTECTED='^(main|master|develop|release(/.*)?)$'
SP='[[:space:]]'

# 1. admin merge
if printf '%s' "$cmd" | grep -Eq "(^|$SP|[;&|])gh$SP+pr$SP+merge\b.*(^|$SP)--admin(\b|$)"; then
  deny 'gh pr merge --admin bypasses required reviews/checks'
fi

# 2. REST API: merge endpoint (any method), protection/rulesets (mutating)
if printf '%s' "$cmd" | grep -Eq "(^|$SP|[;&|])(gh$SP+api|curl|wget)\b"; then
  printf '%s' "$cmd" | grep -Eq '/pulls/[^/[:space:]]+/merge(\b|$)' \
    && deny 'direct PR merge via REST API'
  if printf '%s' "$cmd" | grep -Eq '/branches/[^[:space:]]+/protection(\b|$)|/rulesets(\b|$)'; then
    mut="(-X|--method|--request)($SP+|=)(PUT|POST|PATCH|DELETE)\b"
    body="(^|$SP)(-f|-F|--field|--raw-field|--input|-d|--data(-[a-z]+)?)($SP|=|$)"
    getm="(-X|--method|--request)($SP+|=)GET\b"
    if printf '%s' "$cmd" | grep -Eq -- "$mut"; then
      deny 'branch protection / ruleset modification via REST API'
    elif printf '%s' "$cmd" | grep -Eq -- "$body" && ! printf '%s' "$cmd" | grep -Eq -- "$getm"; then
      # gh api and curl switch to POST when a body flag is given without an explicit method
      deny 'branch protection / ruleset modification via REST API (body flag implies POST)'
    fi
  fi
fi

# 3. force push to a protected branch
if printf '%s' "$cmd" | grep -Eq "(^|$SP|[;&|])git($SP+-C$SP+[^[:space:]]+)?$SP+push\b"; then
  # the push segment only: from the last `git … push` to the next ; & |
  seg=$(printf '%s' "$cmd" | sed -E 's/.*git([[:space:]]+-C[[:space:]]+[^[:space:]]+)?[[:space:]]+push//; s/[;&|].*$//')
  gitdir=$(printf '%s' "$cmd" | sed -nE 's/.*git[[:space:]]+-C[[:space:]]+([^[:space:]]+)[[:space:]]+push.*/\1/p')
  [ -n "$gitdir" ] && cwd=$gitdir
  if printf '%s' "$seg" | grep -Eq -- "(^|$SP)(--force|-f|--force-with-lease(=[^[:space:]]*)?|--force-if-includes)($SP|$)|(^|$SP)\+[^[:space:]]+"; then
    # explicit protected name anywhere in the push segment (refspec src or dst, +ref)
    if printf '%s' "$seg" | grep -Eqw 'main|master|develop|release(/[^[:space:]]*)?'; then
      deny 'force push to a protected branch (main/master/develop/release)'
    fi
    # implicit target: no refspec, or HEAD -> current branch in cwd decides
    toks=()
    for t in $seg; do case $t in -*) ;; *) toks+=("$t");; esac; done
    if [ "${#toks[@]}" -le 1 ] || printf '%s\n' "${toks[@]}" | grep -qx 'HEAD'; then
      cur=$(git -C "${cwd:-.}" symbolic-ref --short -q HEAD 2>/dev/null || true)
      if [ -n "$cur" ] && printf '%s' "$cur" | grep -Eq "$PROTECTED"; then
        deny "force push while on protected branch '$cur'"
      fi
    fi
  fi
fi

exit 0
