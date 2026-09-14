#!/usr/bin/env bash
# Pipe-tests for the PreToolUse hooks in ~/.claude/hooks.
# Run: bash $HOME/.claude/hooks/tests/hooks.test.sh   (exit 0 = all ok)
set -uo pipefail
H=${HOOKS_DIR:-$HOME/.claude/hooks}   # override to test a staged copy
fail=0

# run <hook> <command> [cwd]  -> hook stdout (compact JSON or empty)
run() {
  local hook=$1 cmd=$2 cwd=${3:-$HOME/repo}
  jq -cn --arg c "$cmd" --arg d "$cwd" \
    '{session_id:"test",hook_event_name:"PreToolUse",tool_name:"Bash",tool_input:{command:$c},cwd:$d}' \
    | bash "$H/$hook"
}
# expect_rewrite <hook> <command> <expected rewritten command>: rewritten, no permissionDecision*
expect_rewrite() {
  local out; out=$(run "$1" "$2")
  local want; want=$(jq -cn --arg c "$3" '{command:$c}')
  if printf '%s' "$out" | grep -qF "\"updatedInput\":$want" && ! printf '%s' "$out" | grep -q permissionDecision; then
    echo "ok   rewrite $2  ->  $3"
  else echo "FAIL rewrite $2 -> ${out:-<empty>}"; fail=1; fi
}
# expect_silent <hook> <command>: hook prints nothing (command runs as written)
expect_silent() {
  local out; out=$(run "$1" "$2")
  if [ -z "$out" ]; then echo "ok   silent  $2"
  else echo "FAIL silent  $2 -> $out"; fail=1; fi
}
expect_deny() {
  local out; out=$(run "$@")
  if printf '%s' "$out" | grep -q '"permissionDecision":"deny"'; then echo "ok   deny  $2"
  else echo "FAIL deny  $2 -> ${out:-<empty>}"; fail=1; fi
}
expect_pass() {
  local out; out=$(run "$@")
  if printf '%s' "$out" | grep -q '"permissionDecision"'; then echo "FAIL pass  $2 -> $out"; fail=1
  else echo "ok   pass  $2"; fi
}

echo "== rtk-hook.sh =="
expect_rewrite rtk-hook.sh 'git status' 'rtk git status'
expect_rewrite rtk-hook.sh 'cat /etc/hostname' 'rtk read /etc/hostname'
expect_rewrite rtk-hook.sh 'cat ~/.config/gh/hosts.yml' 'rtk read ~/.config/gh/hosts.yml'   # cred-guard denies this one; rtk need not care
expect_silent  rtk-hook.sh 'terraform apply -auto-approve'
# gated infra: keep original text so the permissions.ask rules match
expect_silent  rtk-hook.sh 'helm uninstall x -n y'

echo "== cred-guard.sh =="
expect_deny cred-guard.sh 'cat ~/.config/gh/hosts.yml'
expect_deny cred-guard.sh 'grep oauth_token $HOME/.config/gh/hosts.yml'
expect_deny cred-guard.sh 'jq . $HOME/.azure/msal_token_cache.json'
expect_deny cred-guard.sh 'python3 -c "print(open(\"$HOME/.azure/msal_http_cache.bin\",\"rb\").read())"'
expect_deny cred-guard.sh 'cat ~/.docker/config.json'
expect_deny cred-guard.sh 'cat ~/.kube/config'
expect_deny cred-guard.sh 'cd /tmp && head -20 ~/.kube/config'
expect_pass cred-guard.sh 'KUBECONFIG=~/.kube/config kubectl get ns'
expect_pass cred-guard.sh 'helm --kubeconfig $HOME/.kube/config list -A'
expect_pass cred-guard.sh 'GH_HOST=git.example.com gh pr list --limit 1'
expect_pass cred-guard.sh 'az account show -o none'
expect_pass cred-guard.sh 'T=$(cat ~/.grafana-mcp-token); echo ok'
expect_pass cred-guard.sh 'cat ~/.config/gh/config.yml'
expect_pass cred-guard.sh 'ls -la'

echo "== merge-guard.sh =="
T=${TMPDIR:-/tmp}/merge-guard-test.$$
mkdir -p "$T" && git init -q -b main "$T/on-main" && git init -q -b claude/topic "$T/on-topic"

# admin merge
expect_deny merge-guard.sh 'gh pr merge 123 --admin --repo example/x'
expect_deny merge-guard.sh 'gh pr merge --squash --admin 123'
expect_deny merge-guard.sh 'rtk gh pr merge 123 --admin'
expect_deny merge-guard.sh 'cd /tmp && gh pr merge 123 --squash --admin'
# API merge / protection
expect_deny merge-guard.sh 'gh api -X PUT repos/example/x/pulls/12/merge'
expect_deny merge-guard.sh 'curl -X PUT https://git.example.com/api/v3/repos/example/x/pulls/12/merge'
expect_deny merge-guard.sh 'gh api -X DELETE repos/example/x/branches/main/protection'
expect_deny merge-guard.sh 'gh api --method PUT repos/example/x/rulesets/5 -f enforcement=disabled'
expect_deny merge-guard.sh 'gh api repos/example/x/rulesets -f enforcement=disabled'
# force push to protected
expect_deny merge-guard.sh 'git push --force origin main'
expect_deny merge-guard.sh 'git push -f origin HEAD:master'
expect_deny merge-guard.sh 'git push origin +main'
expect_deny merge-guard.sh 'git push --force-with-lease origin' "$T/on-main"
expect_deny merge-guard.sh 'git push --force origin HEAD' "$T/on-main"
expect_deny merge-guard.sh "git -C $T/on-main push --force"
# allowed
expect_pass merge-guard.sh 'gh pr merge 123 --squash --delete-branch'
expect_pass merge-guard.sh 'gh pr view 123 --json state'
expect_pass merge-guard.sh 'gh api repos/example/x/pulls/12'
expect_pass merge-guard.sh 'gh api repos/example/x/branches/main/protection'
expect_pass merge-guard.sh 'gh api -X GET repos/example/x/rulesets --paginate -f per_page=100'
expect_pass merge-guard.sh 'gh api --method GET repos/example/x/branches/main/protection -f foo=bar'
expect_pass merge-guard.sh 'git push origin claude/fix-thing'
expect_pass merge-guard.sh 'git push --force-with-lease origin claude/fix-thing'
expect_pass merge-guard.sh 'git push --force' "$T/on-topic"
expect_pass merge-guard.sh 'git push -u origin claude/topic' "$T/on-topic"
expect_pass merge-guard.sh 'ls -la'
rm -rf "$T"

exit $fail
