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
}
  
foreach ($skill in $skills.Keys) {
  npx skills add $skills[$skill] --skill $skill -a claude-code -a codex -a github-copilot -g -y
}

