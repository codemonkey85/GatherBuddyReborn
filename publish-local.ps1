#requires -Version 7
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot

$buildDir = Join-Path $PSScriptRoot 'build'
$pluginDll = Join-Path $buildDir 'GatherBuddyReborn.dll'
$upstreamUrl = 'https://github.com/FFXIV-CombatReborn/GatherBuddyReborn.git'

if (Test-Path -LiteralPath $pluginDll) {
    try {
        $fs = [System.IO.File]::Open($pluginDll, 'Open', 'Read', 'None')
        $fs.Close()
    } catch {
        Write-Error "GatherBuddyReborn.dll appears to be in use (Dalamud has it loaded?). Disable the plugin in-game, then rerun."
        exit 1
    }
}

# Pick the remote that points at the canonical FFXIV-CombatReborn repo.
# If origin already points there, use origin. Otherwise self-heal an upstream remote.
$remotes = @(git remote)
$canonicalPattern = 'FFXIV-CombatReborn/GatherBuddyReborn(\.git)?$'
$originUrl = if ($remotes -contains 'origin') { (git remote get-url origin) } else { '' }

if ($originUrl -match $canonicalPattern) {
    $syncRemote = 'origin'
} else {
    if (-not ($remotes -contains 'upstream')) {
        Write-Host "==> adding upstream remote ($upstreamUrl)" -ForegroundColor Cyan
        git remote add upstream $upstreamUrl
    }
    $syncRemote = 'upstream'
}

$branch = (git rev-parse --abbrev-ref HEAD).Trim()

Write-Host "==> git fetch $syncRemote" -ForegroundColor Cyan
git fetch $syncRemote

Write-Host "==> git merge --ff-only $syncRemote/$branch" -ForegroundColor Cyan
git merge --ff-only "$syncRemote/$branch"

Write-Host '==> git submodule update --init --recursive' -ForegroundColor Cyan
git submodule update --init --recursive

Write-Host '==> dotnet restore' -ForegroundColor Cyan
dotnet restore .\GatherBuddy.sln

Write-Host '==> dotnet build (publish to .\build)' -ForegroundColor Cyan
if (Test-Path -LiteralPath $buildDir) { Remove-Item -Recurse -Force -LiteralPath $buildDir }
dotnet build --no-restore -c Release .\GatherBuddy\GatherBuddy.csproj --output $buildDir

Write-Host ''
Write-Host "Published to: $pluginDll" -ForegroundColor Green
