[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# COPY TO $PROFILE location
$ENV:KUBE_EDITOR='code -w'

# -- Git --
Set-Alias -Name g -Value "git"
Set-Alias -Name gforce -Value "git push --force-with-lease"

function glog {git log --oneline --graph --decorate --all}

Set-Alias -Name d -Value "docker"
Set-Alias -Name k -Value "kubectl"
Set-Alias -Name tf -Value "terraform"

kubectl completion powershell | Out-String | Invoke-Expression

# Install https://ohmyposh.dev/docs/installation/windows
oh-my-posh init pwsh | Invoke-Expression
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/kali.omp.json" | Invoke-Expression
