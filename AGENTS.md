# Dotfiles Repository Instructions

## Source of truth

- This repository is a chezmoi source state. Modify source-state files and templates, not rendered files in `$HOME`.
- Preserve Windows, macOS, and Linux behavior unless the task explicitly changes platform scope.
- Never commit credentials, tokens, private keys, machine-local identifiers, or rendered secret values.

## Repository conventions

- Put shared template fragments in `.chezmoitemplates/`.
- Put machine-independent inventories and defaults in `.chezmoidata.yaml`.
- Put convergence actions in `.chezmoiscripts/`; scripts must be idempotent.
- Use `run_onchange_` for package and agent-skill inventories so changes rerun convergence.
- Use `.chezmoiignore` for platform-specific target paths and repository-only files.
- Keep global personal agent preferences in `.chezmoitemplates/agents/global.md`. Keep this file specific to maintaining the dotfiles repository.

## Change constraints

- Do not weaken or bypass validation to make a check pass.
- Do not execute package installation scripts in CI.
- Do not introduce an unpinned external binary or archive into target state without documenting the supply-chain decision.
- Avoid machine-specific paths in shared templates. If a target path differs by platform, provide platform-specific targets backed by a shared template.

## Verification

Run the repository validation after modifying chezmoi data, templates, scripts, or managed files:

```powershell
./tests/validate-chezmoi.ps1
```

Before applying changes on a workstation, review them first:

```powershell
chezmoi doctor
chezmoi diff
chezmoi apply --dry-run --verbose
```

The GitHub Actions `chezmoi` matrix on Ubuntu, macOS, and Windows is the pull-request validation and must pass before merge.
