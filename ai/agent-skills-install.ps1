# Installs the skills listed in ai/claude-code/skills.md user-wide (-g) into
# ~/.agents/skills, symlinked into the per-agent directories.
# State lives in ~/.agents/.skill-lock.json.
#
# See agent-skills-install.sh for the POSIX peer of this script.

$skills = [ordered]@{
  'az-cost-optimize'                            = 'https://github.com/github/awesome-copilot'
  'azure-role-selector'                         = 'https://github.com/github/awesome-copilot'
  'create-github-action-workflow-specification' = 'https://github.com/github/awesome-copilot'
  'dependabot'                                  = 'https://github.com/github/awesome-copilot'
  'editorconfig'                                = 'https://github.com/github/awesome-copilot'
  'foundry-agent-sync'                          = 'https://github.com/github/awesome-copilot'
  'github-actions-efficiency'                   = 'https://github.com/github/awesome-copilot'
  'github-actions-hardening'                    = 'https://github.com/github/awesome-copilot'
  'microsoft-docs'                              = 'https://github.com/github/awesome-copilot'
  'multi-stage-dockerfile'                      = 'https://github.com/github/awesome-copilot'
  'caveman'                                     = 'https://github.com/juliusbrussee/caveman'
  'find-skills'                                 = 'https://github.com/vercel-labs/skills'
  'firecrawl'                                   = 'https://github.com/firecrawl/cli'
  'github-pr-query'                             = 'https://github.com/github/gh-aw'
  'grill-me'                                    = 'https://github.com/mattpocock/skills'
  'microsoft-foundry'                           = 'https://github.com/microsoft/azure-skills'
}

$agentDirs = @(
  (Join-Path $HOME '.claude/skills'),
  (Join-Path $HOME '.codex/skills'),
  (Join-Path $HOME '.config/github-copilot/skills')
)

function Test-SkillInstalled {
  param(
    [Parameter(Mandatory = $true)]
    [string]$SkillName
  )

  # A skill counts as installed only when it is in the store AND linked into at
  # least one agent directory. Checking the store alone (or either path, as this
  # did before) skips skills that are present but unlinked, leaving them
  # invisible to the agent with nothing to indicate why.
  $store = Join-Path $HOME ".agents/skills/$SkillName"
  if (-not (Test-Path -Path $store)) {
    return $false
  }

  foreach ($dir in $agentDirs) {
    if (Test-Path -Path (Join-Path $dir $SkillName)) {
      return $true
    }
  }

  return $false
}

$ok = 0; $skipped = 0; $failed = @()

foreach ($skill in $skills.Keys) {
  if (Test-SkillInstalled -SkillName $skill) {
    Write-Host "SKIP    $skill"
    $skipped++
    continue
  }

  Write-Host "INSTALL $skill <- $($skills[$skill])"

  # --full-depth is required for repositories that carry a SKILL.md at their
  # root: without it the installer stops there and never scans subdirectories,
  # so github/gh-aw resolves to a single skill ("GitHub Agentic Workflows") and
  # --skill github-pr-query fails with "No matching skills found" even though
  # .github/skills/github-pr-query exists. It is a no-op for the other repos.
  npx -y skills add $skills[$skill] --skill $skill --full-depth `
    -a claude-code -a codex -a github-copilot -g -y

  if ($LASTEXITCODE -eq 0) {
    $ok++
  }
  else {
    Write-Warning "Failed to install '$skill' (exit $LASTEXITCODE)"
    $failed += $skill
  }
}

Write-Host ''
Write-Host "$ok installed, $skipped already present, $($failed.Count) failed"
if ($failed.Count -gt 0) {
  Write-Host "Failed: $($failed -join ', ')"
  exit 1
}
