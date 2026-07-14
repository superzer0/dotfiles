$skills = @{
  'create-github-action-workflow-specification' = 'https://github.com/github/awesome-copilot'
  'multi-stage-dockerfile'                      = 'https://github.com/github/awesome-copilot'
  'azure-role-selector'                         = 'https://github.com/github/awesome-copilot'
  'az-cost-optimize'                            = 'https://github.com/github/awesome-copilot'
  'dependabot'                                  = 'https://github.com/github/awesome-copilot'
  'foundry-agent-sync'                          = 'https://github.com/github/awesome-copilot'
  'find-skills'                                 = 'https://github.com/vercel-labs/skills'
  'grill-me'                                    = 'https://github.com/mattpocock/skills'
  'firecrawl'                                   = 'https://github.com/firecrawl/cli'
  'editorconfig'                                = 'https://github.com/github/awesome-copilot'
  'github-actions-efficiency'                   = 'https://github.com/github/awesome-copilot'
  'github-actions-hardening'                    = 'https://github.com/github/awesome-copilot'
}

function Test-SkillInstalled {
  param(
    [Parameter(Mandatory = $true)]
    [string]$SkillName
  )

  $possiblePaths = @(
    (Join-Path $HOME ".agents/skills/$SkillName"),
    (Join-Path $HOME ".claude/skills/$SkillName")
  )

  foreach ($path in $possiblePaths) {
    if (Test-Path -Path $path) {
      return $true
    }
  }

  return $false
}

foreach ($skill in $skills.Keys) {
  if (Test-SkillInstalled -SkillName $skill) {
    Write-Host "Skipping '$skill' (already installed)."
    continue
  }

  Write-Host "Installing '$skill'..."
  npx skills add $skills[$skill] --skill $skill -a claude-code -a codex -a github-copilot -g -y
}

