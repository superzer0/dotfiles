[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Invoke-Chezmoi {
  param(
    [Parameter(Mandatory)]
    [string[]]$Arguments
  )

  & chezmoi @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "chezmoi failed with exit code $LASTEXITCODE`: chezmoi $($Arguments -join ' ')"
  }
}

function Assert-PowerShellSyntax {
  param(
    [Parameter(Mandatory)]
    [string]$Content,

    [Parameter(Mandatory)]
    [string]$SourceName
  )

  $tokens = $null
  $errors = $null
  [void][System.Management.Automation.Language.Parser]::ParseInput(
    $Content,
    $SourceName,
    [ref]$tokens,
    [ref]$errors
  )

  if ($errors.Count -gt 0) {
    $messages = $errors | ForEach-Object { $_.Message }
    throw "PowerShell syntax errors in '$SourceName': $($messages -join '; ')"
  }
}

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$validationRoot = Join-Path ([System.IO.Path]::GetTempPath()) "dotfiles-$([guid]::NewGuid())"
$destination = Join-Path $validationRoot 'home'
$config = Join-Path $validationRoot 'chezmoi.toml'

New-Item -ItemType Directory -Path $destination -Force | Out-Null
Set-Content -LiteralPath $config -Value '# CI validation config' -Encoding utf8NoBOM

$commonArguments = @(
  '--source', $repositoryRoot,
  '--destination', $destination,
  '--config', $config,
  '--no-tty'
)

try {
  Invoke-Chezmoi -Arguments ($commonArguments + @('data'))
  Invoke-Chezmoi -Arguments ($commonArguments + @('managed'))
  Invoke-Chezmoi -Arguments ($commonArguments + @('apply', '--dry-run', '--exclude=scripts'))
  Invoke-Chezmoi -Arguments ($commonArguments + @('apply', '--exclude=scripts'))
  Invoke-Chezmoi -Arguments ($commonArguments + @('verify', '--exclude=scripts'))

  $globalAgents = Join-Path $destination '.codex/AGENTS.md'
  if (-not (Test-Path -LiteralPath $globalAgents)) {
    throw "Expected rendered global agent instructions at '$globalAgents'."
  }

  Get-ChildItem -LiteralPath (Join-Path $repositoryRoot '.chezmoiscripts') -File -Filter '*.tmpl' | ForEach-Object {
    $rendered = & chezmoi @commonArguments execute-template --file $_.FullName
    if ($LASTEXITCODE -ne 0) {
      throw "Failed to render script template '$($_.FullName)'."
    }

    $content = $rendered -join [Environment]::NewLine
    if (-not [string]::IsNullOrWhiteSpace($content)) {
      if ($_.Name -match '\.ps1\.tmpl$') {
        Assert-PowerShellSyntax -Content $content -SourceName $_.FullName
      }
      elseif ($_.Name -match '\.sh\.tmpl$') {
        $temporaryScript = Join-Path $validationRoot $_.BaseName
        Set-Content -LiteralPath $temporaryScript -Value $content -Encoding utf8NoBOM
        & bash -n $temporaryScript
        if ($LASTEXITCODE -ne 0) {
          throw "Shell syntax validation failed for '$($_.FullName)'."
        }
      }
    }
  }

  if ($IsWindows) {
    $profile = Join-Path $destination 'Documents/PowerShell/Microsoft.PowerShell_profile.ps1'
    if (-not (Test-Path -LiteralPath $profile)) {
      throw "Expected Windows PowerShell profile at '$profile'."
    }
    Assert-PowerShellSyntax -Content (Get-Content -LiteralPath $profile -Raw) -SourceName $profile
  }
  elseif ($IsMacOS) {
    foreach ($path in @('.profile', '.zshrc', '.p10k.zsh')) {
      if (-not (Test-Path -LiteralPath (Join-Path $destination $path))) {
        throw "Expected macOS target '$path' was not rendered."
      }
    }
    & zsh -n (Join-Path $destination '.zshrc')
    if ($LASTEXITCODE -ne 0) {
      throw 'Rendered .zshrc failed zsh syntax validation.'
    }
  }
  else {
    if (-not (Test-Path -LiteralPath (Join-Path $destination '.profile'))) {
      throw 'Expected Linux .profile was not rendered.'
    }
    & bash -n (Join-Path $destination '.profile')
    if ($LASTEXITCODE -ne 0) {
      throw 'Rendered .profile failed bash syntax validation.'
    }
  }
}
finally {
  Remove-Item -LiteralPath $validationRoot -Recurse -Force -ErrorAction SilentlyContinue
}
