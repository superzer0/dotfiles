#!/usr/bin/env bash
# PreToolUse(Bash): deny shell reads of the CLI credential files that must stay
# readable *by their own CLIs* inside the sandbox: gh's hosts.yml, az's MSAL
# caches, kubeconfig, docker config. A Read(...) deny rule cannot be used for
# these — Claude Code merges Read deny rules into the sandbox's OS-level read
# deny, which broke gh itself. A hook only sees the command text, so
# `gh pr list` keeps working while `cat ~/.config/gh/hosts.yml` is refused.
# ~/.ssh is not listed here: deny it at the OS level via sandbox.credentials.
# Add your own token files to the first pattern as needed.
# Requires: jq.
set -uo pipefail
cmd=$(jq -r '.tool_input.command // empty' 2>/dev/null) || exit 0
[ -n "$cmd" ] || exit 0

HOMES='(~|/home/[^/[:space:]]+|/Users/[^/[:space:]]+|\$HOME|\$\{HOME\})'
if printf '%s' "$cmd" | grep -Eq "$HOMES/(\.config/gh/hosts\.yml|\.azure/msal_[a-z_]+\.(json|bin)|\.docker/config\.json)"; then
  what='a CLI credential file (gh hosts.yml / az MSAL cache / docker config)'
elif printf '%s' "$cmd" | grep -Eq "$HOMES/\.kube/config" && ! printf '%s' "$cmd" | grep -Eq '(^|[[:space:]])(kubectl|helm|kubelogin|k9s)([[:space:]]|$)'; then
  what='the kubeconfig (client certificates inside)'
else
  exit 0
fi
jq -cn --arg w "$what" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",
  permissionDecisionReason:("cred-guard: refusing to read " + $w + " from the shell. The CLI that owns it can use it; the transcript must not. Tell the user if you believe you need the contents.")}}'
exit 0
