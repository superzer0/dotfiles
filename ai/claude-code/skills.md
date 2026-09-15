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
| `kql` | https://github.com/microsoft/skills |
| `microsoft-foundry` | https://github.com/microsoft/azure-skills |

Installed state lives in `~/.agents/.skill-lock.json` (source URL, skill path
inside the repo, folder hash, install/update timestamps). That file is worth
backing up — it is the only record of which upstream path each skill came from.

## Installing

`../agent-skills-install.ps1`, or `../agent-skills-install.sh` on a machine
without PowerShell. Both are idempotent and cover the full list above.

Three things the installers handle that are easy to miss doing this by hand:

- **`--full-depth` is not optional here.** A repository with a `SKILL.md` at its
  root stops the scan there, and subdirectories are never searched.
  `github/gh-aw` is exactly that case: without the flag it resolves to one skill
  ("GitHub Agentic Workflows") and `--skill github-pr-query` fails with
  `No matching skills found`, even though `.github/skills/github-pr-query`
  exists upstream. The flag is a no-op for the other repositories here.
- **`npx` reads stdin.** Driving the loop from a pipe or a heredoc on stdin lets
  the first `npx skills add` swallow the rest of the list; the loop then ends
  after one skill and still exits 0.
- **"Already installed" must mean linked, not just present.** A skill can sit in
  `~/.agents/skills/` with no symlink in `~/.claude/skills/`, in which case
  Claude Code cannot see it. Testing only the store skips it and leaves it
  invisible with nothing to explain why.

## Plugins

Plugin marketplaces and the enabled plugin list are in `settings.json`
(`extraKnownMarketplaces` + `enabledPlugins`). Everything listed there is
public. Add a private marketplace with:

```
/plugin marketplace add <owner>/<repo>
```

GitHub Enterprise hosts need the full git URL — the `owner/repo` shorthand does
not resolve.
