#!/usr/bin/env bash
# POSIX-shell peer of agent-skills-install.ps1, covering all 16 skills listed in
# ai/claude-code/skills.md (the .ps1 covers 12).
#
# Installs user-wide (-g) into ~/.agents/skills, symlinked into ~/.claude/skills
# (and the codex / github-copilot equivalents). State: ~/.agents/.skill-lock.json
#
# Three things that are easy to get wrong, all handled below:
#
#   1. `npx` reads stdin. Driving a `while read` loop from a pipe or heredoc on
#      stdin means the first `npx skills add` swallows the rest of the list and
#      the loop ends after one skill — silently, exit 0. The list is read on
#      fd 3 instead.
#
#   2. `--full-depth` is required for repos that have a SKILL.md at their root.
#      Without it the installer stops at the root skill and never scans
#      subdirectories, so e.g. github/gh-aw resolves to a single skill
#      ("GitHub Agentic Workflows") and `--skill github-pr-query` fails with
#      "No matching skills found" even though .github/skills/github-pr-query
#      exists. Harmless for repos without a root SKILL.md.
#
#   3. The installed-check must look at the agent directory, not just the store.
#      A skill can exist in ~/.agents/skills but have no symlink in
#      ~/.claude/skills, in which case Claude Code cannot see it. Checking only
#      the store skips it and leaves it invisible.
set -uo pipefail

AGENTS="-a claude-code -a codex -a github-copilot"

SKILLS="
az-cost-optimize|https://github.com/github/awesome-copilot
azure-role-selector|https://github.com/github/awesome-copilot
create-github-action-workflow-specification|https://github.com/github/awesome-copilot
dependabot|https://github.com/github/awesome-copilot
editorconfig|https://github.com/github/awesome-copilot
foundry-agent-sync|https://github.com/github/awesome-copilot
github-actions-efficiency|https://github.com/github/awesome-copilot
github-actions-hardening|https://github.com/github/awesome-copilot
microsoft-docs|https://github.com/github/awesome-copilot
multi-stage-dockerfile|https://github.com/github/awesome-copilot
caveman|https://github.com/juliusbrussee/caveman
find-skills|https://github.com/vercel-labs/skills
firecrawl|https://github.com/firecrawl/cli
github-pr-query|https://github.com/github/gh-aw
grill-me|https://github.com/mattpocock/skills
microsoft-foundry|https://github.com/microsoft/azure-skills
"

ok=0
skipped=0
failed=0

while IFS='|' read -r name url <&3; do
  [ -n "$name" ] || continue

  # Installed means: present in the store AND linked into the agent directory.
  if [ -e "$HOME/.agents/skills/$name" ] && [ -e "$HOME/.claude/skills/$name" ]; then
    printf 'SKIP    %s\n' "$name"
    skipped=$((skipped + 1))
    continue
  fi

  printf 'INSTALL %-45s <- %s\n' "$name" "$url"
  if npx -y skills add "$url" --skill "$name" --full-depth $AGENTS -g -y \
       </dev/null >/dev/null 2>&1; then
    printf '  ok\n'
    ok=$((ok + 1))
  else
    printf '  FAILED — retry by hand to see why:\n'
    printf '    npx -y skills add %s --skill %s --full-depth %s -g -y\n' \
      "$url" "$name" "$AGENTS"
    failed=$((failed + 1))
  fi
done 3<<EOF
$SKILLS
EOF

printf '\n%d installed, %d already present, %d failed\n' "$ok" "$skipped" "$failed"
[ "$failed" -eq 0 ]
