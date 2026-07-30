[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# COPY TO $PROFILE location
$ENV:KUBE_EDITOR = 'code -w'

# -- WinGet PATH self-heal --
# winget's symlink-based PATH mechanism needs SeCreateSymbolicLinkPrivilege (Developer
# Mode / admin), which this account doesn't have, so it silently falls back to adding
# per-package folders to PATH -- and gets it wrong for packages with a nested exe (e.g.
# Helm's windows-amd64\helm.exe). This scans and fixes it on every new shell.
. "$PSScriptRoot\Repair-WingetPath.ps1"
Repair-WingetPath

# -- Git --
Set-Alias -Name g -Value "git"
Set-Alias -Name gforce -Value "git push --force-with-lease"

function glog { git log --oneline --graph --decorate --all }

Set-Alias -Name d -Value "docker"
Set-Alias -Name k -Value "kubectl"
Set-Alias -Name tf -Value "terraform"

if (Get-Command "kubectl" -ErrorAction SilentlyContinue) {
  kubectl completion powershell | Out-String | Invoke-Expression
}

if (Get-Command "oh-my-posh" -ErrorAction SilentlyContinue) {
  # Install https://ohmyposh.dev/docs/installation/windows
  oh-my-posh init pwsh | Invoke-Expression
  oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/kali.omp.json" | Invoke-Expression
}

