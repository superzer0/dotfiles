#!/usr/bin/env bash
# PreToolUse(Bash): run rtk's command rewrite, minus two things rtk gets wrong
# for a permission system:
#  1. It attaches permissionDecision:"allow" to read-style rewrites. A hook
#     "allow" skips permission rules and the auto-mode classifier; rtk is an
#     output filter, not a permission authority. The decision is stripped.
#  2. It rewrites `helm uninstall` -> `rtk helm uninstall`; the rewritten text
#     no longer matches the Bash(...) ask rules in settings.json, so for those
#     commands the rewrite is skipped and the command runs as written. Whether
#     Claude Code evaluates the rules against the original or the rewritten
#     command is not documented: if the original, this pass-through is
#     redundant but harmless; if the rewrite, it is essential. Keep it.
# Credential-file reads are handled by cred-guard.sh (a deny wins over any
# rewrite), so `cat/head/tail` need no special case here.
# Requires: rtk, jq.
set -uo pipefail
out=$(rtk hook claude 2>/dev/null) || exit 0   # rtk failure = no rewrite, fail open
[ -n "$out" ] || exit 0
new=$(printf '%s' "$out" | jq -r '.hookSpecificOutput.updatedInput.command // empty' 2>/dev/null)
[ -n "$new" ] || exit 0

# commands gated by permissions.ask — keep them verbatim
case "$new" in
  "rtk helm uninstall"*|"rtk helm delete"*|"rtk terraform apply"*|"rtk terraform destroy"*|"rtk kubectl delete"*|"rtk az "*" delete"*) exit 0 ;;
esac

printf '%s' "$out" | jq -c 'del(.hookSpecificOutput.permissionDecision, .hookSpecificOutput.permissionDecisionReason)'
