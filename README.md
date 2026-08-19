# Dotfiles

Cross-platform personal configuration managed with [chezmoi](https://chezmoi.io/).

## Bootstrap

Install chezmoi and initialize this repository without applying changes:

```sh
sh -c "$(curl -fsLS https://get.chezmoi.io)" -- init superzer0
```

On Windows PowerShell:

```powershell
iex "&{$(irm 'https://get.chezmoi.io/ps1')} -- init superzer0"
```

Always inspect the proposed changes before the first apply:

```sh
chezmoi doctor
chezmoi diff
chezmoi apply --dry-run --verbose
chezmoi apply --verbose
```

## Managed configuration

- global Codex instructions in `~/.codex/AGENTS.md`;
- PowerShell profile and Windows Terminal settings on Windows;
- Zsh, Powerlevel10k, and common shell aliases on macOS;
- common Bash profile on Linux;
- Homebrew and Winget package inventories;
- global agent-skill inventory.

Machine-independent defaults and inventories live in `.chezmoidata.yaml`. Override values such as `machineRole` or `installAgentTools` from the local chezmoi configuration when required.

## Daily workflow

```sh
chezmoi edit ~/.profile
chezmoi diff
chezmoi apply
```

To update from GitHub and apply:

```sh
chezmoi update
```

## Validation

Pull requests run the same rendered-state validation on Ubuntu, macOS, and Windows:

```powershell
./tests/validate-chezmoi.ps1
```

The validator renders the source state, performs a dry-run and isolated apply, verifies the resulting files, and checks PowerShell, Bash, and Zsh syntax. Package and skill installers are rendered and syntax-checked but are not executed in CI.

## Manual prerequisites

- Homebrew must already exist before macOS package convergence.
- Winget must already exist before Windows package convergence.
- Oh My Zsh, Powerlevel10k, Krew, and Meslo Nerd Font installation remain explicit workstation setup choices.
- Review Windows Known Folder redirection before applying if the PowerShell Documents directory is redirected to OneDrive or a corporate location.
