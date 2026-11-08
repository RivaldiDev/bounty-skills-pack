<#
.SYNOPSIS
  Installs the skills in this pack into the local harness skill folders.

.DESCRIPTION
  Copies every folder under .\skills into ~/.agents/skills and, if it exists,
  ~/.claude/skills. Existing folders are overwritten only with -Force.

.PARAMETER Force
  Overwrite skills that already exist.

.EXAMPLE
  .\install-skills.ps1 -Force
#>
[CmdletBinding()]
param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$packRoot = Split-Path -Parent $PSScriptRoot
$srcRoot  = Join-Path $packRoot 'skills'

if (-not (Test-Path $srcRoot)) {
    throw "skills folder not found at $srcRoot"
}

$targets = @(
    (Join-Path $env:USERPROFILE '.agents\skills'),
    (Join-Path $env:USERPROFILE '.claude\skills')
)

$installed = 0
foreach ($target in $targets) {
    New-Item -ItemType Directory -Force -Path $target | Out-Null
    foreach ($skill in Get-ChildItem $srcRoot -Directory) {
        $dest = Join-Path $target $skill.Name
        if ((Test-Path $dest) -and -not $Force) {
            Write-Host "skip  $($skill.Name) (exists, use -Force)" -ForegroundColor DarkYellow
            continue
        }
        Copy-Item -Recurse -Force $skill.FullName $target
        Write-Host "ok    $($skill.Name) -> $target" -ForegroundColor Green
        $installed++
    }
}

Write-Host ""
Write-Host "installed $installed skill folder(s)" -ForegroundColor Cyan
