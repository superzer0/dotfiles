# Skills

None of these are mine — they are installed from public repositories into
`~/.agents/skills/` and symlinked into `~/.claude/skills/`. This file is the
source list so a new machine can reinstall them; the skill bodies stay upstream
where they get maintained (and where their own licences live).

| Skill | Source |
|---|---|
| `az-cost-optimize` | https://github.com/github/awesome-copilot |
| `azure-role-selector` | https://github.com/github/awesome-copilot |
| `create-github-action-workflow-specification` | https://github.com/github/awesome-copilot |
| `dependabot` | https://github.com/github/awesome-copilot |
| `editorconfig` | https://github.com/github/awesome-copilot |
| `foundry-agent-sync` | https://github.com/github/awesome-copilot |
| `github-actions-efficiency` | https://github.com/github/awesome-copilot |
| `github-actions-hardening` | https://github.com/github/awesome-copilot |
| `microsoft-docs` | https://github.com/github/awesome-copilot |
| `multi-stage-dockerfile` | https://github.com/github/awesome-copilot |
| `caveman` | https://github.com/juliusbrussee/caveman |
| `find-skills` | https://github.com/vercel-labs/skills |
| `firecrawl` | https://github.com/firecrawl/cli |
| `github-pr-query` | https://github.com/github/gh-aw |
| `grill-me` | https://github.com/mattpocock/skills |
| `microsoft-foundry` | https://github.com/microsoft/azure-skills |

Installed state lives in `~/.agents/.skill-lock.json` (source URL, skill path
inside the repo, folder hash, install/update timestamps). That file is worth
backing up — it is the only record of which upstream path each skill came from.

## Plugins

Plugin marketplaces and the enabled plugin list are in `settings.json`
(`extraKnownMarketplaces` + `enabledPlugins`). Everything listed there is
public. Add a private marketplace with:

```
/plugin marketplace add <owner>/<repo>
```

GitHub Enterprise hosts need the full git URL — the `owner/repo` shorthand does
not resolve.
