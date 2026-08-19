[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$env:KUBE_EDITOR = 'code -w'

$wingetRepair = Join-Path $PSScriptRoot 'Repair-WingetPath.ps1'
if (Test-Path -LiteralPath $wingetRepair) {
  . $wingetRepair
  Repair-WingetPath
}

Set-Alias -Name g -Value git
function glog { git log --oneline --graph --decorate --all }
function gforce { git push --force-with-lease @args }

Set-Alias -Name d -Value docker
Set-Alias -Name k -Value kubectl
Set-Alias -Name tf -Value terraform

if (Get-Command kubectl -ErrorAction SilentlyContinue) {
  kubectl completion powershell | Out-String | Invoke-Expression
}

if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
  oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/kali.omp.json" | Invoke-Expression
}
