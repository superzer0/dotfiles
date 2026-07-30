function Repair-WingetPath {
    <#
    Scans all winget-installed packages under %LOCALAPPDATA%\Microsoft\WinGet\Packages,
    finds the executable(s) inside each package, and makes sure the folder that actually
    contains the exe is on the User PATH. Fixes the case where winget's symlink-based
    "Links" mechanism silently falls back to adding a package's root folder to PATH even
    when the exe lives in a nested subfolder (e.g. Helm's windows-amd64\helm.exe), and the
    case where nothing gets added to PATH at all because SeCreateSymbolicLinkPrivilege
    is unavailable (no Developer Mode / non-admin account).

    Never removes anything from PATH -- only appends missing directories. Safe to re-run.

    To avoid re-scanning every exe on every shell start, the expensive part is skipped
    when the package folder set (names + mtimes, one level deep) matches a cached
    signature from the last run. Use -Force to bypass the cache.
    #>
    [CmdletBinding()]
    param(
        [switch]$WhatIfOnly,
        [switch]$Force
    )

    $packagesRoot = Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Packages"
    if (-not (Test-Path $packagesRoot)) {
        Write-Verbose "No winget Packages directory found at $packagesRoot"
        return
    }

    $packageDirs = Get-ChildItem $packagesRoot -Directory -ErrorAction SilentlyContinue
    $signature = ($packageDirs | Sort-Object Name | ForEach-Object { "$($_.Name)|$($_.LastWriteTimeUtc.Ticks)" }) -join ';'
    $cacheFile = Join-Path $packagesRoot ".repair-wingetpath-cache.txt"

    if (-not $Force -and (Test-Path $cacheFile)) {
        $cached = Get-Content $cacheFile -Raw -ErrorAction SilentlyContinue
        if ($cached -eq $signature) {
            Write-Verbose "Repair-WingetPath: package set unchanged since last run, skipping scan."
            return
        }
    }

    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $userPathEntries = @($userPath -split ';' | Where-Object { $_ -ne '' })
    $userPathSet = [System.Collections.Generic.HashSet[string]]::new(
        [string[]]($userPathEntries | ForEach-Object { $_.TrimEnd('\') }),
        [System.StringComparer]::OrdinalIgnoreCase
    )

    $dirsToAdd = New-Object System.Collections.Generic.List[string]

    $packageDirs | ForEach-Object {
        $pkgDir = $_.FullName

        $allExes = Get-ChildItem $pkgDir -Recurse -Filter *.exe -File -ErrorAction SilentlyContinue
        if (-not $allExes) { return }

        # Only consider the shallowest exe(s) in the package tree -- this is the "main"
        # binary (e.g. helm.exe under windows-amd64\, pnpm.exe at the root). Deeper exes
        # are almost always internal/vendored helper tools (e.g. pnpm's dist\vendor\fastlist*.exe)
        # that were never meant to be exposed on PATH.
        $minDepth = ($allExes | ForEach-Object {
            $rel = $_.FullName.Substring($pkgDir.Length).TrimStart('\')
            ($rel -split '\\').Count - 1
        } | Measure-Object -Minimum).Minimum

        $exes = $allExes | Where-Object {
            $rel = $_.FullName.Substring($pkgDir.Length).TrimStart('\')
            (($rel -split '\\').Count - 1) -eq $minDepth
        }

        foreach ($exe in $exes) {
            $already = Get-Command $exe.Name -ErrorAction SilentlyContinue
            if ($already) { continue }

            $exeDir = $exe.DirectoryName.TrimEnd('\')
            if (-not $userPathSet.Contains($exeDir)) {
                $dirsToAdd.Add($exeDir) | Out-Null
                $userPathSet.Add($exeDir) | Out-Null
            }
        }
    }

    $dirsToAdd = $dirsToAdd | Select-Object -Unique

    if ($dirsToAdd.Count -eq 0) {
        Write-Verbose "Repair-WingetPath: nothing to fix, all winget package exes already resolve."
        Set-Content -Path $cacheFile -Value $signature -NoNewline
        return
    }

    Write-Host "Repair-WingetPath: adding $($dirsToAdd.Count) missing director$(if($dirsToAdd.Count -eq 1){'y'}else{'ies'}) to User PATH:" -ForegroundColor Yellow
    $dirsToAdd | ForEach-Object { Write-Host "  + $_" -ForegroundColor Yellow }

    if ($WhatIfOnly) {
        Write-Host "(WhatIfOnly set -- PATH not modified)" -ForegroundColor DarkGray
        # Cache intentionally not written here: PATH wasn't actually fixed, so a
        # real (non-WhatIf) run must still be allowed to apply it next time.
        return
    }

    $newPath = ($userPathEntries + $dirsToAdd) -join ';'
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")

    # Update current session so it works without reopening the shell
    $env:Path = $newPath + ';' + [Environment]::GetEnvironmentVariable("Path", "Machine")

    Set-Content -Path $cacheFile -Value $signature -NoNewline
    Write-Host "Done. Current session PATH updated; new shells will pick this up automatically." -ForegroundColor Green
}
